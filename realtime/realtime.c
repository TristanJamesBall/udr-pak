// vim: set ts=4 sw=4 et:
#include "../tracing/tracing.h"
#include "../runtime/runtime.h"

#include <time.h>
#include "realtime.h"
//#include <sys/time.h>
//#include <sys/types.h>

/*
    realtime_dt

    Returns current real time int datetime year to fraction(5) form, in
    the locale timezone

    Returned mi_datetime is allocated with FOR_ROUTINE

*/


mi_datetime *
threadtime_dt( 
    MI_FPARAM   *fParam 
) 
{

    mi_datetime *ret;
    timespec_t ts;
    ns_tm_t tm;

    clock_gettime(CLOCK_THREAD_CPUTIME_ID,&ts);

    ret = udr_alloc_ret(mi_datetime);
    if isNull(ret) {
        return_enomem(NULL);
    }

    timespec_to_ns_tm( &ts, &tm, GMT_TZ );
    ns_tm_to_datetime(&tm,ret);
    return(ret);
}

mi_datetime *
proctime_dt( 
    MI_FPARAM   *fParam 
) 
{

    mi_datetime *ret;
    timespec_t ts;
    ns_tm_t tm;

    clock_gettime(CLOCK_PROCESS_CPUTIME_ID,&ts);

    ret = udr_alloc_ret(mi_datetime);
    if isNull(ret) {
        return_enomem(NULL);
    }

    timespec_to_ns_tm( &ts, &tm, GMT_TZ );
    ns_tm_to_datetime(&tm,ret);
    return(ret);
}



mi_datetime *
monotime_dt( 
    MI_FPARAM   *fParam 
) 
{

    mi_datetime *ret;
    timespec_t ts;
    ns_tm_t tm;

    clock_gettime(CLOCK_MONOTONIC,&ts);

    ret = udr_alloc_ret(mi_datetime);
    if isNull(ret) {
        return_enomem(NULL);
    }

    timespec_to_ns_tm( &ts, &tm, GMT_TZ );
    ns_tm_to_datetime(&tm,ret);
    return(ret);
}


mi_datetime *
realtime_dt( 
    MI_FPARAM   *fParam 
) 
{

    mi_datetime *ret;
    timespec_t ts;
    ns_tm_t tm;

    clock_gettime(CLOCK_REALTIME,&ts);

    ret = udr_alloc_ret(mi_datetime);
    if isNull(ret) {
        return_enomem(NULL);
    }

    timespec_to_ns_tm( &ts, &tm, LOCAL_TZ );
    ns_tm_to_datetime(&tm,ret);
    return(ret);
}

mi_datetime *
utc_realtime_dt( MI_FPARAM *fParam ) {

        mi_datetime *ret;
        timespec_t ts;
        ns_tm_t tm;

        clock_gettime(CLOCK_REALTIME,&ts);

        ret = udr_alloc_ret(mi_datetime);
        if isNull(ret) {
            return_enomem(NULL);
        }

        timespec_to_ns_tm( &ts, &tm, GMT_TZ );
        ns_tm_to_datetime(&tm,ret);
        return(ret);
}




__always_inline uint64_t
get_proc_cputime_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID,&ts);
    return (uint64_t) (ts.tv_sec*NSEC) + (ts.tv_nsec);
}

__always_inline uint64_t
get_thread_cputime_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_THREAD_CPUTIME_ID,&ts);
    return (uint64_t) (ts.tv_sec*NSEC) + (ts.tv_nsec);
}

/* see man clock_gettime */
__always_inline uint64_t
get_monotonic_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t) (ts.tv_sec*NSEC) + (ts.tv_nsec);
}

__always_inline uint64_t
get_clocktick_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return (uint64_t) (ts.tv_sec*NSEC) + (ts.tv_nsec);
}
/*
    realtime_dt_slow

    Returns current real time int datetime year to fraction(5) form, in
    the locale timezone

    Slower variant doesn't leaverage the mi_decimal storage of datetimes,
    and rather uses "official" informix or library functions.

    Use this if you have trouble with the nomal versions

*/



mi_datetime *
realtime_dt_slow( 
    MI_FPARAM *fParam 
) {

    mi_datetime *ret;
    timespec_t ts;
    ns_tm_t tm;


    clock_gettime(CLOCK_REALTIME,&ts);

    ret = udr_alloc_ret(mi_datetime);
    if isNull(ret) {
        return_enomem(NULL);
    }

    timespec_to_ns_tm( &ts, &tm, LOCAL_TZ );
    ns_tm_to_datetime_slow(&tm,ret);
    return(ret);
}


