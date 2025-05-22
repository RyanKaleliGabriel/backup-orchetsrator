#!/bin/bash

BACKUP_DIR="/home/sysadmin/backups"
REMOTE_PATH="/home/spatial"
REMOTE_USER="spatial"
REMOTE_HOST=172.28.71.18

#DATES
CURRENT_DATE=$(date +'%m_%Y')
PREVIOUS_MONTH_DATE=$(date --date='1 month ago' +'%m_%Y')
OLD_DATE=$(date --date='2 month ago' +'%m_%Y')

#FILE NAMES
FILE_NAME="today"
CURRENT_FILE_BASENAME="${FILE_NAME}_${CURRENT_DATE}"
PREVIOUS_FILE_BASENAME="${FILE_NAME}_${PREVIOUS_MONTH_DATE}"
OLD_FILE_BASENAME="${FILE_NAME}_${OLD_DATE}"
REMOTE_FILE="${REMOTE_PATH}/${FILE_NAME}.txt"
LATEST_PULLED_FILE="${BACKUP_DIR}/${FILE_NAME}.txt"

#Log function

log(){
   echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

rotate_backups() {
  OLD_FILE="${BACKUP_DIR}/${OLD_FILE_BASENAME}_old.txt"
  if [ -f "$OLD_FILE" ]; then
    log "Removing 2-months-ago old backup: $OLD_FILE"
    rm "$OLD_FILE"
  fi

  LATEST_FILE="${BACKUP_DIR}/${PREVIOUS_FILE_BASENAME}_latest.txt"
  NEW_OLD_FILE="${BACKUP_DIR}/${PREVIOUS_FILE_BASENAME}_old.txt"
  if [ -f "$LATEST_FILE" ]; then
    log "Renaming last month's backup to old: $LATEST_FILE"
    mv "$LATEST_FILE" "$NEW_OLD_FILE"
  fi

  log "Renaming pulled file to latest"
  mv "$LATEST_PULLED_FILE" "${BACKUP_DIR}/${CURRENT_FILE_BASENAME}_latest.txt"
}

#Start pulling
log "Pulling file from Server"
scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_FILE" "$LATEST_PULLED_FILE"
SCP_STATUS=$?

if [ $SCP_STATUS -ne 0 ]; then
   log "❌ SCP failed!"
   exit 1
fi 

REMOTE_SIZE=$(ssh "$REMOTE_USER@$REMOTE_HOST" stat -c %s "$REMOTE_FILE" 2>/dev/null)
if [ -z "$REMOTE_SIZE" ]; then
    log "❌ Failed to get remote file size. File might not exist: $REMOTE_FILE"
    exit 1
fi
LOCAL_SIZE=$(stat -c %s "$LATEST_PULLED_FILE")

log "Remote file size: $REMOTE_SIZE bytes"
log "Local file size: $LOCAL_SIZE bytes"



if [ "$REMOTE_SIZE" -eq "$LOCAL_SIZE" ]; then
    log "✅ File sizes match."
    rotate_backups
else
  log "File size mismatch retrying..."
  scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_FILE" "$LATEST_PULLED_FILE"
  LOCAL_SIZE=$(stat -c %s "$LATEST_PULLED_FILE")


  if [ "$REMOTE_SIZE" -eq "$LOCAL_SIZE" ]; then
    log "✅ Backup successful on retry. File sizes match."
    rotate_backups
  else
    log "❌ Backup failed again! File size mismatch after retry."
    log "Remote: $REMOTE_SIZE bytes, Local: $LOCAL_SIZE bytes"
    exit 1
  fi
fi
































