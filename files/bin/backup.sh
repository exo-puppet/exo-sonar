#!/bin/bash -eu
##################
# File managed by puppet, don't edit
##################

SCRIPT_DIR=$(dirname $0)
source ${SCRIPT_DIR}/_setenv.sh

DATE=$(date +%Y%m%d-%H%M%S)

DB_BACKUP_NAME=sonar_db_${DATE}.sql.bz2
EXT_BACKUP_NAME=sonar_extensions_${DATE}.tar.bz2

docker pull exoplatform/mysql-backup:latest


echo Backuping mysql...
docker run --rm -e DATABASE=sonar -e USER=${BACKUP_DB_USER} -e PASSWORD=${BACKUP_DB_PASSWORD} --network sonar_database -e FULLNAME=${DB_BACKUP_NAME} --link sonar_mysql_1:db -v ${BACKUP_DIRECTORY}:/backups exoplatform/mysql-backup

chown sonar:sonar ${BACKUP_DIRECTORY}/*

echo Backuping plugins...
tar --directory ${DATA_DIR} --use-compress-program pbzip2 -cvf ${BACKUP_DIRECTORY}/${EXT_BACKUP_NAME} extensions

echo Cleaning old backups...
find ${BACKUP_DIRECTORY} -mtime +${BACKUP_HISTORY} -exec rm -v {} \;
