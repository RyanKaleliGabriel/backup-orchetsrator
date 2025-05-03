#!/bin/bash

BACKUP_DIR="/home/spatial/backups"
REMOTE_PATH="/home/spatial"
REMOTE_USER="spatial"
REMOTE_HOST=192.168.100.8

#DATES
CURRENT_DATE=$(date +'%m_%Y')
PREVIOUS_MONTH_DATE=$(date --date='1 month ago' +'%m_%Y')
OLD_DATE=$(date --date='2 month ago' +'%m_%Y')

#FILE NAMES
FILE_NAME="today"
CURRENT_FILE_BASENAME="${FILE_NAME}_${CURRENT_DATE}"
PREVIOUS_FILE_BASENAME="${FILE_NAME}_${PREVIOUS_MONTH_DATE}"
OLD_FILE_BASENAME="${FILE_NAME}_${OLD_DATE}"

# REMOVE OLD FILE FROM 2 MONTHS AGO IF ITS THERE
OLD_FILE="${BACKUP_DIR}/${OLD_FILE_BASENAME}_old.txt"
if [ -f "$OLD_FILE" ]; then
   echo "Removing 2 month's ago old backup: $OLD_FILE"
   rm "$OLD_FILE"
fi

# UPDATE LATEST (1 MONTH AGO) TO old.
LATEST_FILE="${BACKUP_DIR}/${PREVIOUS_FILE_BASENAME}_latest.txt"
NEW_OLD_FILE="${BACKUP_DIR}/${PREVIOUS_FILE_BASENAME}_old.txt"
if [ -f "$LATEST_FILE" ]; then
   echo "Renaming latest file (1 month ago's backup) to old: $LATEST_FILE"
   mv "$LATEST_FILE" "$NEW_OLD_FILE"
fi

# Validate the remote file exists and get size
REMOTE_FILE="${REMOTE_PATH}/${FILE_NAME}.txt"
REMOTE_SIZE=$(ssh "$REMOTE_USER@$REMOTE_HOST" stat -c %s "$REMOTE_FILE" 2>/dev/null)

if [ -z "$REMOTE_SIZE" ]; then
    echo "❌ Failed to get remote file size. File might not exist: $REMOTE_FILE"
    exit 1
fi

echo "Remote file size: $REMOTE_SIZE bytes"

# SCP FROM REMOTE SERVER AND RENAME TO LATEST
TARGET_LATEST_FILE="${BACKUP_DIR}/${CURRENT_FILE_BASENAME}_latest.txt"
echo "Pulling file from Server"
scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_FILE" "$TARGET_LATEST_FILE"

if [ $? -ne 0 ]; then
   echo "❌ SCP failed!"
   exit 1
fi

LOCAL_SIZE=$(stat -c %s "$TARGET_LATEST_FILE")
echo "Local file size: $LOCAL_SIZE bytes"

# Validate file size match
if [ "$REMOTE_SIZE" -eq "$LOCAL_SIZE" ]; then
  echo "✅ Backup completed successfully. File sizes match."
else
  echo "❌ Backup failed! File size mismatch."
  echo "Remote: $REMOTE_SIZE bytes, Local: $LOCAL_SIZE bytes"
  exit 1
fi
