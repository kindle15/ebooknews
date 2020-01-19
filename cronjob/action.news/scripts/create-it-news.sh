#!/bin/sh
#
# Create IT-News from calibre recipe by docker container service calibre
# and copy the epub file to the dropbox sync directory where the reader
# can download it from claud side
# This script will be used via cron job
#

################################################################################
DATE_NAME=`date '+[%a %d %b %Y]'`
BOOK_PRE_NAME="it-news"
BOOK_NAME=`echo "${BOOK_PRE_NAME} ${DATE_NAME}.epub"`
################################################################################
MAINTENACE_PATH="/volume1/maintenance"
INFO_FILE="${MAINTENACE_PATH}/logs/create-${BOOK_PRE_NAME}.info"
################################################################################
# Docker container
IN_RECIPE="./recipes/ITNews.recipe"
OUT_BOOK="./tmp/${BOOK_PRE_NAME}.epub"
################################################################################
# Host
OUT_TMP="${MAINTENACE_PATH}/docker/calibre/target/tmp/${BOOK_PRE_NAME}.epub"
OUT_PATH="/volume3/CloudDrives/dropbox.rainer/Apps/Dropbox PocketBook/03-News"
OUT_SYNC="${OUT_PATH}/${BOOK_NAME}"
################################################################################

echo `date '+%Y-%m-%d %H:%M:%S - Create ebook: '` $BOOK_NAME |tee -a $INFO_FILE

### Check docker runs calibre container services
CALIBRE_SERVICE=calibre_tools
CALIBRE_CONTAINER=`docker ps --format 'table {{.Names}}' |grep "$CALIBRE_SERVICE"`

if [ "${CALIBRE_CONTAINER}" != "${CALIBRE_SERVICE}" ]
then
  echo "  Failure: docker container 'calibre_tools' not found" |tee -a $INFO_FILE
  exit 1
fi

### Create the epub book
### Filenames and path shall be used in the scope of container mounts
### Create the cover with build date
###   recipe use the cover-name: cover1.png
docker-compose                      \
  -f ${MAINTENACE_PATH}/docker/calibre/docker-compose.prod.nas.yml             \
  exec -T calibre_tools convert  \
  -font helvetica \
  -fill white \
  -pointsize 34 \
  -draw "text 350,910 '$DATE_NAME'" \
  ./recipes/NewsCover1.png \
  ./recipes/cover1.png

### Filenames and path shall be used in the scope of container mounts
### Create the epub book
docker-compose                      \
  -f ${MAINTENACE_PATH}/docker/calibre/docker-compose.prod.nas.yml             \
  exec -T calibre_tools ebook-convert  \
  "$IN_RECIPE"                    \
  "$OUT_BOOK"

### Move the book to the dropbox sync directory
### Filenames and path shall be used in the scope of host
if [ -e "$OUT_TMP" ]
then
  mv "$OUT_TMP" "$OUT_SYNC"
else
  echo "  Failure: created ebook $OUT_TMP not found" |tee -a $INFO_FILE
  exit 1
fi

# Remove it-news file older than 7 days
echo "Delete ebooks $BOOK_PRE_NAME older than 7 days" |tee -a $INFO_FILE
find "$OUT_PATH" -name "${BOOK_PRE_NAME}*" -type f -mtime +7 -delete

# mail info for notifications used by /usr/bin/php
#MAIL_TO="raibru1303@gmail.com"
#MAIL_TO="raibru@outlook.de"
#MAIL_SUBJECT_PRE="[Bilbo Relay]"
#MAIL_HEADER="Bilbo - NAS-Service Job"
# send mail when backup is finished
#MAIL_SUBJECT="${MAIL_SUBJECT_PRE} ebooks"
#MAIL_BODY=`printf "newest it-news"`
#MAIL_HEADER_FULL="From: ${MAIL_HEADER}"
#/usr/bin/php -r "mail('${MAIL_TO}', '${MAIL_SUBJECT}', '${MAIL_BODY}', '${MAIL_HEADER_FULL}');"
#echo "Subject: ${MAIL_SUBJECT_PRE} Backup completed
#From: ${MAIL_HEADER}
#To: ${MAIL_TO}
#
#Backup is fully completed.
#Start: ${DATE_STARTED}
#End: ${DATE_FINISHED}
#CHD: ${CUR_DRIVE_ID}
#NHD: ${NEXT_NEW_DRIVE_ID}
#Please change HD.
#" | sendmail -t

echo "  Done ok" |tee -a ${INFO_FILE}

# EOF
