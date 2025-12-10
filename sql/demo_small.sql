select
	prng()				as prng,
	uuidv7()			as uuidv7,
	realtime_dt()		as realtime,
	clocktick_s()		as clocktick_s,
	sysdate				as sysdate,
	s1					as seq_plus,
	s2					as seq_minus,
	s3					as seq10
from
	table( seq(1,1,2) ) as seq1(s1)
cross join
	table( seq(-2) ) as seq2(s2)
cross join
	table( seq(0,10,30) ) as seq3(s3);
