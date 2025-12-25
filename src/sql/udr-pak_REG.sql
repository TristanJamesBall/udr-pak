

create opaque type if not exists any_int (internallength = 12, alignment = 8);
GRANT USAGE ON TYPE any_int TO public;


create implicit cast if not exists (lvarchar as any_int with any_int_input);
create implicit cast if not exists (any_int as lvarchar with any_int_output);

create implicit cast if not exists (smallint as any_int with smallint_to_any);
create implicit cast if not exists (integer as any_int with integer_to_any);
create implicit cast if not exists (bigint as any_int with bigint_to_any);
create implicit cast if not exists (boolean as any_int with boolean_to_any);

create implicit cast if not exists (any_int as smallint with any_to_smallint);
create implicit cast if not exists (any_int as integer with any_to_integer);
create implicit cast if not exists (any_int as bigint with any_to_bigint);
create implicit cast if not exists (any_int as boolean with any_to_boolean);


create function if not exists any_int_output(any_int) returns lvarchar(128) with(PARALLELIZABLE,NOT VARIANT) external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' language c;
create function if not exists any_int_input(lvarchar(128)) returns any_int with(PARALLELIZABLE,NOT VARIANT) external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' language c;


create function if not exists smallint_to_any(smallint) returns any_int with(PARALLELIZABLE,NOT VARIANT) external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' language c;
create function if not exists integer_to_any(integer) returns any_int with(PARALLELIZABLE,NOT VARIANT) external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' language c;
create function if not exists bigint_to_any(bigint) returns any_int with(PARALLELIZABLE,NOT VARIANT) external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' language c;
create function if not exists boolean_to_any(boolean) returns any_int with(PARALLELIZABLE,NOT VARIANT) external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' language c;

create function if not exists any_to_smallint(any_int) returns smallint with(PARALLELIZABLE,NOT VARIANT) external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' language c;
create function if not exists any_to_integer(any_int) returns integer with(PARALLELIZABLE,NOT VARIANT) external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' language c;
create function if not exists any_to_bigint(any_int) returns bigint with(PARALLELIZABLE,NOT VARIANT) external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' language c;
create function if not exists any_to_boolean(any_int) returns boolean with(PARALLELIZABLE,NOT VARIANT) external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so()' language c;


create function if not exists to_hex(any_int) returns lvarchar(36) with(HANDLESNULLS,PARALLELIZABLE,NOT VARIANT) external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(any_to_hex)' language c;
create function if not exists to_hex4(any_int) returns lvarchar(36) with(HANDLESNULLS,PARALLELIZABLE,NOT VARIANT) external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(any_to_hex4)' language c;


create function if not exists seq(
	p1 int default null,
	p2 int default null, 
	p3 int default null
) 
returns int as seq
with(ITERATOR,HANDLESNULLS,PARALLELIZABLE,PERCALL_COST=5)
external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(seq_int)'
language c;


create function if not exists __slow_seq(
	p1 int default null,
	p2 int default null, 
	p3 int default null
) 
returns int as seq
with(ITERATOR,HANDLESNULLS,PARALLELIZABLE,PERCALL_COST=5)
external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(slow_seq_int)'
language c;

create function if not exists prng() returns bigint
	with(VARIANT,HANDLESNULLS, PARALLELIZABLE,PERCALL_COST=5)
	external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(xoshiro256_star_star)'
	language c
	;


create function if not exists uuidv7() returns lvarchar(36)
	with(VARIANT,HANDLESNULLS, PARALLELIZABLE,PERCALL_COST=5)
	external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(uuidv7)'
	language c
	;

create function if not exists uuidv4() returns lvarchar(36)
	with(VARIANT,HANDLESNULLS, PARALLELIZABLE,PERCALL_COST=5)
	external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(uuidv4)'
	language c
	;



create procedure if not exists yield_ms(smallint)
	external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(yield_ms_proc)'
	language c;

create function if not exists yield_ms(smallint) returns smallint
	with (VARIANT)
	external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(yield_ms)'
	language c;


/* "default" version */
create function if not exists realtime() returns datetime year to fraction(5) 
	with(VARIANT,HANDLESNULLS, PARALLELIZABLE,PERCALL_COST=5)
	external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(realtime_dt)'
	language c
	;


	create function if not exists realtime_dt() returns datetime year to fraction(5) 
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE,PERCALL_COST=5)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(realtime_dt)'
		language c
		;

	create function if not exists utc_realtime_dt() returns datetime year to fraction(5) 
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE,PERCALL_COST=5)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(utc_realtime_dt)'
		language c
		;


	-- Exact unix utc time, as seconds.
	create function if not exists clocktick() returns bigint
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE,PERCALL_COST=5)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(clocktick)'
		language c
		;

	-- Exact unix utc time, as seconds.fraction - nanosec resolution
	create function if not exists clocktick_s() returns decimal(32,9)
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE,PERCALL_COST=5)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(clocktick_s)'
		language c
		;

	-- Exact unix utc time in nanoseconds, whole number	
	create function if not exists clocktick_ns() returns decimal(32,0)
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE,PERCALL_COST=5)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(clocktick_ns)'
		language c
		;
	-- Exact unix utc time in microseconds, whole number
	create function if not exists clocktick_us() returns decimal(32,0)
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE,PERCALL_COST=5)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(dec_clocktick_us)'
		language c
		;

	-- Exact unix utc time in microseconds, whole number
	create function if not exists clocktick_us() returns bigint
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE,PERCALL_COST=5)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(int_clocktick_us)'
		language c
		;
	-- Exact unix utc time in milliseconds, whole number
	create function if not exists clocktick_ms() returns bigint
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE,PERCALL_COST=5)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(clocktick_ms)'
		language c
		;
