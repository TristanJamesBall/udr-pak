// vim: set ts=4 sw=4 et:
#include "../tracing/tracing.h"
#include "runtime.h"
#include <string.h>


__always_inline void *
get_func_state_ptr(size_t sz, MI_FPARAM *fParam) {

        void *ustate = NULL;

        ustate = mi_fp_funcstate( fParam );

        if isNull(ustate)  {

                ustate = udr_alloc_bytes(sz);

                if isNull(ustate)  {

                    return_enomem(NULL);
                }
                memset(ustate,0,sz);
                mi_fp_setfuncstate( fParam, ustate );
        }

        return( ustate );
}


struct fn_state {
    int count;
}; 

mi_integer
udr_fn(mi_lvarchar *trc, MI_FPARAM *fParam) {
    struct fn_state  *ustate = NULL;
    //char *trc_s = mi_lvarchar_to_string(trc);
    //t race(5,"%s",trc_s);

    ustate = (struct fn_state *)get_func_state_ptr(sizeof(struct fn_state),fParam);
    ustate->count++;
    //t race(1,"State at %lx count is: %d",ustate,ustate->count);

    return(ustate->count);
}


