// Simple unit tests for realtime helpers
#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include <unistd.h>
#include <time.h>

#include "../realtime/realtime.h"
#include <dmi/mitrace.h>

int main(void) {
    uint64_t a, b;
    struct timespec ts;
    ns_tm_t tm;

    /* Basic non-zero checks */
    a = get_clocktick_ns();
    assert(a > 0 && "get_clocktick_ns returned zero");

    a = get_monotonic_ns();
    assert(a > 0 && "get_monotonic_ns returned zero");

    a = get_proc_cputime_ns();
    assert(a > 0 && "get_proc_cputime_ns returned zero");

    a = get_thread_cputime_ns();
    assert(a > 0 && "get_thread_cputime_ns returned zero");

    /* Monotonicity: successive calls should not go backward */
    a = get_monotonic_ns();
    usleep(1000); /* 1ms */
    b = get_monotonic_ns();
    assert(b >= a && "get_monotonic_ns moved backwards");

    /* timespec -> ns_tm conversion (UTC) */
    ts.tv_sec = 1609459200; /* 2021-01-01 00:00:00 UTC */
    ts.tv_nsec = 123456789;
    timespec_to_ns_tm(&ts, &tm, GMT_TZ);
    /* gmtime_r yields year since 1900 */
    assert((tm.tm.tm_year + 1900) == 2021 && "timespec_to_ns_tm year mismatch");
    assert((tm.tm.tm_mon + 1) == 1 && "timespec_to_ns_tm month mismatch");
    assert(tm.tm.tm_mday == 1 && "timespec_to_ns_tm day mismatch");
    assert(tm.ns == ts.tv_nsec && "timespec_to_ns_tm nanoseconds mismatch");

    printf("tests: realtime - OK\n");
    return 0;
}
