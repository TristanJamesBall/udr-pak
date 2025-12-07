// vim: set ts=4 sw=4 et:
#include "../runtime/runtime.h"
#include "../prng/prng.h"

#define BitMask48 0xffffffffffff
#define BitMask32 0xffffffff
#define BitMask16 0xffff
#define BitMask8  0xff
#define UUID_STR 40

typedef union {
    uint8_t     b[16];
    uint16_t    w[8];
    uint32_t    dw[4];
    uint64_t    qw[2];
} uuid_num_t;

mi_lvarchar *
uuidv7( MI_FPARAM *fParam) {
    uuid_num_t  uuid;
    char uuid_str[UUID_STR+1];
    uint64_t ts;
    mi_lvarchar *ret;

    ts = get_clocktick_ns() / 1000000;


    uuid.qw[0] = (ts << 16) + ( 0x7000 + ((uint64_t)*prng(fParam) & 0xfff) );
    uuid.qw[1] = (0x2ULL << 62) + (  (uint64_t)*prng(fParam) & 0x3fffffffffffffff );
    
    //snprintf( uuid_str, 40, "[%lx][%lx]", uuid.qw[0], uuid.qw[1] );
    //8-4-4-4-12
    //32 16-16-16-48
    
    snprintf( uuid_str, 40, "%08lx-%04lx-%04lx-%04lx-%012lx", 
            (uuid.qw[0] >> 32) & 0xffffffff,
            (uuid.qw[0] >> 16) & 0xffff,
            (uuid.qw[0]) & 0xffff,
            (uuid.qw[1] >> 48) & 0xffff,
            (uuid.qw[1]) & BitMask48
            );
    ret = mi_new_var( UUID_STR );
    //mi_set_varptr( ret, uuid_str );
    mi_set_vardata( ret, uuid_str );
    return( ret );
}

