select
	prng()				as prng,
	prng2()				as prng2,
	uuidv7()			as uuidv7,
	realtime_dt()		as realtime,
	utc_realtime_dt()	as utc_realtime,
	sysdate				as sysdate,
	s1					as seq_plus,
	s2					as seq_minus,
	s3					as seq10
from
	table( seq(1,1,3) ) as seq1(s1)
cross join
	table( seq(0,-1,-3) ) as seq2(s2)
cross join
	table( seq(0,10,30) ) as seq3(s3);
