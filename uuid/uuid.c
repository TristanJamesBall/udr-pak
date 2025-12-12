// vim: set ts=4 sw=4 et:
#include <dmi/mi.h>
#include <inttypes.h>
#include <time.h>

#include "../prng/prng.h"
#include "../realtime/realtime.h"
#include "../runtime/runtime.h"

#define BitMask48 0x0000ffffffffffffULL
#define BitMask32 0xffffffffU
#define BitMask16 0xffffU
#define BitMask8  0xffU
#define UUID_STR  36

typedef union {
    uint8_t  b[16];
    uint16_t w[8];
    uint32_t dw[4];
    uint64_t qw[2];
} uuid_num_t;

mi_lvarchar *uuidv7(MI_FPARAM *fParam) {
    uuid_num_t   uuid;
    char         uuid_str[UUID_STR + 1];
    uint64_t     ts;
    mi_lvarchar *ret;

    ts = get_clocktick_ns(CLOCK_REALTIME) / 1000000;
    set_safe_duration();

    mi_bigint *p1 = prng(fParam);
    if (isNull(p1)) {
        return_enomem(NULL);
    }

    mi_bigint *p2 = prng(fParam);
    if (isNull(p2)) {
        return_enomem(NULL);
    }

    uuid.qw[0] = (ts << 16) + (0x7000 + ((uint64_t)(*p1) & 0xfffULL));
    uuid.qw[1] = (0x2ULL << 62) + ((uint64_t)(*p2) & 0x3fffffffffffffffULL);

    // 8-4-4-4-12
    // 32-16-16-16-48

    snprintf(uuid_str, 40, "%08x-%04x-%04x-%04x-%012lx", (uint32_t)((uuid.qw[0] >> 32) & BitMask32),
             (uint16_t)((uuid.qw[0] >> 16) & BitMask16), (uint16_t)(uuid.qw[0] & BitMask16), (uint16_t)((uuid.qw[1] >> 48) & BitMask16),
             (uint64_t)(uuid.qw[1] & BitMask48));

    ret = mi_new_var(UUID_STR);
    if (isNull(ret)) {
        return_enomem(NULL);
    }
    mi_set_vardata(ret, uuid_str);

    return ret;
}
