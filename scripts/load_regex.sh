#!/bin/bash


{
	cd $INFORMIXDIR/extend

	cat ifxmngr/sysbldinit.sql
	cat ifxregex.1.10/prepare.sql 
	cat ifxregex.1.10/objects.sql 

} |	dbaccess ${1:-${DBNAME:?}}
