// vim: set ts=4 sw=4 et:
//
#include "../tracing/tracing.h"
#include "../runtime/runtime.h"

typedef enum {
    ASC,
    DESC
} seq_order;

typedef struct {
    mi_integer start;
    mi_integer now;
    mi_integer step;
    mi_integer end;
    seq_order  order;
} int_seq_t;


mi_integer seq_int_init(mi_integer p1,mi_integer p2 ,mi_integer p3 ,MI_FPARAM *fParam) {

    int_seq_t *seq_state = NULL;

    if (      mi_fp_argisnull(fParam, 0) 
           || mi_fp_argisnull(fParam, 1)  
           || mi_fp_argisnull(fParam, 2)  
    ) {
        return(-1);
    }

    seq_state = (int_seq_t *)get_func_state_ptr(sizeof(int_seq_t),fParam);

    seq_state->start    = p1;
    seq_state->step     = p2;
    seq_state->end      = p3;
    seq_state->now      = p1;

    if ( seq_state->end >= seq_state->start ) {

        if( seq_state->step <= 0 ) {
            return(-1);
        }

    } else {

        if( seq_state->step >= 0 ) {
            return(-1);
        }
        
        seq_state->start    = p3;
        seq_state->step     = p2*-1;
        seq_state->end      = p1;
        seq_state->now      = p3;

    }
    return(0); 
}


/*
 * Three states of iterator status:
 *    SET_INIT : Allocate the defined user-state structure. 
 *    SET_RETONE : Compute the next number in the series. 
 *    SET_END : Free the user-allocated user-state structure.
 */
mi_integer seq_int( mi_integer p1,mi_integer p2 ,mi_integer p3 ,MI_FPARAM *fParam ) {
    int_seq_t *seq_state = NULL;
    mi_integer ret = -1;
   // tr ace(1,"Entry");
    switch ( mi_fp_request(fParam) ) 
    {

        case SET_RETONE:
    //        t race(1,"Retrieving State Ptr...");
            seq_state = (int_seq_t *)get_func_state_ptr(sizeof(int_seq_t),fParam);
    //        t race(1,"Got State Ptr...: %lx",seq_state);
           
           
            ret = seq_state->now;
            
            if ( seq_state->now > seq_state->end ) {
                mi_fp_setisdone(fParam, 1);
            } else {
                seq_state->now += seq_state->step;
            }
        break;

        case SET_INIT:
      //      t race(1,"SET_INIT calling init");

            if ( seq_int_init(p1,p2,p3,fParam) < 0 ) {
                mi_fp_setisdone(fParam, 1);
                return_SQLnull(0);
            }
        break;

        case SET_INVALID:
        case SET_END:
    
        break;
    }
    return(ret);
}   
    










/*

*/


