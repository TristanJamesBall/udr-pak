-- Functional tests for seq() iterator UDR

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
    'seq(10) generates 0 to 9' AS test_name,
    *,
    CASE 
        WHEN    expected1 == result1 
            and expected2 == result2 
            and expected3 == result3 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        10 as expected1,
        0 as expected2,
        9 as expected3,
        *
    FROM (
        SELECT 
            COUNT(*)::integer AS result1,
            MIN(val) AS result2,
            MAX(val) AS result3
        from
        TABLE(seq(10)) AS t(val)
    )
);

-- Test 2: seq(start, end) - two parameters
insert into results
SELECT 
    'seq(5,10) generates 5 to 9' AS test_name,
    *,
    CASE 
        WHEN    expected1 == result1 
            and expected2 == result2 
            and expected3 == result3 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        5 as expected1,
        5 as expected2,
        9 as expected3,
        *
    FROM (
        SELECT 
            COUNT(*)::integer AS result1,
            MIN(val) AS result2,
            MAX(val) AS result3
        from
        TABLE(seq(5,10)) AS t(val)
    )
);

insert into results
SELECT 
    'seq(0,5,20) generates 0,5,10,15' AS test_name,
    *,
    CASE 
        WHEN    expected1 == result1 
            and expected2 == result2 
            and expected3 == result3 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        4 as expected1,
        0 as expected2,
        15 as expected3,
        *
    FROM (
        SELECT 
            COUNT(*)::integer AS result1,
            MIN(val) AS result2,
            MAX(val) AS result3
        from
        TABLE(seq(0,5,20)) AS t(val)
    )
);

insert into results
SELECT 
    'seq(10,-1,0) counts down to 1' AS test_name,
    *,
    CASE 
        WHEN    expected1 == result1 
            and expected2 == result2 
            and expected3 == result3 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        10 as expected1,
        1 as expected2,
        10 as expected3,
        *
    FROM (
        SELECT 
            COUNT(*)::integer AS result1,
            MIN(val) AS result2,
            MAX(val) AS result3
        from
        TABLE(seq(10, -1, 0)) AS t(val)
    )
);

insert into results
SELECT 
    'seq(-5) generates 0,-1,-2,-3,-4' AS test_name,
    *,
    CASE 
        WHEN    expected1 == result1 
            and expected2 == result2 
            and expected3 == result3 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        5 as expected1,
        -4 as expected2,
        0 as expected3,
        *
    FROM (
        SELECT 
            COUNT(*)::integer AS result1,
            MIN(val) AS result2,
            MAX(val) AS result3
        from
        TABLE(seq(-5)) AS t(val)
    )
);


-- Test 6: seq in cross join
insert into results
SELECT 
    'seq cross join' AS test_name,
    *,
    CASE 
        WHEN    expected1 == result1 
            and expected2 == result2 
            and expected3 == result3 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        50 as expected1,
        0 as expected2,   /* 0 + 0 */
        13 as expected3,  /* 4 + 9 */
        *
    FROM (
        SELECT 
            COUNT(*)::integer AS result1,
            MIN(v1+v2) AS result2,
            MAX(v1+v2) AS result3
        from
        TABLE(seq(10)) AS t1(v1)    
        CROSS JOIN TABLE(seq(5)) AS t2(v2)
    )
);


insert into results
SELECT 
    'seq(0,0,10) returns empty' AS test_name,
    *,
    CASE 
        WHEN    expected1 == result1 
            and nvl(expected2,'null') == nvl(result2,'null')
            and nvl(expected3,'null') == nvl(result3,'null')
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        0 as expected1,
        null::integer as expected2,  
        null::integer as expected3,  
        *
    FROM (
        SELECT 
            COUNT(*)::integer AS result1,
            MIN(v1) AS result2,
            MAX(v1) AS result3
        from
        TABLE(seq(0,0,10)) AS t1(v1)    
    )
);

insert into results
SELECT 
    'seq(1,1,100) arithmetic sum' AS test_name,
    *,
    CASE 
        WHEN    expected1 == result1 
            and nvl(expected2,'null') == nvl(result2,'null')
            and nvl(expected3,'null') == nvl(result3,'null')
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        99 as expected1,
        4950 as expected2,  
        null::integer as expected3,  
        *
    FROM (
        SELECT 
            COUNT(*)::integer AS result1,
            sum(v1) AS result2,
            null::integer AS result3
        from
        TABLE(seq(1,1,100)) AS t1(v1)    
    )
);

unload to '../results/results.txt'
select * from results;