
-- ----------------------------------------------------------------------------------------------
--
--   dbaccess [database] tests/demo_all.sql | ./scripts/pv_sample.sh
--
-- It'll give you the first 5 and last 5 lines, as welll as a lines/sec rate for the rest
-- FWIW, right now I'm getting about 110k/s on my laptop
--
-- ----------------------------------------------------------------------------------------------


-- execute procedure set_explain('on','demo_all.');

-- the ^^ delimilter below is really \x1e ( or \036 octal   
-- to enter that in vim from insert mode, hit ctrl-q, then type "x" "1" "e"
-- To use it as a shell delimiter: IFS=$'\x1e'
--   in awk -F$'\x1e'
--   in pspg --csv-separator $'\x1e'
--   in sqlcmd -D $'\x1e'
--   ... because yes it's differeent option for every single command...
--   or as a default in dbaccess
--      export DBELIMITER=$'\x1e'



--unload to 'demo.all.csv' delimiter ','
--unload to '/dev/null' delimiter ','


unload to /dev/stdout delimiter ''
select
	prng() as prng,
	to_hex(prng()) as to_hex,
	uuidv7() as uuidv7,
	realtime_dt() as realtime,
	utc_realtime_dt() as utc_realtime,	
	clocktick() as clocktick_ns,
	clocktick_s() as clocktick_ns,
	clocktick_us()::bigint as clocktick_us,
	sysdate as sysdate,
	s1,
	s2,
	s3,
	s4
from
	{ 1 to 30, step 1 }
	table( seq(1,1,30) ) as seq1(s1)
cross join
	{ 0 to -50, step -1 }
	table( seq(-50) ) as seq2(s2)
cross join
	{ 25 to -25, step -1 }
	table( seq(25,-25) ) as seq3(s3)
cross join
	{ 0 to 400, step 10 }
	table( seq(0,10,400) ) as seq4(s4);
