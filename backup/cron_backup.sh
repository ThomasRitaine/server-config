#!/usr/bin/env zsh

# Script: restore_backup.sh
# Usage: Restore a backup archive for a specific application.
# ------------------------------------------------------------------------------------
# This script restores a backup for a specified application. The backup archive
# (in tar.gz format) should be located in the directory of the application.
#
# Prerequisites:
# - The backup archive must be named following the pattern <app_name>-*.tar.gz and
#   placed in the application's directory.
# - It is recommended to backup the current application directory and volumes before running this script.
# - The application directory and volumes will be restored from the backup, potentially overwriting existing data.
#
# Example Usage:
# To restore backup for an application named "my-app", run:
#     zsh ~/server-config/backup/restore_backup.sh my-app
# ------------------------------------------------------------------------------------

# Define a function to log with timestamp.
log_with_timestamp() {
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$TIMESTAMP] $1"
}

# Application name passed as an argument
APP_NAME="$1"

# Check if application name is provided
if [ -z "$APP_NAME" ]; then
  log_with_timestamp "Error: No application name provided."
  echo "Usage: $0 <app_name>"
  exit 1
fi

# Define the application directory
APP_DIR="$HOME/applications/$APP_NAME"

# Check if the application directory exists
if [ ! -d "$APP_DIR" ]; then
  log_with_timestamp "Error: Application directory for $APP_NAME does not exist."
  exit 1
fi

# Assuming the backup file is named after the application and located in the same directory
BACKUP_FILEPATH=$(ls "$APP_DIR"/"$APP_NAME"-*.tar.gz 2>/dev/null | head -n 1)

# Check for the backup file.
if [ ! -f "$BACKUP_FILEPATH" ]; then
  log_with_timestamp "$APP_NAME: No backup file found in $APP_DIR"
  exit 1
fi

# Extract the backup
TMP_DIR=$(mktemp -d)
log_with_timestamp "$APP_NAME: Extracting backup..."
tar -xzf "$BACKUP_FILEPATH" -C "$TMP_DIR"

# Assuming the backup directory is named like $APP_NAME-<timestamp>
BACKUP_CONTENT_DIR="$TMP_DIR"/*

# Restore the application directory
if [ -d "$BACKUP_CONTENT_DIR/app_dir" ]; then
  log_with_timestamp "$APP_NAME: Restoring application directory..."
  # Backup current app directory just in case
  mv "$APP_DIR" "${APP_DIR}.bak.$(date +"%Y%m%d%H%M%S")"
  mkdir -p "$APP_DIR"
  cp -a "$BACKUP_CONTENT_DIR/app_dir/." "$APP_DIR/"
else
  log_with_timestamp "$APP_NAME: No application directory found in backup."
fi

# Restore volumes
if [ -d "$BACKUP_CONTENT_DIR/volumes" ]; then
  for VOLUME_DIR in "$BACKUP_CONTENT_DIR/volumes/"*; do
    VOLUME_NAME=$(basename "$VOLUME_DIR")
    log_with_timestamp "$APP_NAME: Restoring volume $VOLUME_NAME..."
    # Remove existing volume data
    docker volume rm "$VOLUME_NAME" >/dev/null 2>&1 || true
    # Create a new empty volume
    docker volume create "$VOLUME_NAME" >/dev/null
    # Restore data into the volume
    docker run --rm -v "$VOLUME_NAME":/destination -v "$VOLUME_DIR":/source busybox sh -c "cp -a /source/. /destination/"
  done
else
  log_with_timestamp "$APP_NAME: No volumes found in backup."
fi

# Cleanup temporary directory
rm -rf "$TMP_DIR"

log_with_timestamp "$APP_NAME: Restoration complete."
