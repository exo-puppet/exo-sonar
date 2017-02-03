#!/bin/bash -eu
##################
# File managed by puppet, don't edit
##################

SCRIPT_DIR=$(dirname $0)
source ${SCRIPT_DIR}/_setenv.sh

DATE=$(date +%Y%m%d-%H%M%S)

DB_BACKUP_NAME=sonar_db_${DATE}.sql.bz2
EXT_BACKUP_NAME=sonar_extensions_${DATE}.tar.bz2

echo Backuping mysql...
docker run --rm --network sonar_database --link sonar_mysql_1:db -v ${BACKUP_DIRECTORY}:/backups mysql:5.7 mysqldump -u"${BACKUP_DB_USER}" -h db -p"${BACKUP_DB_PASSWORD}" sonar | pbzip2 > ${BACKUP_DIRECTORY}/${DB_BACKUP_NAME}

chown sonar:sonar ${BACKUP_DIRECTORY}/*

echo Backuping plugins...
tar --directory ${DATA_DIR} --use-compress-program pbzip2 -cvf ${BACKUP_DIRECTORY}/${EXT_BACKUP_NAME} extensions

echo Cleaning old backups...
find ${BACKUP_DIRECTORY} -mtime +${BACKUP_HISTORY} -exec rm -v {} \;
