-- Functional tests for PRNG UDRs
-- Tests: prng(), to_hex(), to_hex4()
DATABASE ci_test;

create temp table results ( 
    test_name lvarchar(64),
    expected  lvarchar(32),
    result  lvarchar(32),
    status  lvarchar(6)
    );


insert into results values('test_name','expected','result','status');

insert into results
SELECT
    'prng() returns value' AS test_name,
    *,
    CASE
        WHEN expected == result THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
from (
    SELECT
        't'::boolean as expected,
        len(prng()::lvarchar) > 5 as result
    FROM sysmaster:sysdual
);

insert into results
SELECT
    'prng() generates different values' AS test_name,
    *,
    CASE
        WHEN result >= expected THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
FROM (
        SELECT
            90 as expected,
            count(distinct(prng()))::integer result
        FROM TABLE(seq(100))
    );


insert into results
SELECT
    'prng() generates no nulls' AS test_name,
    *,
    CASE
        WHEN result == expected THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
FROM (
        SELECT
            1000 as expected,
            count(prng())::integer result
        FROM TABLE(seq(1000))
    );

insert into results
SELECT
    'prng() distribution sanity' AS test_name,
    *,
    case when result <= expected then 'PASS' else 'FAIL' end as status
FROM (
        select
            10 as expected,
            round( ((abs(positive_count - negative_count)/1000)*100) ,1) as result
        from (
        select
            sum(case when val > 0 then 1 end) positive_count,
            sum(case when val < 0 then 1 end) negative_count
        from (
            SELECT prng() AS val FROM TABLE(seq(1000))
        )
        )
    );


-- Test 5: to_hex() with prng()
insert into results
SELECT
    'to_hex(prng()) generates no nulls' AS test_name,
    *,
    CASE
        WHEN result == expected THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
FROM (
        SELECT
            10 as expected,
            count(to_hex(prng()))::integer result
        FROM TABLE(seq(10))
    );

insert into results
SELECT
    'to_hex4(prng()) generates no nulls' AS test_name,
    *,
    CASE
        WHEN result == expected THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
FROM (
        SELECT
            10 as expected,
            count(to_hex4(prng()))::integer result
        FROM TABLE(seq(10))
    );

unload to '../results/results.txt'
select * from results;