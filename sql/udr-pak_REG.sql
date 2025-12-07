CREATE PROCEDURE IF NOT EXISTS udr_trace_configure( 
	level integer default 1, 
	class lvarchar(14) default 'udrpak',
	path  lvarchar(255) default '/var/tmp/udrpak.trace.log'
) 
WITH ( HANDLESNULLS)
EXTERNAL NAME '$INFORMIXDIR/extend/udr-pak/udr-pak.so()'
LANGUAGE C;


CREATE PROCEDURE IF NOT EXISTS udr_trace_set( lvl smallint ) 
EXTERNAL NAME '$INFORMIXDIR/extend/udr-pak/udr-pak.so()'
LANGUAGE C;

CREATE PROCEDURE IF NOT EXISTS udr_trace_on( ) 
EXTERNAL NAME '$INFORMIXDIR/extend/udr-pak/udr-pak.so()'
LANGUAGE C;



CREATE PROCEDURE IF NOT EXISTS udr_trace_off()
EXTERNAL NAME '$INFORMIXDIR/extend/udr-pak/udr-pak.so()'
LANGUAGE C;

CREATE PROCEDURE IF NOT EXISTS udr_trace_test()
EXTERNAL NAME '$INFORMIXDIR/extend/udr-pak/udr-pak.so()'
LANGUAGE C;



{ Not allowed to merge into systraceclasses!! }

insert into systraceclasses(name)
select name from table(list{'udrpak','udrpak_mem'}) as ins(name)
where not exists ( select 1 from systraceclasses where name = ins.name) ;


-- execute procedure udr_trace_set();
-- execute procedure udr_trace_test();
--execute procedure udr_trace_off();


CREATE FUNCTION IF NOT EXISTS udr_fn(trc lvarchar(24)) returning int
WITH (VARIANT)
EXTERNAL NAME '$INFORMIXDIR/extend/udr-pak/udr-pak.so(udr_fn)'
LANGUAGE C;


create function if not exists seq(int,int,int) returns int
    with(ITERATOR,VARIANT,HANDLESNULLS, PARALLELIZABLE)
	external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(seq_int)'
	language c;

create function if not exists prng() returns bigint
	with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
	external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(xoshiro256_star_star)'
	language c
	;

create function if not exists prng2() returns bigint
	with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
	external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(prng2)'
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

	create function if not exists proctime_dt() returns datetime year to fraction(5) 
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(proctime_dt)'
		language c
		;




	create function if not exists monotime_dt() returns datetime year to fraction(5) 
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(monotime_dt)'
		language c
		;
	create function if not exists threadtime_dt() returns datetime year to fraction(5) 
		with(VARIANT,HANDLESNULLS, PARALLELIZABLE)
		external name '$INFORMIXDIR/extend/udr-pak/udr-pak.so(threadtime_dt)'
		language c
		;
