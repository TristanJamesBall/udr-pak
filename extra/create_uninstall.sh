#!/bin/bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

T=$'\t'; 
dbaccess tjb 2>/dev/null <<-EOF

	unload to '${TMPFILE}' delimiter '$T' 
	
	select 
		'drop '
		|| decode( isproc, 't', 'procedure ', 'function ')
		||trim(procname)
		||'('
		||trim(paramtypes::lvarchar(250))
		||');'   
	from 
		sysprocedures 
	where 
		externalname like '%udr-pak%'
EOF

cat $TMPFILE
