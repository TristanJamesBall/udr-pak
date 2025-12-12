CREATE PROCEDURE IF NOT EXISTS udr_trace_configure( 
	level integer default 1, 
	class lvarchar(14) default 'udrpak',
	path  lvarchar(255) default '/var/tmp/udrpak.trace.log'
) 
WITH ( HANDLESNULLS)
EXTERNAL NAME '$INFORMIXDIR/extend/udr-pak/udr-pak.so()'
LANGUAGE C;


CREATE PROCEDURE IF NOT EXISTS udr_trace_set( lvl smallint ) EXTERNAL NAME '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' LANGUAGE C;
CREATE PROCEDURE IF NOT EXISTS udr_trace_on( ) EXTERNAL NAME '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' LANGUAGE C;
CREATE PROCEDURE IF NOT EXISTS udr_trace_off() EXTERNAL NAME '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' LANGUAGE C;
CREATE PROCEDURE IF NOT EXISTS udr_trace_test() EXTERNAL NAME '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' LANGUAGE C;



{ Not allowed to merge into systraceclasses!! }

insert into systraceclasses(name)
select name from table(list{'udrpak'}) as ins(name)
where not exists ( select 1 from systraceclasses where name = ins.name) ;


-- execute procedure udr_trace_set();
-- execute procedure udr_trace_test();
--execute procedure udr_trace_off();



create function if not exists seq(
	p1 int default null,
	p2 int default null, 
	p3 int default null
) 
returns int as seq
with(ITERATOR,VARIANT,HANDLESNULLS, PARALLELIZABLE)
external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(seq_int)'
language c;

create function if not exists prng() returns bigint
	with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
	external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(xoshiro256_star_star)'
	language c
	;


create function if not exists uuidv7() returns lvarchar(36)
	with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
	external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(uuidv7)'
	language c
	;


/* "default" version */
create function if not exists realtime() returns datetime year to fraction(5) 
	with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
	external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(realtime_dt)'
	language c
	;


	create function if not exists realtime_dt() returns datetime year to fraction(5) 
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(realtime_dt)'
		language c
		;

	create function if not exists utc_realtime_dt() returns datetime year to fraction(5) 
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(utc_realtime_dt)'
		language c
		;


	-- Exact unix utc time, as seconds.
	create function if not exists clocktick() returns bigint
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(clocktick)'
		language c
		;

	-- Exact unix utc time, as seconds.fraction - nanosec resolution
	create function if not exists clocktick_s() returns decimal(32,9)
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(clocktick_s)'
		language c
		;

	-- Exact unix utc time in nanoseconds, whole number	
	create function if not exists clocktick_ns() returns decimal(32,0)
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(clocktick_ns)'
		language c
		;
	-- Exact unix utc time in microseconds, whole number
	create function if not exists clocktick_us() returns decimal(32,0)
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(dec_clocktick_us)'
		language c
		;

	-- Exact unix utc time in microseconds, whole number
	create function if not exists clocktick_us() returns bigint
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(int_clocktick_us)'
		language c
		;
	-- Exact unix utc time in milliseconds, whole number
	create function if not exists clocktick_ms() returns bigint
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(clocktick_ms)'
		language c
		;
