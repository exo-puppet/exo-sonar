#!/bin/bash -eu
##################
# File managed by puppet, don't edit
##################

SCRIPT_DIR=$(dirname $0)
source ${SCRIPT_DIR}/_setenv.sh

${SCRIPT_DIR}/stop.sh
${SCRIPT_DIR}/start.sh