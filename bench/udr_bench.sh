#!/bin/bash

export TIMEFORMAT="Elapsed: %3R"
DBNAME=${DBNAME:-${DB:-tjb}}
FIFO="./.timing.fifo.$$"
TAB=$'\t'
OFS="$IFS"
DL=$'\034'
trap 'r=$?; rm -f $FIFO; pkill -s 0 -f pv; trap - EXIT HUP INT QUIT; exit $r' EXIT HUP INT QUIT
export DBACCESS_COLUMNS=${COLUMNS:-100}
typeset -i OUTC=$DBACCESS_COLUMNS
typeset -A meta




main() {

	meta=( [h1]="" [h2]="Java UUIDv4 (IBM packeged java.util.uuuid)" [short_name]="uuid()" )
	projection_clauses=( "uuid() as prng" )
	bench_runner 10000000 5
exit

	meta=( [h1]="" [h2]="Realtime timestamps, Year to fraction(5) format, local timezone" [short_name]="realtime_dt()" )
	projection_clauses=( "realtime_dt() as realtime" )
	bench_runner 1000000 5


	meta=( [h1]="" [h2]="PRNG with Txn Level Auto Re-Seed" [short_name]="prng()" )
	projection_clauses=( "prng() as prng" )
	bench_runner 1000000 5


	meta=( [h1]="" [h2]="UUIDv4 with Random" [short_name]="uuid4()" )
	projection_clauses=( "uuidv4() as prng" )
	bench_runner 1000000 5
	
	
	meta=( [h1]="" [h2]="UUIDv7 with Millisec timestamp and PRNG above" [short_name]="uuid7()" )
	projection_clauses=( "uuidv7() as prng" )
	bench_runner 1000000 5
	

	meta=( [h1]="" [h2]="Realtime timestamps, Year to fraction(5) format, local timezone" [short_name]="realtime_dt()" )
	projection_clauses=( "realtime_dt() as realtime" )
	bench_runner 1000000 5

	meta=( [h1]="" [h2]="Realtime timestamps, Unix time as a Decimal(32,9), nanosecond resolution" [short_name]="clocktick_s()" )
	projection_clauses=( "clocktick_s() as seconds" )
	bench_runner 1000000 5

	
	meta=( [h1]="" [h2]="Realtime timestamps, Unix time as a Decimal(32) nanosecond resolution" [short_name]="clocktick_ns()" )
	projection_clauses=( "clocktick_ns() as nanoseconds" )
	bench_runner 1000000 5

	meta=( [h1]="" [h2]="Realtime timestamps, Unix time as a Bigint microsecond resolution" [short_name]="clocktick_us()" )
	projection_clauses=( "clocktick_us() as microseconds" )
	bench_runner 1000000 5
}





# Setup PV if we can

if which pv >/dev/null 2>&1 ; then
    pv() {
        label="${1:-Running}"
        command pv --discard --line-mode --format "${label}:- Avg_Lines/Sec: %r  Total_Lines: %b  Elapsed: %t"
    }
else
    pv() {
        wc -l
    }
