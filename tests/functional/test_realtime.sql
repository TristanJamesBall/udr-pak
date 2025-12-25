
DATABASE ci_test;


create temp table results ( 
    test_name lvarchar(64),
    expected  lvarchar(128),
    result  lvarchar(128),
    status  lvarchar(6)
    );

insert into results values('test_name','expected','result','status');


insert into results
SELECT 
    'realtime reasonable dates' AS test_name,
    'between '||lo_bound ||' and '||hi_bound as expected,
    result,
    case when result between lo_bound and hi_bound then 'PASS' else 'FAIL' end as status
from (
 select
        current::datetime year to day - 5 units day as lo_bound,
        current::datetime year to day + 5 units day as hi_bound,
        realtime() as result
    from
        sysmaster:sysdual
);

insert into results
SELECT 
    'realtime_dt reasonable dates' AS test_name,
    'between '||lo_bound ||' and '||hi_bound as expected,
    result,
    case when result between lo_bound and hi_bound then 'PASS' else 'FAIL' end as status
from (
 select
        current::datetime year to day - 5 units day as lo_bound,
        current::datetime year to day + 5 units day as hi_bound,
        realtime_dt() as result
    from
        sysmaster:sysdual
);

insert into results
SELECT 
    'utc_realtime_dt reasonable dates' AS test_name,
    'between '||lo_bound ||' and '||hi_bound as expected,
    result,
    case when result between lo_bound and hi_bound then 'PASS' else 'FAIL' end as status
from (
 select
        current::datetime year to day - 5 units day as lo_bound,
        current::datetime year to day + 5 units day as hi_bound,
        utc_realtime_dt() as result
    from
        sysmaster:sysdual
);


insert into results
SELECT
    'clocktick() returns positive bigint' AS test_name,
    *,
    CASE
        WHEN result >= expected THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
FROM (
        SELECT
            1577797200 as expected, /* 2020-01-01 00:00:00 */
            clocktick() as result
        FROM sysmaster:sysdual
    );

insert into results
SELECT
    'clocktick_s() returns positive bigint' AS test_name,
    *,
    CASE
        WHEN result >= expected THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
FROM (
        SELECT
            1577797200 as expected, /* 2020-01-01 00:00:00 */
            clocktick_s() as result
        FROM sysmaster:sysdual
    );

insert into results
SELECT
    'clocktick_ms() returns positive bigint' AS test_name,
    *,
    CASE
        WHEN result >= expected THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
FROM (
        SELECT
            1577797200000 as expected, /* 2020-01-01 00:00:00 */
            clocktick_ms() as result
        FROM sysmaster:sysdual
    );


insert into results
SELECT
    'clocktick_us() returns positive bigint' AS test_name,
    *,
    CASE
        WHEN result >= expected THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
FROM (
        SELECT
            1577797200000000 as expected, /* 2020-01-01 00:00:00 */
            clocktick_us() as result
        FROM sysmaster:sysdual
    );


-- Test 10: realtime_dt() is monotonically increasing over calls
insert into results
SELECT
    'realtime_dt() monotonic' AS test_name,
    *,
    CASE
        WHEN result >= expected THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
from
(
    select
        99 as expected,
        sum(case when ts > prev_ts then 1 end) as result
    from (
        select
            ts,
            lag(ts) over (order by n) as prev_ts
        from (
            SELECT n,realtime_dt() AS ts,yield_ms(1) FROM TABLE(seq(100)) s(n) order by n
        )
    )
);


insert into results
SELECT 
    'clocktick variants relationship' AS test_name,
    'between '||lo_bound ||' and '||hi_bound as expected,
    result,
    case when result between lo_bound and hi_bound then 'PASS' else 'FAIL' end as status
from (
 select
        998 as lo_bound,
        1002 as hi_bound,
        (tick_ns/tick_us)::integer result
    FROM (
        SELECT
            clocktick_ns() AS tick_ns,
            clocktick_us() AS tick_us
    FROM 
        sysmaster:sysdual
)
);
   

unload to '../results/results.txt'
select * from results;