#!/bin/sh

export INFORMIXSDK=$(realpath ../informix-sdk)
export INFORMIXDIR=$(realpath ../informix-server)
gcc -I$INFORMIXSDK/incl -c ${1%.c}.c 
{
gcc -o ${1%.c}  ${1%.c}.o ../build/client_obj/*.o \
 -L$INFORMIXSDK/lib/esql -L$INFORMIXSDK/lib/dmi -L$INFORMIXSDK/lib \
 -lifdmi -lifsql -lifasf -lifcss -lifos -lifgen  -lifgls -lm \
   -lcrypt ${INFORMIXSDK}/lib/esql/checkapi.o 
} 2>&1 | head -10
