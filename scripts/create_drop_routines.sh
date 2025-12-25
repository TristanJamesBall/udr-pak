#!/bin/bash


case "$1" in
	"" | --help | -h )
		printf "\n"
		printf " Create 'Drop Routine' statements for a given Informix Extension shared library\n"
		printf " so that library can be unloaded from the running instance\n\n"
		printf "     create_drop_routines.sh [name]\n\n"
		printf " [name] can match either the shared library, sans .so or bld extension,\n"
		printf " or it can match the name of a folder under \${INFORMIXDIR}/extend/\n"
	    printf "\n"
		printf " Outputs SQL to drop stored procedures and functions\n\n"
		printf " Does not clean up types or anything else, only those things\n"
	    printf " dependent on the extension\n"
		exit
		;;
esac
DBNAME=$1
shift
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

T=$'\t'; 
dbaccess ${DBNAME:?} 2>/dev/null <<-EOF

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
		externalname like '%extend/${1}/%'
		or externalname like '%/${1}.so'
		or externalname like '%/${1}.bld'
EOF

cat $TMPFILE
