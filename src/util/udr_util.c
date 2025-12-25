// vim: set ts=4 sw=4 et:
//
#include "udr_util.h"
#include "../any/any.h"
#include "../realtime/realtime.h"


typedef enum { ASC, DESC } seq_order;

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

mi_integer seq_int_init(mi_integer p1, mi_integer p2, mi_integer p3, MI_FPARAM *fParam) {
    int_seq_t *seq_state = NULL;
    uint8_t    p_map     = 0;

    p_map |= notArgNull(fParam, 0) << 2;
    p_map |= notArgNull(fParam, 1) << 1;
    p_map |= notArgNull(fParam, 2);

    if (PMAP_000 == p_map) {
        return (-1);
    }

    seq_state = (int_seq_t *)get_func_state_ptr(sizeof(int_seq_t), fParam);

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
        seq_state->now   = 0;
        seq_state->start = 0;
        seq_state->step  = (p3 > 0) ? 1 : -1;
        seq_state->end   = p3;
        break;
    case PMAP_010:
        // Should probably be an error?
        seq_state->now   = 0;
        seq_state->start = 0;
        seq_state->step  = (p2 > 0) ? 1 : -1;
        seq_state->end   = p2;
        break;
    case PMAP_100:
        seq_state->now   = 0;
        seq_state->start = 0;
        seq_state->step  = (p1 > 0) ? 1 : -1;
        seq_state->end   = p1;
        break;
    case PMAP_101:
        seq_state->now   = p1;
        seq_state->start = p1;
        seq_state->step  = (p3 > p1) ? 1 : -1;
        seq_state->end   = p3;
        break;
    case PMAP_110:
        seq_state->now   = p1;
        seq_state->start = p1;
        seq_state->step  = (p2 > p1) ? 1 : -1;
        seq_state->end   = p2;
        break;
    case PMAP_011:
        seq_state->now   = p2;
        seq_state->start = p2;
        seq_state->step  = (p3 > p2) ? 1 : -1;
        seq_state->end   = p3;
        break;
    case PMAP_111:
        seq_state->now   = p1;
        seq_state->start = p1;
        seq_state->step  = p2;
        seq_state->end   = p3;
        break;
    }
    if (seq_state->step == 0 || seq_state->start == seq_state->end) {
        return (-1);
    }

    if (seq_state->end < seq_state->start && seq_state->step > 0) {
        seq_state->step *= -1;
    } else if (seq_state->end > seq_state->start && seq_state->step < 0) {
        seq_state->step *= -1;
    }

    return (0);
}

/*
 * Three states of iterator status:
 *    SET_INIT : Allocate the defined user-state structure.
 *    SET_RETONE : Compute the next number in the series.
 *    SET_END : Free the user-allocated user-state structure.
 */
mi_integer seq_int(mi_integer p1, mi_integer p2, mi_integer p3, MI_FPARAM *fParam) {
    int_seq_t *seq_state = NULL;
    mi_integer ret       = -1;

    set_safe_duration();

    switch (mi_fp_request(fParam)) {

    case SET_INIT:
        if (seq_int_init(p1, p2, p3, fParam) < 0) {
            mi_fp_setisdone(fParam, 1);
            return_SQLnull(0);
        }
        break;

    case SET_RETONE:

        /*
            this is critical, otherwise the sequence will continue to run
            past "first n" limites or ctrl-c cancels ( although the additional data
           is thrown away)
        */
        if (mi_interrupt_check() != 0) {
            mi_fp_setisdone(fParam, 1);
            return_SQLnull(0);
            break;
        }

        seq_state = (int_seq_t *)get_func_state_ptr(sizeof(int_seq_t), fParam);

        ret = seq_state->now;

        if (seq_state->step > 0 && seq_state->now >= seq_state->end) {
            mi_fp_setisdone(fParam, 1);
        } else if (seq_state->step < 0 && seq_state->now <= seq_state->end) {
            mi_fp_setisdone(fParam, 1);
        } else {
            seq_state->now += seq_state->step;
        }
        break;

    case SET_INVALID:
    case SET_END:

        break;
    }
    return (ret);
}



/* This is a debugging aid only, it generates numbers like seq, but with deliberate pauses*/
mi_integer slow_seq_int(mi_integer p1, mi_integer p2, mi_integer p3, MI_FPARAM *fParam) {
    int_seq_t *seq_state = NULL;
    mi_integer ret       = -1;

    set_safe_duration();

    switch (mi_fp_request(fParam)) {

    case SET_INIT:
        if (seq_int_init(p1, p2, p3, fParam) < 0) {
            mi_fp_setisdone(fParam, 1);
            return_SQLnull(0);
        }
        break;

    case SET_RETONE:

        /*
            this is critical, otherwise the sequence will continue to run
            past "first n" limites or ctrl-c cancels ( although the additional data
           is thrown away)
        */
        if (mi_interrupt_check() != 0) {
            mi_fp_setisdone(fParam, 1);
            return_SQLnull(0);
            break;
        }

        seq_state = (int_seq_t *)get_func_state_ptr(sizeof(int_seq_t), fParam);

        ret = seq_state->now;

        if (seq_state->step > 0 && seq_state->now >= seq_state->end) {
            mi_fp_setisdone(fParam, 1);
        } else if (seq_state->step < 0 && seq_state->now <= seq_state->end) {
            mi_fp_setisdone(fParam, 1);
        } else {
            seq_state->now += seq_state->step;
        }
        yield_ms_proc(100);
        break;

    case SET_INVALID:
    case SET_END:

        break;
    }
    return (ret);
}

