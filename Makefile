
default : all
DBNAME = tjb
RUNAS = sudo -u informix
SDKDIR = /opt/ifx.sdk.15.0.0.2/

# Compiler and flags
CC = gcc
CFLAGS = -Wall -O3 -std=gnu23 -fPIC -shared -I${SDKDIR}/incl -DMI_SERVBUILD -D_GNU_SOURCE 
LDFLAGS = -shared -u _etext

MKDIR = mkdir -p
RM = rm -f
RMDIR = rmdir
# Project name and target executable
TARGET = udr-pak

# Source and object directories
SRCDIRS = tracing runtime seq prng uuid realtime
OBJDIR = build/obj
LIBDIR = build/lib

# Find all C source files in subdirectories
SOURCES = $(foreach dir,$(SRCDIRS),$(wildcard $(dir)/*.c))

# Create object file names based on source files
OBJECTS = $(patsubst %.c,$(OBJDIR)/%.o,$(notdir $(SOURCES)))

.PHONY: all clean


all: $(LIBDIR) $(OBJDIR) $(TARGET)

$(LIBDIR):
	mkdir -p $(LIBDIR)

$(OBJDIR):
	mkdir -p $(OBJDIR)

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $(LIBDIR)/$(TARGET).so

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: tracing/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: runtime/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: realtime/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: seq/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: prng/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: uuid/%.c
	$(CC) $(CFLAGS) -c $< -o $@


clean:
	${RM} $(OBJECTS) $(LIBDIR)/$(TARGET).so 


install: all
	${RUNAS} ${MKDIR} ${INFORMIXDIR}/extend/${TARGET}
	${RUNAS} chmod 775 ${INFORMIXDIR}/extend/${TARGET}
	${RUNAS} cp -f ./build/lib/${TARGET}.so      ${INFORMIXDIR}/extend/${TARGET}
	${RUNAS} cp -f ./sql/${TARGET}*REG.sql  ${INFORMIXDIR}/extend/${TARGET}
	${RUNAS} dbaccess -a ${DBNAME} ./sql/${TARGET}_REG.sql 2>&1 | awk 'NF>0'
	${RUNAS} ./extra/show_install.sh

uninstall: 
	${RUNAS} dbaccess ${DBNAME} ./sql/${TARGET}_UNREG.sql 2>&1 | awk 'NF>0'
	${RUNAS} ${RM} ${INFORMIXDIR}/extend/${TARGET}/*
	${RUNAS} rmdir ${INFORMIXDIR}/extend/${TARGET}
