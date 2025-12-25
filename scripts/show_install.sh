#!/bin/bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

T=$'\t'; 
dbaccess tjb 2>/dev/null <<-EOF

	unload to '${TMPFILE}' delimiter '$T' 
	
	select 
		decode( isproc, 't', 'procedure ', 'function  ')
		||trim(procname)
		||'('
		||trim(paramtypes::lvarchar(250))
		||');'   
	from 
		sysprocedures 
	where 
		externalname like '%udr-pak%'
	order by isproc,procname

EOF


if [ -s $TMPFILE ]; then

	tput -x clear  # note, -x means do not clear scrollback history!
	echo
	echo "Installed Routines:"
	echo

	sed -r 's/^/\t/g' <	$TMPFILE | awk '
		{ 	
			type=$1 
			rtn=$2 
		}
	type != prevtype {
		printf( "\n%-12s %-12s",type, rtn );
	
	}
	type == prevtype && substr( rtn,0,4 ) == substr( prevrtn,0,4 ) {
		printf("\t%12s",rtn)
	}
	type == prevtype && substr( rtn,0,4 ) != substr( prevrtn,0,4 ) {
		printf( "\n%-12s %-12s",type, rtn );

	}

	{
		prevtype = type;
		prevrtn  = rtn;
		mext;
	}
	END { 
		printf("\n")
	}
	' 

fi
