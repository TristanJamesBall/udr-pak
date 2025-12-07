#!/bin/ksh

## looks for a tty attached session for the current user
## assumes only one,probably on a quite box - 

## Not a serious approach on anything other than a dev box
getSid() {
	SID=$( onstat -g ses -r 1 | awk '$2 == ENVIRON["LOGNAME"] && $3 ~ /^[0-9]+$/ {print $1;exit}' );
}
getSid2() {
	SID=$( timeout 1 onstat -g ses -r 1 | awk '$2 == ENVIRON["LOGNAME"] && $3 ~ /^[0-9]+$/ {print $1;exit}' );
}

getSid
while [[ -n "$SID" ]]; do

	{
		echo "g ses $SID"
		echo "g mem $SID"
	}  | onstat -i  |grep -E -v '^$'
	/bin/sleep 0.9
	getSid2
done
