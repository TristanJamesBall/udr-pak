
unload to './.timing.fifo.1840362'
select 
limit 5000000
clocktick_us() as microseconds
from	
table(seq(1,1,22))
cross join table(seq(1,1,22))
cross join table(seq(1,1,22))
cross join table(seq(1,1,22))
cross join table(seq(1,1,22))
;