fi
#############################################################
#
# bench_runner [tgt_line_count] [xjoin count]
#
#  Splitting the sequence generation via the cross-join means informix is only ever
#  fetching the size of the final join at any given time - so we get smoother results
#  that are quiker to start returning values
#
#  On the other hand, that's not very realistic in any number of cases, so 
#  you you can go all the qay to 0 on xjoin and get all results from a single
#  from table(seq(1,1,$target_cunt))
#
#  On the gripping hand.. selecting from an iterator like this is very much an edge case too
#  so, I'm using higher numbers of joins for quiker iterations on testing
#
# ##########################################################
bench_runner() {
	
	tgt_line_count="${1:-"500000"}"
	xjoins=${2:-"6"}


	#h1_text="${meta['h1']}"
	h2_text="${meta['h2']}"
	short_name="${meta['short_name']}"


	if (( xjoins > 0 )); then
		
		if (( xjoins > 10 )); then
			xjoins=10
		fi
		seq_lines=$( perl -e "use POSIX; print POSIX::ceil( ( ${tgt_line_count}.0 ** (  1.0/(${xjoins})) ) );" )
	else
		seq_lines=${tgt_line_count}
	fi

	rm -f $FIFO
	mkfifo $FIFO

	if [[ -n "${h2_text+h2_set}" ]]; then

		h2_line "$h2_text"
	
	fi

	proj_clause() {
		sep=""; 
		for prj in "${projection_clauses[@]}" ; do 
			printf "%s%s\n" "$sep" "$prj"; 
			sep=","
		done 
	}

	label="$( printf "%-35.35s" "${short_name} rate ${res_pad_str}" )"
	pv "$label" < $FIFO  &
	pv_pid=$?

	#dbaccess $DBNAME 2>/dev/null  <<-EOF

	
	label="$( printf "%-35.35s" "${short_name} example ${res_pad_str}" )"

	run_example() {
		# this stdout trick is brittle, it doesn't work under ksh, and it might not work
		# if you're not the owner pf your PTY (eg, because of su/sudo )
		#dbaccess $DBNAME 2>/dev/null <<< "unload to '/dev/stdout' delimiter '$DL' select $( proj_clause ) from sysmaster:sysdual;" 
		dbaccess $DBNAME  <<< "unload to '/dev/stdout' delimiter '$DL' select $( proj_clause ) from sysmaster:sysdual;" 
	}

	IFS="$DL" 
	printf "$label:- %s\n" $( run_example ) 
	IFS="$OFS"

	{ tee ./prng_bench_run.sql | dbaccess $DBNAME 2>/dev/null ;} <<-EOF

		unload to '$FIFO'
		select 
			limit ${tgt_line_count:-100000}
			$( 
				sep=""; 
				for prj in "${projection_clauses[@]}" ; do 
					printf "%s%s\n" "$sep" "$prj"; 
					sep=","
				done 
			)
		from	
						table(seq(1,1,${seq_lines}))
			$( 
				# carefull here, this is x=1 and '<' not '<='
				# delberately so we don't get waaaaay to many xjones
				# 1 to many is waaaaay
				for (( x=1; x < xjoins; x++ )); do 
					printf "cross join table(seq(1,1,%d))\n" "$seq_lines"; 
				done 
			)
		;
EOF
	(( $? != 0 )) && exit
}




#########################################3
## 
## Header lines output malarky
##

typeset h1_pad_str="$(  for((_i=0; _i < OUTC; _i++)); do printf '=';done )"
typeset h2_pad_str="$(  for((_i=0; _i < OUTC; _i++)); do printf '-';done )"
typeset res_pad_str="$( for((_i=0; _i < OUTC; _i++)); do printf '.';done )"
typeset h_mgn_str="$( for((_i=0; _i < OUTC; _i++)); do printf ' ';done )"

set -u
ljs() { printf '%%-%d.%ds' $1 $1 ;}
rjs() { printf '%%%d.%ds' $1 $1 ;}

function h1_line {
	h_pad_str="${h1_pad_str}"
	h_mgn=$(( OUTC/16 ))
	h_tail="\\n"
	h_line "$@"
}

function h2_line {
	h_pad_str="${h2_pad_str}"
	h_mgn=$(( OUTC/8 ))
	h_tail="\\n"
	h_line "$@"
}

function h_line {

	typeset h_str="$*"
	typeset h_len=$(( ${#h_str} ))
	# -4 is for spaces around the title string
	typeset h_lpad=$(( (OUTC - h_len - h_mgn*2 -4 )/2  ))
	typeset h_rpad=$(( (OUTC - h_len - h_mgn*2 -4 )/2  ))
	

	typeset h_fmt=""
	h_fmt+="$( ljs $h_mgn )"
	h_fmt+="$( ljs $h_lpad )"

	h_fmt+="$( ljs $(( $h_len+4)) )"

	h_fmt+="$( rjs $h_rpad )"
	h_fmt+="$( rjs $h_mgn   )"
	
	h_fmt+="${h_tail}"
	h_fmt+="\\n"
	printf "${h_fmt}" \
		"${h_mgn_str}" \
		"${h_pad_str}" \
		"  ${h_str}  " \
		"${h_pad_str}" \
		"${h_mgn_str}"
}


main "$@"
