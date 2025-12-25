-- Functional tests for UUID UDRs
-- Tests: uuidv7(), uuidv4()

DATABASE ci_test;
create temp table results ( 
    test_name lvarchar(64),
    expected1  lvarchar(128),
    expected2  lvarchar(128),
    expected3  lvarchar(128),
    result1    lvarchar(128),
    result2    lvarchar(128),
    result3    lvarchar(128),
    status  lvarchar(6)
);

insert into results values('test_name','expected1','expected2','expected3','result1','result2','result3','status');

insert into results
SELECT 
    'uuidv4() format validation' AS test_name,
    *,
    CASE 
        WHEN    result1 == expected1 
            and result2 == expected2 
            and result3 matches expected3  
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        36 as expected1,
        '----' as expected2,
            '[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
        ||  '-'
        ||  '[0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
        ||  '-'
        ||  '[0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
        ||  '-'
        ||  '[0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
        ||  '-'
        ||  '[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
        as expected3,
        *
    FROM (
        SELECT 
            LENGTH(u1) as result1,
            SUBSTR(u1, 9, 1) 
                || SUBSTR(u1, 14, 1) 
                || SUBSTR(u1, 19, 1) 
                || SUBSTR(u1, 24, 1) as result2,
            u1 as result3
        from (
            select uuidv4() u1 from TABLE(seq(1)) AS t(val)
        )
    )
);

insert into results
SELECT 
    'uuidv7() format validation' AS test_name,
    *,
    CASE 
        WHEN    result1 == expected1 
            and result2 == expected2 
            and result3 matches expected3  
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        36 as expected1,
        '----' as expected2,
            '[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
        ||  '-'
        ||  '[0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
        ||  '-'
        ||  '[0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
        ||  '-'
        ||  '[0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
        ||  '-'
        ||  '[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
        as expected3,
        *
    FROM (
        SELECT 
            LENGTH(u1) as result1,
            SUBSTR(u1, 9, 1) 
                || SUBSTR(u1, 14, 1) 
                || SUBSTR(u1, 19, 1) 
                || SUBSTR(u1, 24, 1) as result2,
            u1 as result3
        from (
            select uuidv7() u1 from TABLE(seq(1)) AS t(val)
        )
    )
);


insert into results
SELECT 
    'uuidv4() uniqueness' AS test_name,
    *,
    CASE 
        WHEN    result1 == expected1 
            and result2 == expected2 
            and nvl(result3,'null') == nvl(expected3,'null') 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        10000 as expected1,
        10000 as expected2,
        null::integer as expected3,
        *
    FROM (
        SELECT 
            COUNT(distinct(u1)) AS result1,
            COUNT(*) AS result2,
            null::integer as result3
        from (
            SELECT uuidv4() AS u1  FROM TABLE(seq(10000))
        )
    )
);

insert into results
SELECT 
    'uuidv7() uniqueness' AS test_name,
    *,
    CASE 
        WHEN    result1 == expected1 
            and result2 == expected2 
            and nvl(result3,'null') == nvl(expected3,'null') 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        10000 as expected1,
        10000 as expected2,
        null::integer as expected3,
        *
    FROM (
        SELECT 
            COUNT(distinct(u1)) AS result1,
            COUNT(*) AS result2,
            null::integer as result3
        from (
            SELECT uuidv7() AS u1  FROM TABLE(seq(10000))
        )
    )
);


insert into results
SELECT 
    'uuidv7() monotonic ordering' as test_name,
     *,
     CASE 
        WHEN    result1 == expected1 
            and result2 == expected2 
            and result3 == expected3 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
    from (
        select
            10 as expected1,
            9 as expected2,  /* first row as null lag */
            9 as expected3,
            *
        from (
            select 
                count(*)::integer as result1,
                sum(case when left(u,13) > left(prev_u,13) then 1 end ) as result2,
                sum(case when right(u,23) <> right(prev_u,23) then 1 end ) as result3
            FROM (
                select u,lag(u) over (order by n) prev_u from ( select n,uuidv7() u from table(__slow_seq(10)) s(n) )
            )
        )
    );

unload to '../results/results.txt'
select * from results;