/*
    hex strings without the 0x0000000000.... prefixes

    We use a custom any_int_t type here to avoid needing an overloaded function,
    because we can't have an overloaded function that accepts null parameters

    #face_bloody_palm

    We also can't just promote everything to bigint or similar, because
    we'd like to handle printing negative numbers, in normal two-compliment form

    And under that scheme, -1::smallint is different to -1::integer (ffff vs ffffffff)

    So - the any_int_t is a thin wrapper around the built in int-like types, that
    preseves knowledge of the origin type

    And so finally, correct handling of ints, negative ints, and null, in one place,
    with no more "routine cant be resolved" errors

    It's been a long day
*/

mi_lvarchar *any_to_hex(any_int_t *val, MI_FPARAM *fParam) {

    char         buf[MAXVCLEN];
    mi_lvarchar *ret;

    set_safe_duration();

    if (mi_fp_argisnull(fParam, 0) == MI_TRUE) {
        mi_fp_setreturnisnull(fParam, 0, MI_TRUE);
        return NULL;
    }

    switch (val->orig_type) {
    case CBOOLTYPE:
    case CSHORTTYPE: {
        snprintf(buf, MAXVCLEN, "%hx", (int)val->val);
        break;
    }
    case CINTTYPE: {
        snprintf(buf, MAXVCLEN, "%x", (int)val->val);
        break;
    }
    case CBIGINTTYPE: {
        snprintf(buf, MAXVCLEN, "%lx", val->val);
        break;
    }
    default: {
        mi_db_error_raise(NULL, MI_EXCEPTION, "Unknown origin type: %d", val->orig_type);
        return NULL;
        break;
    }
    }

    ret = mi_new_var(strlen(buf));
    mi_set_vardata(ret, buf);

    return (ret);
}

/*
    Hex strings, zero paded to 4 digits (32 bit)
    Just a formatting nicety as it can make visually comparing columns of results easier
*/
mi_lvarchar *any_to_hex4(any_int_t *val, MI_FPARAM *fParam) {

    char         buf[MAXVCLEN];
    mi_lvarchar *ret;
    uint16_t     len, over;
    set_safe_duration();

    if (mi_fp_argisnull(fParam, 0) == MI_TRUE) {
        mi_fp_setreturnisnull(fParam, 0, MI_TRUE);
        return NULL;
    }

    memset(buf, '0', MAXVCLEN);

    switch (val->orig_type) {
    case CBOOLTYPE:
    case CSHORTTYPE: {
        snprintf(&buf[3], MAXVCLEN, "%hx", (int)val->val);
        break;
    }
    case CINTTYPE: {
        snprintf(&buf[3], MAXVCLEN, "%x", (int)val->val);
        break;
    }
    case CBIGINTTYPE: {
        snprintf(&buf[3], MAXVCLEN, "%lx", val->val);
        break;
    }
    default: {
        mi_db_error_raise(NULL, MI_EXCEPTION, "Unknown origin type: %d", val->orig_type);
        return NULL;
        break;
    }
    }

    len  = strlen(buf);
    over = len % 4;

    ret = mi_new_var(len - over);
    mi_set_vardata(ret, &buf[over]);

    return (ret);
}

mi_lvarchar *integer_to_hex4(mi_integer val, MI_FPARAM *fParam) {

    char         buf[MAXVCLEN];
    mi_lvarchar *ret;
    uint16_t     len, over;
    set_safe_duration();

    memset(buf, '0', MAXVCLEN);
    snprintf(&buf[3], MAXVCLEN, "%x", val);
    len  = strlen(buf);
    over = len % 4;

    ret = mi_new_var(len - over);
    mi_set_vardata(ret, &buf[over]);

    return (ret);
}

mi_lvarchar *smallint_to_hex4(mi_smallint val, MI_FPARAM *fParam) {

    char         buf[MAXVCLEN];
    mi_lvarchar *ret;
    uint16_t     len, over;
    set_safe_duration();
    memset(buf, '0', MAXVCLEN);
    snprintf(&buf[3], MAXVCLEN, "%hx", val);
    len  = strlen(buf);
    over = len % 4;

    ret = mi_new_var(len - over);
    mi_set_vardata(ret, &buf[over]);

    return (ret);
}

void get_session_id(uint64_t *sid, MI_FPARAM *fParam) {
    MI_CONNECTION *conn;
    /*
        It's is ridiculously eass to leak memory if you try and preserver the
       connection, eg, as part of a long running transaction - even if you only
       connect once, _something_ leaks memory every row...

        On the other hand - this is fast anyawy, we're not really making a
       connection just hooking up to the server environment we're already in, so
       don't sweat it
    */
    conn = mi_open(NULL, NULL, NULL);
    if (isNull(conn)) {
        *sid = 0;
        abort_enomem();
    }
    *sid = (uint64_t)mi_get_id(conn, MI_SESSION_ID);
    mi_close(conn);
}

__always_inline void *get_func_state_ptr(size_t sz, MI_FPARAM *fParam) {
    void *ustate = NULL;

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
