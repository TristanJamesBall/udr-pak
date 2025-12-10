
unload to './.timing.fifo.1406082'
select 
limit 15000000
prng() as prng
from	
table(seq(1,1,28))
cross join table(seq(1,1,28))
cross join table(seq(1,1,28))
cross join table(seq(1,1,28))
cross join table(seq(1,1,28))
;
