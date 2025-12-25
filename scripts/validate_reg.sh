#!/usr/bin/env bash
set -euo pipefail

# Validate that symbols referenced in sql/udr-pak_REG.sql exist in the built shared object
# Usage: scripts/validate_reg.sh [so-path] [reg-sql]

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SO="${1:-$REPO_ROOT/build/lib/udr-pak.so}"
REGSQL="${2:-$REPO_ROOT/src/sql/udr-pak_REG.sql}"


SQLSYM=/tmp/sql_sym.$$
UDRSYM=/tmp/udr_sym.$$


pass1 ()
{
  # mash our sql into single lines per statement
    awk '
    
    tolower($1) ~ /^(create|insert|update|drop|delete)$/,/;/ 
     {
      
      gsub( /[[:blank:]]+/, " "); 
      printf("%s ",tolower($0)); 
      
      if( $0 ~ /;/ ){ printf("\n") }
      
    } ' < $1
}

pass2 () 
{
  # extract and print either the symbols listed in the external or specific name clauses
  # or failing that just the names of the stored procs themselves
  awk '
  {
    f1=""
    f2=""
    f3=""
  }

  !( $0 ~ /language *c/ ){
    next
  }

  match($0,/create.*(function|procedure)([^\(]+)/,a1) {
   
    #gensub(r, s, h [, t]) 
    f1 = gensub( /(.*) ([^ ]+)$$/, "\\2", "G", a1[2] )
   
  } 
  
  match($0, /external name(.*\/)(.*)\((.*)\)/,a2) {
    f2=a2[3]
  }
  match($0, /specific name(.*\/)(.*)\((.*)\)/,a3) {
    f3=a3[3]
  }
  
  {
    if(f3 != "") {
      print f3
    }  else if(f2 != "") {
      print f2
    }  else if(f1 != "") {
      print tolower(f1)
    }
  }
  '
}

get_symbols() {
  pass1 "$1" | pass2 | sort | uniq
}

if [ ! -f "$SO" ]; then
  echo "ERROR: shared object not found: $SO"
  exit 2
fi

if [ ! -f "$REGSQL" ]; then
  echo "ERROR: reg sql not found: $REGSQL"
  exit 2
fi

echo "Extracting defined symbols from $SO..."
if command -v nm >/dev/null 2>&1; then

  nm -D --defined-only "$SO" 2>/dev/null | awk '{print $3}' | sort -u > $UDRSYM

else

  readelf -Ws "$SO" 2>/dev/null | awk '/FUNC|OBJECT/ {print $8}' | sort -u > $UDRSYM

fi

echo "Parsing registered symbols from $REGSQL..."
get_symbols "$REGSQL" >$SQLSYM || true

echo "Checking registered symbols..."
MISSING=0

while read -r sym; do

  [ -z "$sym" ] && continue


  if ! grep -qx "^${sym}$" $UDRSYM; then
    echo "  MISSING: $sym"
    MISSING=1
  else
    echo "  OK: $sym"
  fi
done < $SQLSYM

if [ "$MISSING" -ne 0 ]; then
  echo "One or more registered symbols are missing in $SO" >&2
  exit 3
fi

echo "All registered symbols found in $SO."
exit 0
