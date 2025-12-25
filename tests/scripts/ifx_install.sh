#!/bin/bash

TEST_USER=$(whoami)
PKG=${1:?}
DIR=$(realpath "$(dirname "$0")" )
DIR=$(realpath "${DIR}/.." )
export TEST_USER
cd "$DIR" || exit
source "${DIR}/scripts/integ.env" || exit
onclean -yk >/dev/null 2>&1 || true
sudo rm -rf server
sudo tar -xapf "${PKG}"

sudo -u informix DIR=${DIR} TEST_USER=${TEST_USER} /bin/bash <<"EOF"
set -e
declare -A dbs=( \
	[plogdbs]="40" 
	[llogdbs]="460" 
	[datadbs]="230" 
	[rootdbs]="590" 
	[tempdbs]="60" 
	[sbspace]="40" 
)
mkdir -p server/storage
rm -f server/storage/*
chmod 755 server/storage

for D in "${!dbs[@]}"; do
	S=${dbs["$D"]}
	BYTES=$(( S *1024*1024 ))
	touch server/storage/$D
	fallocate -z -o 0 -l $BYTES server/storage/$D
	chmod 660 server/storage/$D
done

source ${DIR}/scripts/integ.env

cp -f ${DIR}/pkg/onconfig.ifx_ci  server/etc/
cp -f ${DIR}/pkg/sqlhosts.ifx_ci  server/etc/
cp -f ${DIR}/scripts/integ.env server/

chmod 440 server/etc/onconfig.ifx_ci server/etc/sqlhosts.ifx_ci
echo "Starting informix, please wait..." >&2
  oninit -iyw 2>&1 | { grep -v '^Warning' || true ;}
 sleep 5
 timeout 5 dbaccess sysmaster <<< "create database ci_test with log"
 timeout 5 dbaccess -e ci_test <<< "grant resource to '${TEST_USER}';"
 timeout 5 dbaccess ci_test ${DIR}/scripts/java_uuid_reg.sql
EOF
