#!/bin/bash -eu
##################
# File managed by puppet, don't edit
##################

SCRIPT_DIR=$(dirname $0)
source ${SCRIPT_DIR}/_setenv.sh

rsync -avP --delete ${BACKUP_DIRECTORY}/ ${BACKUP_REMOTE_USER}@${BACKUP_REMOTE_HOST}:${BACKUP_REMOTE_DIRECTORY}
