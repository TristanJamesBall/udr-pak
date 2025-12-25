#!/bin/bash

## ... after realisng all my tests were invalid. again, because I'd broken something such
## that I still got data, but not the right data, presenting....

############################################################################################
##
##  pv_sample
## 
## Show the first (n) and last (n) lines of a stream, but otherwise run like 
## we were doing  "pv >/dev/null"
##
## NOTE: If you've been benchmarking with 'pv >/dev/null' or 'pv --discard', this will be
## a little slower, because we still write the data to tail, which has to scan and 
## discard most of..
## 

SAMPLE_LINES=5

rs_delim_table() {
	pspg --csv --csv-separator $'\x1e' | grep -Ev '^\([0-9]+ rows\)'
}

# unset these to to just get the raw lines
head_filter=rs_delim_table
tail_filter=rs_delim_table


command pv -W --line-mode --format "Avg_Lines/Sec: %r  Total_Lines: %b  Elapsed: %t" | (

	{
		printf "\nFirst ${SAMPLE_LINES}...\n\n" 
		
		if [[ -n "${head_filter+x}" ]]; 
		then	head -n ${SAMPLE_LINES} | $head_filter
		else	head -n ${SAMPLE_LINES} 
		fi

		printf "\b..\n\n" 
	}>&2



	tail -n ${SAMPLE_LINES} | (
			printf "\n\nLast ${SAMPLE_LINES}...\n\n" 

			if [[ -n "${tail_filter+x}" ]]; 
			then	$tail_filter
			else	cat -
			fi

			printf "\nDone\n"
		)	>&2
	)
