// vim: set ts=4 sw=4 et:

#include "tracing.h"

#include <dmi/mitrace.h>

#include "../runtime/runtime.h"

/* based on systraceclassses column width*/
#define TRACE_STR_LEN 20

#define BIT_MASK_LO_6 63

void _mi_tracelevel_set(const mi_string* trace_cmds) {
#ifdef MI_SERVERBUILD
    mi_tracelevel_set(trace_cmds);
#else
    fprintf(stderr, "Can't strace in client code, would have set: %s\n", trace_cmds);
#endif
}

mi_lvarchar* udr_trace_configure(mi_integer trace_level, mi_lvarchar* trace_class,
                                 mi_lvarchar* trace_path, MI_FPARAM* fParam) {
    char trace_cmd[TRACE_STR_LEN];
    mi_lvarchar* ret;
    set_safe_duration();

#ifdef MI_SERVERBUILD
    mi_tracefile_set(
        nvl2Arg(fParam, 2, mi_lvarchar_to_string(trace_path), "/var/tmp/udrpak.trace.log"));
#else
    fprintf(stderr, "Can't strace in client code, would have set: %s\n",
            nvl2Arg(fParam, 2, mi_lvarchar_to_string(trace_path), "/var/tmp/udrpak.trace.log"));
#endif

    snprintf(trace_cmd, TRACE_STR_LEN, "%.11s %3d",
             nvl2Arg(fParam, 1, mi_lvarchar_to_string(trace_class), "udrpak"),
             (int8_t)nvl2Arg(fParam, 0, trace_level, 1));
    _mi_tracelevel_set(trace_cmd);

    ret = mi_new_var(strlen(trace_cmd));
    return (ret);
}

void udr_trace_set(int lvl, MI_FPARAM* fParam) {
    char trace_cmd[TRACE_STR_LEN + 2];
    set_safe_duration();

    lvl = nvl2Arg(fParam, 0, lvl, 1);

    snprintf(trace_cmd, TRACE_STR_LEN, "udrpak_mem %3d", (int8_t)lvl);
    _mi_tracelevel_set(trace_cmd);

    /*reset our buffer*/
    udr_memset(trace_cmd, TRACE_STR_LEN + 2, '\0');
    snprintf(trace_cmd, TRACE_STR_LEN, "udrpak %3d", (int8_t)lvl);
    _mi_tracelevel_set(trace_cmd);

    udr_memset(trace_cmd, TRACE_STR_LEN + 2, '\0');
    snprintf(trace_cmd, TRACE_STR_LEN, "__myErrors__ %3d", (int8_t)lvl);
    _mi_tracelevel_set(trace_cmd);
}

void udr_trace_on(void) {
    set_safe_duration();

    _mi_tracelevel_set("udrpak_mem 1");
    _mi_tracelevel_set("udrpak 1");
    _mi_tracelevel_set("__myErrors__ 1");
}

void udr_trace_off(void) {
    set_safe_duration();

    _mi_tracelevel_set("udrpak_mem 0");
    _mi_tracelevel_set("udrpak 0");
    _mi_tracelevel_set("__myErrors__ 0");
}

mi_bigint udr_trace_test(MI_FPARAM* fParam) {
    set_safe_duration();

    udr_trace_set(2, fParam);
    trace(1, "Lvl 1 Should Not Be Visible");
    trace(10, "Lvl 10 Should Be Visible: DummyVal:%d", 25);

    udr_trace_set(20, fParam);
    trace(1, "Lvl 1 Should Be Visible");
    trace(10, "Lvl 10 Should Be Visible: DummyVal:%d", 25);

    udr_trace_off();
    trace(0, "Should not be visible\n");
    debug("Should be visible\n");
    udr_trace_off();

    return 1;
}
