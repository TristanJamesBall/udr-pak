# Makefile for udr-pak shared library
# Compiles all C code under ./src into build/lib/udr-pak.so
TARGET = udr-pak

# Default target
.PHONY: all clean install
default : all
all: build/lib/$(TARGET).so


export DBNAME := ci_test
RUNAS = sudo -u informix

#Tools
CC ?= gcc
LD ?= $(CC)


# ./informix-[sdk|server] are symlinks to the install dirs
# eg $( realpath informix-sdk ) resolves to /opt/ifx.sdk.15.0.0.2
# You don't have to do it this way, just normal -I flags is OK,
# it's and experiment in easilly giving AI more context
INFORMIXSDK := $(shell realpath informix-sdk)

DESTDIR := ${INFORMIXDIR}/extend/${TARGET}



# Source directories
SRCDIRS := src/util src/prng src/realtime src/uuid src/any
SOURCES := $(shell find $(SRCDIRS) -maxdepth 1 -name "*.c" -type f | sort)

# Object files output directory
OBJDIR := build/obj

# Library output
LIBDIR := build/lib
LIBOUT := $(LIBDIR)/udr-pak.so


# On my fedora/glibc system, _XOPEN_SOURCE=600 seems to be the minimum can go 
# and still get our CLOCK_* defines
#
# If you're on any remotely modern linux system, you can just set _GNU_SOURCE:
#
# CFLAGS := -std=c11  -D_XOPEN_SOURCE=600 -fPIC -Wall  -g -O3  -DMI_SERVBUILD 
#

REQ_CFLAGS := -std=c11 -fPIC -shared -D_GNU_SOURCE  -DMI_SERVBUILD 
DBG_CFLAGS := -Wall -g -Winline
REL_CFLAGS := -Wall 
OPT_CFLAGS :=
#-coverage -ftest-coverage
CFLAGS := $(REQ_CFLAGS) $(DBG_CFLAGS) $(OPT_CFLAGS)
#CFLAGS := $(REQ_CFLAGS) $(REL_CFLAGS) $(OPT_CFLAGS)
CPPFLAGS := -Isrc/util -Isrc/prng -Isrc/realtime -Isrc/uuid -Isrc/any
LDFLAGS += -shared 

SDKDIR ?= ./informix-sdk
ifdef SDKDIR
    CPPFLAGS += -I$(SDKDIR)/incl
    LDFLAGS += -L$(SDKDIR)/lib
endif



# Generate object file names from sources
OBJECTS := $(foreach src,$(SOURCES),$(OBJDIR)/$(notdir $(basename $(src))).o)

# Create directories if they don't exist
$(OBJDIR) $(LIBDIR):
	mkdir -p $@

# Compile C source files to object files
$(OBJDIR)/%.o: src/util/%.c | $(OBJDIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: src/any/%.c | $(OBJDIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: src/prng/%.c | $(OBJDIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: src/realtime/%.c | $(OBJDIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: src/uuid/%.c | $(OBJDIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# Link object files into shared library
$(LIBOUT): $(OBJECTS) | $(LIBDIR)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@

# Install target (requires Informix environment)
.PHONY: Install

NOW := $(shell date  "+%Y%m%d__%H%M%S" )
UDR_SO := $(DESTDIR)/$(TARGET).so
BACKUP_SO := $(UDR_SO).$(NOW)


install: $(LIBOUT)
	@if [ -z "$(INFORMIXDIR)" ]; then         \
		echo "Error: INFORMIXDIR not set"    ;\
		exit                                 ;\
	fi
	@${RUNAS} mkdir -p $(DESTDIR)
	@${RUNAS} chmod 775 $(DESTDIR)
# Copy in as a .new file first, if this fails, there's no point going further
	@${RUNAS} cp -f ./build/lib/${TARGET}.so $(UDR_SO).new

	@if [ -f $(UDR_SO) ]; then      \
		printf "\n NOTICE: Existing library backed up to: \n\t$(BACKUP_SO)\n\n"     ;\
	 	$(RUNAS) mv $(UDR_SO)    $(BACKUP_SO)                                     ;\
	fi
	@if [ -f $(UDR_SO) ]; then      \
		printf "Failed to backup pre-existing library, can't continue\n"         ;\
		exit 1                                                                   ;\
	fi
	@$(RUNAS) mv     $(UDR_SO).new      $(UDR_SO)
	@${RUNAS} cp -f ./src/sql/*.sql     $(DESTDIR)
	@printf "Registering procedures with Informix\n\n"
	${RUNAS} dbaccess -e -a ${DBNAME} ./src/sql/${TARGET}_REG.sql 

	@printf "\nInstall summary\n\n"
	@${RUNAS} ./scripts/show_install.sh
	@echo
	@tree -n -f --matchdirs -P "$(TARGET)" -P "*.sql" -P "*.so" --prune $(DESTDIR) || find $(DESTDIR) -name "*.so" -o -name ".sql" -ls || true





uninstall: 
	$(RUNAS) ./scripts/create_drop_routines.sh $(DBNAME) $(TARGET) | $(RUNAS) dbaccess -e ${DBNAME} 2>&1 
	${RUNAS} dbaccess -e ${DBNAME} ./src/sql/${TARGET}_UNREG.sql 2>&1 
	${RUNAS} ${RM} 	$(DESTDIR)/*.{so,sql}
	@echo "The following command may fail"
	${RUNAS} rmdir 	${DESTDIR} || true

# Clean build artifacts
clean:
	rm -rf $(OBJDIR) $(LIBDIR) dbaccess.install.log
	@echo "Cleaned build artifacts"


.PHONY: format 
format:
	@command -v clang-format >/dev/null 2>&1 || { echo "clang-format not found; install clang-format to run this target"; exit 1; }
	@echo "Formatting C sources with clang-format..."
	@find . -name '*.c' -o -name '*.h' | xargs clang-format -i || true


# Show build variables
.PHONY: info
info:
	@echo
	@printf "%-20s: %s\n"  "DESTDIR" "$(DESTDIR)"
	@printf "%-20s: %s\n"  "INFORMIXSERVER" "${INFORMIXSERVER}"
	@printf "%-20s: %s\n"  "INFORMIXDIR" "${INFORMIXDIR}"
	@printf "%-20s: %s\n"  "DBNAME" "${DBNAME}"
	@printf "%-20s: %s\n"  "Sources" "$(SOURCES)"
	@printf "%-20s: %s\n"  "Objects" "$(OBJECTS)"
	@printf "%-20s: %s\n"  "Library" "$(LIBOUT)"
	@printf "%-20s: %s\n"  "CFLAGS" "$(CFLAGS)"
	@printf "%-20s: %s\n"  "CPPFLAGS" "$(CPPFLAGS)"
	@printf "%-20s: %s\n"  "LDFLAGS" "$(LDFLAGS)"
	@echo

