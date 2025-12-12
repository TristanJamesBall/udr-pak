// vim: set ts=4 sw=4 et:
#include <dmi/mi.h>
#include <inttypes.h>
#include <sys/time.h>
#include <time.h>

#define prng xoshiro256_star_star
typedef struct timespec timespec_t;

typedef struct {
    uint64_t xsr_s[4]; // the xoro* function state
    uint64_t sm64_x;   // splitmix64 seed
    uint64_t sid;
} xsr256_state_t;

xsr256_state_t *init_xsr256_state(MI_FPARAM *fParam);
mi_bigint      *xoshiro256_star_star(MI_FPARAM *fParam);
void            _xoshiro256_star_star(uint64_t *r, xsr256_state_t *s, MI_FPARAM *fParam);
