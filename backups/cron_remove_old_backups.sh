#!/bin/bash

# Script that runs every day at 3AM, Tahiti timezone to remove old backup of every database.
# 0 3 * * * TZ=Pacific/Tahiti /home/ci-cd/ci-cd-server/backups/cron_remove_old_backups.sh

# Stop the script if an error is thrown
set -e

# Import backups env
. "$HOME/ci-cd-server/backups/.env"

# Stop the script if an error is thrown
set -e

# Loop through all directories in the applications directory
for PROJECT_DIR in $HOME/applications/*; do
    # Check if it's a directory
    if [ -d "$PROJECT_DIR" ]; then
        PROJECT_NAME=$(basename "$PROJECT_DIR")

        # Check if there are backups for the project
        if [ -d "$PROJECT_DIR/backups" ]; then
            find "$PROJECT_DIR/backups" -type f -name "*.gz" -mtime +$BACKUP_RETENTION_DAYS -exec rm {} \;
            echo "$PROJECT_NAME : backups older than $BACKUP_RETENTION_DAYS days have been deleted."
        fi
    fi
done
