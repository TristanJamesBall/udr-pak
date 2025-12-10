#!/bin/bash
SELF=$( basename "$0" )
TEST=${SELF%.sh}
HOST=$(uname -n)
DB=tjb
set -e
SCRIPT=../sql/demo_all.sql
WORKERS=5
NOW=$(date '+%Y-%m-%d__%H-%M-%S')
RESULTS="./${TEST}/${NOW}"
mkdir -p "$RESULTS"

cp $SCRIPT $RESULTS/
cd $RESULTS

SCRIPT=$(basename "$SCRIPT" )
	
function ts {
	while IFS= read -t90 -r l; do 
		printf "%(%F %T)T:: %s\n" -1 "$l"
	done
}

onstat -g ses -r 3 |grep --line-buffered "$HOST" | ts >onstat_g_ses.txt &
OS_PID1=$!
onstat -g seg -r 3 | ts >onstat_g_seg.txt &
OS_PID2=$!
trap 'kill -9 $OS_PID1 $OS_PID2' EXIT
export TIMEFORMAT="%3R Elapsed (%3U User + %3S System )"

(
	#export PDQPRIORITY=$(( 100 / WORKERS-1))


	while (( WORKERS-- )); do
		( time dbaccess -e $DB $SCRIPT ) > "${SCRIPT%.sql}.$WORKERS.result" 2>&1 &
	done
	wait
)
