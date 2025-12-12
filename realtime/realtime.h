// vim: set ts=4 sw=4 et:
#include <dmi/mi.h>
#include <time.h>

#include "../runtime/runtime.h"
#include "../tracing/tracing.h"

/* These are for datetime year to fraction conversions*/
#define DYEAR (long)10000000000
#define DMON  (long)100000000
#define DDAY  (long)1000000
#define DHOUR (long)10000
#define DMIN  (long)100

typedef enum is_gmt { LOCAL_TZ, GMT_TZ } IS_GMT_T;

typedef struct timespec timespec_t;
typedef struct {
    struct tm   tm;
    suseconds_t ns;
} ns_tm_t;

// snprintf doesn't like it if we go smaller
#define DATE_STR_BUFSZ 80
#define USE_CLOCK      CLOCK_REALTIME

mi_datetime *realtime_dt(MI_FPARAM *fParam);
mi_datetime *utc_realtime_dt(MI_FPARAM *fParam);
/*
    Might be safer
    Definitly slower
    The latter probably isn't enough to matter
*/
mi_datetime *realtime_slow_dt(MI_FPARAM *fParam);
mi_datetime *utc_realtime_slow_dt(MI_FPARAM *fParam);

/* Whole seconds, so bigint is find.
   Honestly, fester to use sysmaster:sysdhmvals
*/
mi_bigint *clocktick(void);
/*
    nanoseconds can only be represented as a decimal here,
    either because we need the fractional resolution, or because of
    wrapping risks if we're using whole numbers
*/
mi_decimal *clocktick_s(void);
mi_decimal *clocktick_ns(void);

/*
    safe either way, unless it's several thousand years in the
    future in which case I am sorry for many things
*/
mi_decimal *dec_clocktick_us(void);
mi_bigint  *int_clocktick_us(void);

/*
    Fastest, bigint, even signed is fine.
    But miilliseconds are so last year darling
*/
mi_bigint *clocktick_ms(void);

/* internal functions, not accessible to sql*/
void     timespec_to_ns_tm(const timespec_t *ts, ns_tm_t *tm, const IS_GMT_T is_gmt);
void     ns_tm_to_datetime_slow(const ns_tm_t *tm, mi_datetime *dt);
void     ns_tm_to_datetime(const ns_tm_t *tm, mi_datetime *dt);
uint64_t get_clocktick_ns(clockid_t clock);
