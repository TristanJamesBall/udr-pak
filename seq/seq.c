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

#define PMAP_000 0
#define PMAP_001 1
#define PMAP_010 2
#define PMAP_011 3
#define PMAP_100 4
#define PMAP_101 5
#define PMAP_110 6
#define PMAP_111 7

mi_integer seq_int_init(mi_integer p1,mi_integer p2 ,mi_integer p3 ,MI_FPARAM *fParam) {

    int_seq_t *seq_state = NULL;
    uint8_t p_map = 0;

    p_map |= notArgNull(fParam, 0)  << 2;
    p_map |= notArgNull(fParam, 1)  << 1;
    p_map |= notArgNull(fParam, 2)  ;

    if ( PMAP_000 == p_map ) {
        return(-1);
    }    

    seq_state = (int_seq_t *)get_func_state_ptr(sizeof(int_seq_t),fParam);

    /* our 3 parameters aren't really positional, although the way informix works
       parameters are either named or positional.

       We don't want that, we want to do "the right thing" depend in whether 
       we were given 1, 2, or 3 parameters - recognising that (null,value,value)
       is something that informix will allow but is different to (value,value)
       
       So, this is how we map the different combinations of our 3 parameters being
       set, or null, into the "1, 2, or 3" variants we care about
    */

    /* 
        In the switch be, 1's on the PMAP_ represent parameters that are
        set, left to right, so PMAP_101 would be when P1 and P3 are set, but
        p2 is null
    */
    switch (p_map) {

        case PMAP_001:
            seq_state->now      = 0;
            seq_state->start    = 0;
            seq_state->step     = (p3>0) ? 1 : -1;;
            seq_state->end      = p3;
        break;
        case PMAP_010:
            // Should probably be an error?
            seq_state->now      = 0;
            seq_state->start    = 0;
            seq_state->step     = (p2>0) ? 1 : -1;;
            seq_state->end      = p2;
        break;
        case PMAP_100:
            seq_state->now      = 0;
            seq_state->start    = 0;
            seq_state->step     = (p1>0) ? 1 : -1;
            seq_state->end      = p1;
        break;
        case PMAP_101:
            seq_state->now      = p1;
            seq_state->start    = p1;
            seq_state->step     = (p3>p1) ? 1 : -1;
            seq_state->end      = p3;
        break;
        case PMAP_110:
            seq_state->now      = p1;
            seq_state->start    = p1;
            seq_state->step     = (p2>p1) ? 1 : -1;
            seq_state->end      = p2;
        break;
         case PMAP_011:
            seq_state->now      = p2;
            seq_state->start    = p2;
            seq_state->step     = (p3>p2) ? 1 : -1;
            seq_state->end      = p3;
        break;
       case PMAP_111:
            seq_state->now      = p1;
            seq_state->start    = p1;
            seq_state->step     = p2;
            seq_state->end      = p3;
        break;
    }
    if( seq_state->step == 0 || seq_state->start == seq_state->end) {
        return(-1);
    }

    if ( seq_state->end < seq_state->start && seq_state->step > 0) {
        seq_state->step *= -1;
    } else if (seq_state->end > seq_state->start && seq_state->step < 0) {
        seq_state->step *= -1;
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

    set_safe_duration();

    switch ( mi_fp_request(fParam) ) 
    {

        case SET_RETONE:

            /* 
                this is critical, otherwise the sequence will continue to run
                past "first n" limites or ctrl-c cancels ( although the additional data is thrown away)
            */
            if ( mi_interrupt_check() != 0) {
                mi_fp_setisdone(fParam, 1);
                return_SQLnull(0);
                break;
            }

            seq_state = (int_seq_t *)get_func_state_ptr(sizeof(int_seq_t),fParam);
           
            ret = seq_state->now;
            
            if ( seq_state->step > 0 && seq_state->now > seq_state->end ) {
                mi_fp_setisdone(fParam, 1);
            } else if ( seq_state->step < 0 && seq_state->now < seq_state->end ) {
                mi_fp_setisdone(fParam, 1);
            } else {
                seq_state->now += seq_state->step;
            }
        break;

        case SET_INIT:
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


