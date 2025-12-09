-- DROP PROCEDURE if exists trace_set;
-- DROP PROCEDURE if exists trace_on;
-- DROP PROCEDURE if exists trace_off;

execute PROCEDURE udr_trace_off();

DROP PROCEDURE if exists udr_trace_set;
DROP PROCEDURE if exists udr_trace_on;
DROP PROCEDURE if exists udr_trace_off;
DROP PROCEDURE if exists udr_trace_test;


DROP FUNCTION IF EXISTS clocktick;
DROP FUNCTION IF EXISTS clocktick_s;
DROP FUNCTION IF EXISTS clocktick_ms;
DROP FUNCTION IF EXISTS clocktick_us;
DROP FUNCTION IF EXISTS clocktick_ns;

DROP FUNCTION IF EXISTS realtime;
DROP FUNCTION IF EXISTS realtime_dt;
DROP FUNCTION IF EXISTS utc_realtime_dt;
DROP FUNCTION IF EXISTS fast_realtime_dt;
DROP FUNCTION IF EXISTS fast_utc_realtime_dt;
DROP FUNCTION IF EXISTS fast_utc_realtime_dt2;
DROP PROCEDURE IF EXISTS udr_trace_configure;

delete from systraceclasses
where name in (
select name from systraceclasses where name like 'udr%'
);


delete from systraceclasses
where name in (
select name from table(list{'udr_entry','udr_state','udr_mem','udr_state','udr_dbg'}) as ins(name)
);
DROP FUNCTION IF EXISTS udr_fn;
DROP PROCEDURE IF EXISTS udr_fn;

drop function if exists seq;

drop function if exists prng;


drop function if exists uuid;
drop function if exists uuidv7;
