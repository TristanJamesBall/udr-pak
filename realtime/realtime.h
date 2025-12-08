// vim: set ts=4 sw=4 et:
#include <dmi/mi.h>

#include "../tracing/tracing.h"
#include "../runtime/runtime.h"
#include <time.h>



typedef enum is_gmt{
    LOCAL_TZ,
    GMT_TZ
} IS_GMT_T;

typedef struct timespec     timespec_t;
typedef struct {
    struct tm tm;
    suseconds_t ns;
} ns_tm_t;


// snprintf doesn't like it if we go smaller
#define DATE_STR_BUFSZ 80
#define USE_CLOCK CLOCK_REALTIME


mi_datetime *realtime_dt( MI_FPARAM *fParam );
mi_datetime *utc_realtime_dt( MI_FPARAM *fParam );

void timespec_to_ns_tm( const timespec_t *ts, ns_tm_t *tm,const IS_GMT_T is_gmt);
void ns_tm_to_datetime(const ns_tm_t *tm, mi_datetime *dt);

uint64_t get_clocktick_ns(clockid_t clock);

uint64_t get_monotonic_ns(void);
uint64_t get_proc_cputime_ns(void);
uint64_t get_thread_cputime_ns(void);



mi_datetime *realtime_slow_dt( MI_FPARAM *fParam );
mi_datetime *utc_realtime_slow_dt( MI_FPARAM *fParam );
void ns_tm_to_datetime_slow(const ns_tm_t *tm, mi_datetime *dt);