/*
    realtime_slow_dt

    Returns current real time int datetime year to fraction(5) form, in
    the utc time zone

    Slower variant doesn't leaverage the mi_decimal storage of datetimes,
    and rather uses "official" informix or library functions.

    Use this if you have trouble with the nomal versions

*/


mi_datetime *
utc_realtime_dt_slow( 
    MI_FPARAM *fParam 
) 
{
    mi_datetime *ret;
    timespec_t ts;
    ns_tm_t tm;

    clock_gettime(CLOCK_REALTIME,&ts);

    ret = udr_alloc_ret(mi_datetime);
    if isNull(ret) {
        return_enomem(NULL);
    }

    timespec_to_ns_tm( &ts, &tm, GMT_TZ );
    ns_tm_to_datetime_slow(&tm,ret);
    return(ret);
}




inline void 
timespec_to_ns_tm( 
    const timespec_t    *ts, 
    ns_tm_t             *tm,
    const IS_GMT_T      is_gmt  
) 
{
    if( is_gmt ) {
        gmtime_r( &ts->tv_sec, &tm->tm );
    } else {
        localtime_r( &ts->tv_sec, &tm->tm );
    }
    tm->ns = ts->tv_nsec;
}


/*
    ns_tm_to_datetime()

    Converts a ns_tm ( unix tm + nanoseconds ) to an Informix datetime
    
    ns_tm is assumed to already by converted to the correct timezone
    ( see timespec_to_ns_tm() )

    This version becomes very simple by recogising the very straight
    forward way Innformix stores datetimes.

    I wrote "generic" version of this that handled different resolutions
    but it gets substantially more complicated, or slower, or both

*/

inline void 
ns_tm_to_datetime (
    const ns_tm_t   *tm, 
    mi_datetime     *dt
)
{
    int64_t     int_time;
    dec_t       frac_part, nsec;


    
    /* 
        these multipliers are spefifically for "year to second" -> "year to fraction"
        the intent is to create a number that looks like
        
        20241231235959
        or
        20241231235959.12345
        
        Because that, in MI_DECIMAL form, is how how datetime's are represented!

    */
    int_time = (  
          (((long)tm->tm.tm_year + 1900) * DYEAR )
        + (((long)tm->tm.tm_mon  + 1   ) * DMON )
        + ( (long)tm->tm.tm_mday * DDAY )
        + ( (long)tm->tm.tm_hour * DHOUR )
        + ( (long)tm->tm.tm_min  * DMIN )
        + ( (long)tm->tm.tm_sec )
    );

    /* 
        I did test a time->string->decimal version, which requires fewer function
        calls but is still slower
    */

    int64_to_dec( int_time, &dt->dt_dec );  

    int64_to_dec( tm->ns, &frac_part ); 
    int64_to_dec( NSEC, &nsec ); 
    decdiv( &frac_part, &nsec, &frac_part );
    dectrunc( &frac_part, 5 );

    decadd( &dt->dt_dec, &frac_part, &dt->dt_dec);
    
    /* Ensure *dt is 'year to fraction(5) */
    dt->dt_qual=TU_DTENCODE( TU_YEAR,TU_F5);
 
}



/*
    ns_tm_to_datetime_slow() aka ns_tm_to_datetime_safe()

    Converts a ns_tm ( unix tm + nanoseconds ) to an Informix datetime
    
    Same as above, but using only standard informix/system library functions.

    So far as I can tell, in glibc at list, strftime does no internal allocations, so
    should be safe. ( don't use strftime_l though it might )

*/

inline void
ns_tm_to_datetime_slow (
    const ns_tm_t   *tm, 
    mi_datetime     *dt
)  
{
    mi_datetime *dt_tmp;
    char buf[DATE_STR_BUFSZ];


    strftime( buf, DATE_STR_BUFSZ, "%Y-%m-%d %H:%M:%S", &tm->tm );
    
    snprintf( &buf[19], 8, ".%05ld", (tm->ns/10000) % FRAC5  );
    
    /* allocates, so copy and free */
    dt_tmp = mi_string_to_datetime( buf, "datetime year to fraction(5)");

    *dt = *dt_tmp;
    
    mi_free(dt_tmp);

}












