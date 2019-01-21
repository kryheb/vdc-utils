#!/bin/bash

HOST=$1
VDC=$2

RED='\033[0;31m'
NC='\033[0m'

function log_err {
	>&2 echo -e "${RED}${@}"
}

# params: result | cmd params
function check_result {
	if [ $? -ne 0 ]; then
		log_err "Command '$@' has failed"
		exit 1
	fi
}

if [ -z "$HOST" ] || [ -z "$VDC" ]; then
	log_err "ERROR: Incorrect params, pass <HOST-NAME> <VDC-NAME>"
	log_err "note: vdc name without vdc prefix"
	exit 1
fi


# params: host | sv-cmd | sv-name
function service_cmd {
	ssh root@${HOST} "/usr/sbin/sv $1 $2"
	check_result "service_cmd($@)"
}

# params: binary-name source | binary-name target 
function upload {
	scp $1 root@${HOST}:/usr/bin/$2
	check_result "upload ($@)"
}

service_cmd stop vdc-${VDC}
upload ${VDC}vdc vdc-${VDC}
service_cmd start vdc-${VDC}


