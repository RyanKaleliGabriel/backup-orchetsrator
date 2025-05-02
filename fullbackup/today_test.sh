#!/bin/bash

BACKUP_DIR="/home/spatial/backups"
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

# SCP FROM REMOTE SERVER AND RENAME TO LATEST
REMOTE_FILE="${REMOTE_PATH}/${FILE_NAME}.txt"
TARGET_LATEST_FILE="${BACKUP_DIR}/${CURRENT_FILE_BASENAME}_latest.txt"

echo "Pulling file from Server"
scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_FILE" "$TARGET_LATEST_FILE"

if [ $? -eq 0 ]; then
  echo "✅ Backup completed successfully and saved as: $TARGET_LATEST_FILE"
else
  echo "❌ Backup failed!"
fi