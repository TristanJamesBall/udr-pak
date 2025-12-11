// vim: set ts=4 sw=4 et:
#include "runtime.h"

#include <string.h>

#include "../realtime/realtime.h"
#include "../tracing/tracing.h"

void get_session_id(uint64_t* sid, MI_FPARAM* fParam) {
    MI_CONNECTION* conn;
    /*
        It's is ridiculously eass to leak memory if you try and preserver the connection,
        eg, as part of a long running transaction - even if you only connect once, _something_
        leaks memory every row...

        On the other hand - this is fast anyawy, we're not really making a connection
        just hooking up to the server environment we're already in, so don't sweat it
    */
    conn = mi_open(NULL, NULL, NULL);
    if (isNull(conn)) {
        *sid = 0;
        abort_enomem();
    }
    *sid = (uint64_t)mi_get_id(conn, MI_SESSION_ID);
    mi_close(conn);
}

__always_inline void* get_func_state_ptr(size_t sz, MI_FPARAM* fParam) {
    void* ustate = NULL;

    ustate = mi_fp_funcstate(fParam);

    if (isNull(ustate)) {
        if (!(ustate = udr_alloc_bytes(sz))) {
            return_enomem(NULL);
        } else {
            memset(ustate, 0, sz);
        }
        mi_fp_setfuncstate(fParam, ustate);
    }

    return (ustate);
}
