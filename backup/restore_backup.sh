#!/bin/bash

# Script: restore_backup.sh
# Usage: Restore a backup archive for a specific application.
# ------------------------------------------------------------------------------------
# This script restores a backup for a specified application. The backup archive 
# (in tar.gz format) should be located in the directory of the application.
# 
# Prerequisites:
# - The backup archive must be named following the pattern <app_name>-*.tar.gz and 
#   placed in the application's directory.
# - It is recommended to delete the current volumes of the application to apply 
#   the backup to, before running this script. This ensures a clean restoration.
# 
# Example Usage:
# To restore backup for an application named "my-app", run:
#     bash ~/server-config/backup/restore_backup.sh my-app
# ------------------------------------------------------------------------------------

# Define a function to log with timestamp.
log_with_timestamp() {
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] $1"
}

# Application name passed as an argument
APP_NAME="$1"

# Define the application directory
APP_DIR="$HOME/applications/$APP_NAME"

# Check if the application directory exists
if [ ! -d "$APP_DIR" ]; then
    log_with_timestamp "Error: Application directory for $APP_NAME does not exist."
    exit 1
fi

# Assuming the backup file is named after the application and located in the same directory
BACKUP_FILEPATH=$(ls $APP_DIR/$APP_NAME-*.tar.gz 2> /dev/null | head -n 1)

# Check for the backup file.
if [ ! -f "$BACKUP_FILEPATH" ]; then
    log_with_timestamp "$APP_NAME: No backup file found in $APP_DIR"
    exit 1
fi

# Extract the backup
TMP_DIR=$(mktemp -d)
log_with_timestamp "$APP_NAME: Extracting backup..."
tar -xzf $BACKUP_FILEPATH -C $TMP_DIR

# Correcting the restoration process
ARCHIVE_DIR=$(ls -d $TMP_DIR/* | head -n 1) # Getting the first directory, assuming it's the right one from the archive.
for VOLUME_DIR in $ARCHIVE_DIR/*; do
    VOLUME_NAME=$(basename $VOLUME_DIR) # Extracting the actual volume name
    log_with_timestamp "$APP_NAME: Restoring volume $VOLUME_NAME..."
    docker run --rm -v $VOLUME_NAME:/destination -v $VOLUME_DIR:/source busybox sh -c "cp -a /source/. /destination/ && chown -R $(id -u):$(id -g) /destination"
done

# Cleanup temporary directory with proper permissions
chmod -R u+rwX $TMP_DIR # Ensuring the script can clean up the directory
rm -rf $TMP_DIR

log_with_timestamp "$APP_NAME: Restoration complete."
