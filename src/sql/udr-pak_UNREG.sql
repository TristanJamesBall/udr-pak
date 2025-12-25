


drop cast if exists (lvarchar as any_int );
drop cast if exists (any_int as lvarchar );

drop cast if exists (smallint as any_int );
drop cast if exists (integer as any_int );
drop cast if exists (bigint as any_int );
drop cast if exists (boolean as any_int );

drop cast if exists (any_int as smallint );
drop cast if exists (any_int as integer );
drop cast if exists (any_int as bigint );
drop cast if exists (any_int as boolean );

/*
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

drop function if exists to_hex;
drop function if exists to_hex4;
drop function if exists seq;

drop function if exists prng;


drop function if exists uuidv4;
drop function if exists uuidv7;
*/