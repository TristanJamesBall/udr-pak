#!/home/tristanb/ShellEnv/pkg/ksh.1.1.0-alpha_6f46232_2025-07-05/bin/ksh

# int, long, unsigned
alias uint64='typeset -i -l -u '

uint64 x sm_inc smm1 smm2

(( sm_inc = 0x9e3779b97f4a7c15 ))
(( smm1   = 0xbf58476d1ce4e5b9 ))
(( smm2   = 0x94d049bb133111eb ))

splitmix64() {
	i=0
    uint64 z 
	(( x += sm_inc )) 
	(( z = x ))
	(( z = (z ^ ( ( z^(1<<63) ) >> 30) ) * smm1 ))
	(( z = (z ^ ( ( z^(1<<63) ) >> 27) ) * smm2 ))
	echo $(( z ^ ( (z^(1<<63) ) >> 31) ))
}

(( x = 1234567 ))

splitmix64
printf "Start: %lx   (%lu)\n" x x
splitmix64
printf "Start: %lx   (%lu)\n" x x
splitmix64
printf "Start: %lx   (%lu)\n" x x
