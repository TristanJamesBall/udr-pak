// vim: set ts=4 sw=4 et:
#include <dmi/mi.h>
#include <dmi/mitrace.h>
#include <dmi/sqlca.h>
#include <dmi/sqlhdr.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <time.h>

/*
 * GOTCHYA: You cant use a [.] in the trace flag names ( eg, can't use udr.entry, have to use
 * udr_entry )
 *
 * Levels are only relative to the class, that is,  enabling 'udr_dbg 30'
 * does *not* enable levels < 30 for the other classes
 *
 */

#define trace_mem(lvl, fmt, ...)     \
    if (MI_TFLAG("udrpak_mem", lvl)) \
    mi_def_tprintf("%s:%d::%s() " fmt, __FILE__, __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__)

#define trace(lvl, fmt, ...)     \
    if (MI_TFLAG("udrpak", lvl)) \
    mi_def_tprintf("%s:%d::%s() " fmt, __FILE__, __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__)

#define debug(fmt, ...)              \
    if (MI_TFLAG("__myErrors__", 0)) \
    mi_def_tprintf("%s:%d::%s() " fmt, __FILE__, __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__)

mi_lvarchar* udr_trace_configure(mi_integer trace_level, mi_lvarchar* trace_class,
                                 mi_lvarchar* trace_path, MI_FPARAM* fParam);
void udr_trace_set(mi_integer lvl, MI_FPARAM* fParam);
void udr_trace_on(void);
void udr_trace_off(void);
mi_bigint udr_trace_test(MI_FPARAM* fParam);

void _mi_tracelevel_set(const mi_string* trace_cmds);
