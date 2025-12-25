-- Functional tests for utility UDRs
-- Tests: to_hex(), to_hex4(), udr_fn()
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
    test_name,
    expected,
    result,
    CASE
        WHEN expected == result THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
from (
        SELECT
            'to_hex(65535) = ffff' AS test_name,
            'ffff' AS expected,
            to_hex(65535) AS result
        FROM sysmaster:sysdual 
    );

insert into results
SELECT
    test_name,
    expected,
    result,
    CASE
        WHEN expected == result THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
    from (
        SELECT
            'to_hex(0) = 0' AS test_name,
            '0' AS expected,
            to_hex(0) AS result
        FROM sysmaster:sysdual
    );


insert into results
SELECT
    test_name,
    expected,
    result,
    CASE
        WHEN expected == result THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
    from (
        SELECT
            'to_hex(-1::smallint)' AS test_name,
            'ffff' AS expected,
            to_hex(-1::smallint) AS result
        FROM sysmaster:sysdual
    );

insert into results
SELECT
    test_name,
    expected,
    result,
    CASE
        WHEN expected == result
            THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
    from (
SELECT
            'to_hex(-1::integer)' AS test_name,
            'ffffffff' AS expected,
            to_hex(-1 :: INTEGER) AS result
        FROM sysmaster:sysdual
    );

insert into results
SELECT
    test_name,
    expected,
    result,
    CASE
        WHEN expected == result
            THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
from (
        SELECT
            'to_hex(-1::bigint)' AS test_name,
            'ffffffffffffffff' AS expected,
            to_hex(-1 :: bigint) AS result
        FROM sysmaster:sysdual
    );

insert into results
SELECT
    test_name,
    expected,
    result,
    CASE
        WHEN expected == result
            THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
FROM (
        SELECT
            'to_hex4(255) format' AS test_name,
            '00ff' AS expected,
            to_hex4(255) AS result
        FROM sysmaster:sysdual 
    );

insert into results
SELECT
    test_name,
    expected,
    result,
    CASE
        WHEN expected == result THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
FROM (
        SELECT
            'to_hex(NULL) handling' AS test_name,
            'null_val' AS expected,
            nvl(to_hex(NULL), 'null_val') AS result
        FROM sysmaster :sysdual
    );


insert into results
SELECT
    test_name,
    expected,
    result,
    CASE
        WHEN expected == result THEN 'PASS'
        ELSE 'FAIL'
    END AS STATUS
FROM (
        SELECT
            'to_hex() consistency' AS test_name,
            '1' AS expected,
            COUNT(DISTINCT hex_val) AS result
        FROM (
                SELECT
                    to_hex(12345) AS hex_val
                FROM TABLE(seq(100)) AS t(val)
            )
    );

unload to '../results/results.txt'
select * from results;