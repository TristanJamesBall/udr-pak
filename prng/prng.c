// vim: set ts=4 sw=4 et:
#include "../tracing/tracing.h"
#include "../runtime/runtime.h"
#include "../realtime/realtime.h"
#include <time.h>
#include "prng.h"


/*  
    This is an informix port of xoshiro256** Written in 2018 
    by David Blackman and Sebastiano Vigna (vigna@acm.org)

    Please see the ./orig/ folder for the original versions and license

    This Code release under the same license
*/

static inline uint64_t rotl(const uint64_t x, int k) {
    return (x << k) | (x >> (64 - k));
}

/* 
    seeding and state
    Using a combination of the Session ID, and various clocks,
    filtered through splitmix64, we create our
    set of 4 uint64_t state values for the prng below to start with
    
*/
xsr256_state_t*
init_xsr256_state(
    MI_FPARAM *fParam
) {

    xsr256_state_t *s;
    uint64_t sid,sm64_z;
    uint32_t i;
    timespec_t ts;
    clockid_t clocks[] = {CLOCK_REALTIME,CLOCK_MONOTONIC,CLOCK_THREAD_CPUTIME_ID,CLOCK_REALTIME};

            
    s = (xsr256_state_t *)get_func_state_ptr(sizeof(xsr256_state_t),fParam);

#ifdef  MI_SERVBUILD
    if isNull(s->conn) {
        // Only do this once, as mi_connect allocates memory in PER_STMT_EXEC 
        // (aka, it's new memory every time, but it hangs around until the end 
        // the statement. 
        s->conn = mi_open(NULL, NULL, NULL);
    }
    sid = (uint64_t)mi_get_id(s->conn, MI_SESSION_ID);
#else
    //dummy for testing outside server
    sid = 1;
#endif    
        
    

    for(i=0;i <= 3; i++ ) {

        clock_gettime(clocks[i], &ts);

        s->sm64_x = ( ( (uint64_t)(ts.tv_sec*NSEC)+ts.tv_nsec) ^( (sid & 0xffffffffULL ) <<32) );

        sm64_z = (s->sm64_x += 0x9e3779b97f4a7c15ULL);
        sm64_z = (sm64_z ^ (sm64_z >> 30)) * 0xbf58476d1ce4e5b9ULL;
        sm64_z = (sm64_z ^ (sm64_z >> 27)) * 0x94d049bb133111ebULL;

        s->xsr_s[i] = sm64_z ^ (sm64_z >> 31);
    }
    return(s);
}

/* interfact wrapper, could probably be factored out now*/
mi_bigint *
xoshiro256_star_star(MI_FPARAM *fParam) {
    mi_bigint *ret;
    uint64_t uret;
    xsr256_state_t *s;


    s = init_xsr256_state(fParam);
    ret = udr_alloc_ret(mi_bigint);

    _xoshiro256_star_star(&uret,s,fParam);
    *ret = (int64_t)uret;

    return(ret);
}


void _xoshiro256_star_star(uint64_t *r, xsr256_state_t *s,  MI_FPARAM *fParam) {
    uint64_t t;

    if isNull(s) {
        s = init_xsr256_state(fParam);
    } 
    if isNull(s) {
        return; //_enomem();
    }

    
    *r = (rotl(s->xsr_s[1] * 5, 7) * 9) >>1;
    t = s->xsr_s[1] << 17;

    s->xsr_s[2] ^= s->xsr_s[0];
    s->xsr_s[3] ^= s->xsr_s[1];
    s->xsr_s[1] ^= s->xsr_s[2];
    s->xsr_s[0] ^= s->xsr_s[3];
    s->xsr_s[2] ^= t;
    s->xsr_s[3] = rotl(s->xsr_s[3], 45);

    return;
}

