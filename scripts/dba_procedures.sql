
/* view for sysprocedures which trims unprintable charaters from the procnames */

drop view if exists dba_procedures;

create view dba_procedures (
	procname
	,owner
	,procid
	,mode
	,retsize
	,symsize
	,datasize
	,codesize
	,numargs
	,isproc
	,specificname
	,externalname
	,paramstyle
	,langid
	,paramtypes
	,variant
	,client
	,handlesnulls
	,iterator
	,percallcost
	,commutator
	,negator
	,selfunc
	,internal
	,class
	,stack
	,parallelizable
	,costfunc
	,selconst
	,collation
	,procflags
) 
as

select

	regex_replace( procname , '[^-_.a-zA-Z0-9]' ,'')
		--'[^[:print:]]'.'',2)
	,owner
	,procid
	,mode
	,retsize
	,symsize
	,datasize
	,codesize
	,numargs
	,isproc
	,specificname
	,externalname
	,paramstyle
	,langid
	,paramtypes
	,variant
	,client
	,handlesnulls
	,iterator
	,percallcost
	,commutator
	,negator
	,selfunc
	,internal
	,class
	,stack
	,parallelizable
	,costfunc
	,selconst
	,collation
	,procflags
from sysprocedures;
