#!/bin/bash -eu
##################
# File managed by puppet, don't edit
##################

SCRIPT_DIR=$(dirname $0)
source ${SCRIPT_DIR}/_setenv.sh

cd ${INSTALL_DIR}
/usr/local/bin/docker-compose up -d