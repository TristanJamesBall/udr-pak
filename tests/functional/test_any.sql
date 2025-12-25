
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

/* 
    Tests for the any_int_t custom type, which is a "boolean/smalling/int/bigint/null" 
    type used to workaround the difficulties of having UDR's with overloaded parameters
    that also handle nulls

    Mostly, this is tested indirectly by the fact that the to_hex() functions work
    so this is just double checking that reallly
*/

/* 
    OK, this is a little obscure, but we're testing both that the 
    lvarchar->any_int cast works, and also that when it does so, it 
    uses the the smalled type possible for the internal "origin type"
    We confirm this by using negative values, which, when printed in hex
    nicely show the different type sizes
*/
insert into results
SELECT 
    'str to any_int uses minimum size_types' AS test_name,
    *,
    CASE 
        WHEN    result1 == expected1 
            and result2 == expected2 
            and result2 == expected2
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
from (
    select
        /* to crosscheck these, use a C program to do:
                printf( "%hx\n%x\n%lx\n",-1,-32769,-2147483649 );
        */
        'ffff' as expected1,
        'ffff7fff' as expected2,
        'ffffffff7fffffff' as expected3,
        *
    FROM (
        SELECT 
            to_hex('-1'::any_int) as result1,
            to_hex('-32769'::any_int) as result2,
            to_hex('-2147483649'::any_int) as result3
        from 
            sysmaster:sysdual
        
    )
);

unload to '../results/results.txt'
select * from results;