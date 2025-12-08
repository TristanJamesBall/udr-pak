
default : all
DBNAME = tjb
RUNAS = sudo -u informix
INFORMIXSDK := $(shell realpath informix-sdk)
INFORMIXDIR := $(shell realpath informix-server)

# Compiler and flags
CC = gcc
CFLAGS = -Wall -O3 -std=gnu23 -fPIC -shared -I${INFORMIXSDK}/incl -D_GNU_SOURCE 
CFLAGS_UDR = -DMI_SERVBUILD
CFLAGS_CLIENT = -UMI_SERVBUILD -DMITRACE_OFF
LDFLAGS = -shared -u _etext 


TEST_CFLAGS = -Wall -Og -std=gnu23 -fPIC -shared -I${INFORMIXSDK}/incl -DMI_SERVBUILD -D_GNU_SOURCE 

TEST_LDFLAGS = -L$(INFORMIXSDK)/lib/esql -L$(INFORMIXSDK)/lib/dmi -L$(INFORMIXSDK)/lib -lthdmi -lthsql -lthasf -lthcss -lthos -lthgen -lthgls -lm -lcrypt /opt/ifx.sdk.15.0.0.2/lib/esql/checkapi.o 

LD ?= $(CC)

MKDIR = mkdir -p
RM = rm -f
RMDIR = rmdir
# Project name and target executable
TARGET = udr-pak

# Source and object directories
SRCDIRS = tracing runtime seq prng uuid realtime
OBJDIR = build/obj
CLIENT_OBJDIR = build/client_obj
LIBDIR = build/lib

# Find all C source files in subdirectories
SOURCES = $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.c))

# Create object file names based on source files
OBJECTS = $(patsubst %.c,$(OBJDIR)/%.o,$(notdir $(SOURCES)))

# Create object file names based on source files
CLIENT_OBJECTS = $(patsubst %.c,$(CLIENT_OBJDIR)/%.o,$(notdir $(SOURCES)))

.PHONY: all clean


all: $(LIBDIR) $(OBJDIR) $(CLIENT_OBJDIR) $(TARGET)

$(LIBDIR):
	mkdir -p $(LIBDIR)

$(OBJDIR):
	mkdir -p $(OBJDIR)

$(CLIENT_OBJDIR):
	mkdir -p $(CLIENT_OBJDIR)



$(TARGET): $(OBJECTS) $(CLIENT_OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $(LIBDIR)/$(TARGET).so $(LDLIBS)
	$(LD) $(LDFLAGS) $(CLIENT_OBJECTS) -o $(LIBDIR)/$(TARGET)_client.so $(LDLIBS)

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	$(CC) $(CFLAGS) $(CFLAGS_UDR) -c $< -o $@

$(OBJDIR)/%.o: tracing/%.c
	$(CC) $(CFLAGS) $(CFLAGS_UDR) -c $< -o $@

$(OBJDIR)/%.o: runtime/%.c
	$(CC) $(CFLAGS) $(CFLAGS_UDR) -c $< -o $@

$(OBJDIR)/%.o: realtime/%.c
	$(CC) $(CFLAGS) $(CFLAGS_UDR) -c $< -o $@

$(OBJDIR)/%.o: seq/%.c
	$(CC) $(CFLAGS) $(CFLAGS_UDR) -c $< -o $@

$(OBJDIR)/%.o: prng/%.c
	$(CC) $(CFLAGS) $(CFLAGS_UDR) -c $< -o $@

$(OBJDIR)/%.o: uuid/%.c
	$(CC) $(CFLAGS) $(CFLAGS_UDR) -c $< -o $@



$(CLIENT_OBJDIR)/%.o: $(SRCDIR)/%.c
	$(CC) $(CFLAGS) $(CFLAGS_CLIENT) -c $< -o $@

$(CLIENT_OBJDIR)/%.o: tracing/%.c
	$(CC) $(CFLAGS) $(CFLAGS_CLIENT) -c $< -o $@

$(CLIENT_OBJDIR)/%.o: runtime/%.c
	$(CC) $(CFLAGS) $(CFLAGS_CLIENT) -c $< -o $@

$(CLIENT_OBJDIR)/%.o: realtime/%.c
	$(CC) $(CFLAGS) $(CFLAGS_CLIENT) -c $< -o $@

$(CLIENT_OBJDIR)/%.o: seq/%.c
	$(CC) $(CFLAGS) $(CFLAGS_CLIENT) -c $< -o $@

$(CLIENT_OBJDIR)/%.o: prng/%.c
	$(CC) $(CFLAGS) $(CFLAGS_CLIENT) -c $< -o $@

$(CLIENT_OBJDIR)/%.o: uuid/%.c
	$(CC) $(CFLAGS) $(CFLAGS_CLIENT) -c $< -o $@




clean:
	${RM} $(OBJECTS) $(LIBDIR)/$(TARGET).so 


TEST_BIN_DIR = build/bin

.PHONY: test
test: $(TEST_BIN_DIR) $(TEST_BIN_DIR)/test_realtime
	@echo "Running realtime tests..."
	$(TEST_BIN_DIR)/test_realtime

$(TEST_BIN_DIR):
	${MKDIR} $(TEST_BIN_DIR)

$(TEST_BIN_DIR)/test_realtime: tests/test_realtime.c realtime/realtime.c
	$(CC) -Wall -O2 -std=gnu23 $(TEST_CFLAGS) $(TEST_LDFLAGS) -I. $^ -o $@ -lrt

.PHONY: integration-test
integration-test:
	@echo "Running integration tests (build, install, SQL checks)"
	@./tests/integration/run_informix_tests.sh


## It's really important that we don't overwrite the shared library informix is currently using.
## Even if we overwrite it "perfectly" (identical file, same inode, matching sha256 ) - informix will crash
## Moving the file and recreating new one is OK tho
install: all
	${RUNAS} ${MKDIR} ${INFORMIXDIR}/extend/${TARGET}
	${RUNAS} chmod 775 ${INFORMIXDIR}/extend/${TARGET}
	$(RUNAS) /bin/sh -c 'F=${INFORMIXDIR}/extend/${TARGET}/${TARGET}.so; if [ -e "$$F" ]; then mv "$$F" "$$F".bak.$$(date +%s); fi '
	${RUNAS} cp -f ./build/lib/${TARGET}.so      ${INFORMIXDIR}/extend/${TARGET}
	${RUNAS} cp -f ./sql/${TARGET}*REG.sql  ${INFORMIXDIR}/extend/${TARGET}
	${RUNAS} dbaccess -a ${DBNAME} ./sql/${TARGET}_REG.sql 2>&1 | awk 'NF>0'
	${RUNAS} ./extra/show_install.sh

uninstall: 
	${RUNAS} dbaccess -e ${DBNAME} ./sql/${TARGET}_UNREG.sql 2>&1 | awk 'NF>0'
	${RUNAS} ${RM} ${INFORMIXDIR}/extend/${TARGET}/*
	${RUNAS} rmdir ${INFORMIXDIR}/extend/${TARGET}
