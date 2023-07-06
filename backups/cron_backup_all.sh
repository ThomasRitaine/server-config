#!/bin/bash

# Script that runs every day at 2AM, Tahiti timezone to generate backup of every database.
# 0 2 * * * TZ=Pacific/Tahiti /home/ci-cd/ci-cd-server/backups/cron_backup_all.sh

# Stop the script if an error is thrown
set -e

# Loop through all directories in the applications directory
for PROJECT_DIR in $HOME/applications/*; do
    # Check if it's a directory
    if [ -d "$PROJECT_DIR" ]; then

        # Check if a backup already exists for the current day
        CURRENT_DATE="$(date +'%Y-%m-%d')"
        if ! ls "$PROJECT_DIR/backups/$CURRENT_DATE-"*.gz >/dev/null 2>&1; then
            # Call the backup script for that directory
            bash $HOME/ci-cd-server/backups/create_backup.sh $PROJECT_DIR
        else
            PROJECT_NAME=$(basename "$PROJECT_DIR")
            echo "$PROJECT_NAME : Today's backup already exists."
        fi

    fi
done
