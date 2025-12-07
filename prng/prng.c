// vim: set ts=4 sw=4 et:
#include "../tracing/tracing.h"
#include "../runtime/runtime.h"
#include "../realtime/realtime.h"
#include "prng.h"


/*  Written in 2018 by David Blackman and Sebastiano Vigna (vigna@acm.org)

To the extent possible under law, the author has dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide.

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. */


/* This is xoshiro256** 1.0, one of our all-purpose, rock-solid
   generators. It has excellent (sub-ns) speed, a state (256 bits) that is
   large enough for any parallel application, and it passes all tests we
   are aware of.

   For generating just floating-point numbers, xoshiro256+ is even faster.

   The state must be seeded so that it is not everywhere zero. If you have
   a 64-bit seed, we suggest to seed a splitmix64 generator and use its
   output to fill s. */


static inline uint64_t rotl(const uint64_t x, int k) {
    return (x << k) | (x >> (64 - k));
}

xsr256_state_t*
init_xsr256_state(MI_FPARAM *fParam) {

    xsr256_state_t *s;
    uint64_t sm64_z;
    uint64_t nanosec;
    uint32_t i;
    uint64_t sid;
    
    s = (xsr256_state_t *)get_func_state_ptr(sizeof(xsr256_state_t),fParam);

    if isNull(s->conn) {
        // Only do this once, as mi_connect allocates memory in PER_STMT_EXEC 
        // (aka, it's new memory every time, but it hangs around until the end 
        // the statement. 
        s->conn = mi_open(NULL, NULL, NULL);
    }
    sid = (uint64_t)mi_get_id(s->conn, MI_SESSION_ID);
    nanosec = get_clocktick_ns(); 
        
    
    //s->sm64_x = ( ( nanosec & 0xffffULL) << 32 ) + (sid & 0xffffULL );
    s->sm64_x = ( ( nanosec << 32 ) + (sid & 0xffffffffULL ) );

    for(i=0;i <= 3; i++ ) {
        sm64_z = (s->sm64_x += 0x9e3779b97f4a7c15ULL);
        sm64_z = (sm64_z ^ (sm64_z >> 30)) * 0xbf58476d1ce4e5b9ULL;
        sm64_z = (sm64_z ^ (sm64_z >> 27)) * 0x94d049bb133111ebULL;

        s->xsr_s[i] = sm64_z ^ (sm64_z >> 31);
    }
    return(s);


}



void _xoshiro256_star_star(uint64_t *r, xsr256_state_t *s,  MI_FPARAM *fParam) {
    uint64_t t;
    //xsr256_state_t *s;

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

mi_bigint *
xoshiro256_star_star(MI_FPARAM *fParam) {
//    uint64_t t;
    mi_bigint *ret;
    uint64_t uret;
    xsr256_state_t *s;


    s = init_xsr256_state(fParam);
    //mi_yield(); 
    ret = udr_alloc_ret(mi_bigint);

    _xoshiro256_star_star(&uret,s,fParam);
    *ret = (int64_t)uret;

    return(ret);
}


mi_bigint *
prng2(MI_FPARAM *fParam) {
    int64_t *ret;
    uint64_t sm64_z,t;
    uint8_t i,j;
    xsr256_state_t s;
    struct timespec ts;
    

        
    for(i=0;i <= 3; i++ ) {
        clock_gettime(CLOCK_TAI, &ts);

        s.sm64_x = ( ts.tv_nsec & 0xffffffff );
        for(j=0;j <= (uint8_t)(ts.tv_nsec & 0x7); j++ ) {
            sm64_z = (s.sm64_x += 0x9e3779b97f4a7c15);
            sm64_z = (sm64_z ^ (sm64_z >> 30)) * 0xbf58476d1ce4e5b9;
            sm64_z = (sm64_z ^ (sm64_z >> 27)) * 0x94d049bb133111eb;

            s.xsr_s[i] = sm64_z ^ (sm64_z >> 31);
        }
    }
    //i_yield(); 
    
    for(j=0;j <= (uint8_t)(ts.tv_nsec & 0x7); j++ ) {
        t = s.xsr_s[1] << 17;

        s.xsr_s[2] ^= s.xsr_s[0];
        s.xsr_s[3] ^= s.xsr_s[1];
        s.xsr_s[1] ^= s.xsr_s[2];
        s.xsr_s[0] ^= s.xsr_s[3];
        s.xsr_s[2] ^= t;
        s.xsr_s[3] = rotl(s.xsr_s[3], 45);
    }


    ret = udr_alloc_ret(mi_bigint);
    *ret = (rotl(s.xsr_s[1] * 5, 7) * 9) >>1;
    return((mi_bigint*)ret);
}

/*  Written in 2015 by Sebastiano Vigna (vigna@acm.org)

To the extent possible under law, the author has dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide.

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. */


/* This is a fixed-increment version of Java 8's SplittableRandom generator
   See http://dx.doi.org/10.1145/2714064.2660195 and 
   http://docs.oracle.com/javase/8/docs/api/java/util/SplittableRandom.html

   It is a very fast generator passing BigCrush, and it can be useful if
   for some reason you absolutely want 64 bits of state. */

