
!echo "Writing to demo.all.csv"
unload to 'demo.all.csv' delimiter ','
select
prng() as prng,
uuidv7() as uuidv7,
realtime_dt() as realtime,
utc_realtime_dt() as utc_realtime,
sysdate as sysdate,
*
from
	table( seq(1,1,50) ) as seq1(s1)
cross join
	table( seq(0,-1,-50) ) as seq2(s2)
cross join
	table( seq(0,10,500) ) as seq3(s3);
