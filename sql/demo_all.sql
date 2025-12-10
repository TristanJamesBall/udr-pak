
execute procedure set_explain('on','demo_all.');


-- unload to 'demo.all.csv' delimiter ','
unload to '/dev/null' delimiter ','
select
	prng() as prng,
	uuidv7() as uuidv7,
	realtime_dt() as realtime,
	utc_realtime_dt() as utc_realtime,
	clocktick_s() as clocktick_ns,
	clocktick_us()::bigint as clocktick_us,
	sysdate as sysdate,
	s1,
	s2,
	s3,
	s4
from
	{ 
		seq(a,b,c) generates inetegers from a to c
		if c < a, then count down.
		if b is given, use as step size 
		The  may be adjusted to -/- to ensure move in the right direction to go from a to c
		That's not very sqlish, but it suits my usecase of "just make numbers from here to here"
	}
	{ 1 to 50, step 1 }
	table( seq(1,1,50) ) as seq1(s1)
cross join
	{ 0 to -50, step -1 }
	table( seq(-50) ) as seq2(s2)
cross join
	{ 25 to -25, step -1 }
	table( seq(25,-25) ) as seq3(s3)
cross join
	{ 0 to 400, step 10 }
	table( seq(0,10,400) ) as seq4(s4);
