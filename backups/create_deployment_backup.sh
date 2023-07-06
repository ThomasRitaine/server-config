#!/bin/bash

# Script that is called by the ci-cd pipeline to create a pre-deployment backup of a given app.
# First argument : The directory of the app to be backed up (Necessary)

# Stop the script if an error is thrown
set -e

# Import backups env
. "$HOME/ci-cd-server/backups/.env"

PROJECT_DIR="$1"
BACKUP_DIR="$PROJECT_DIR/backups"

# Ensure the directory exists
if [[ ! -d $PROJECT_DIR ]]; then
  echo "The provided directory does not exist"
  exit 1
fi

# If the backup directory does not exist, new project, do not backup
if ! test -e $BACKUP_DIR; then
  exit 0
fi

# Create the backup directory if not already created
mkdir -p "$BACKUP_DIR"

# Get the current date and time in the format "YYYY-MM-DD-HH-MM"
current_date=$(date +"%Y-%m-%d-%H-%M")

# Create the new deployment backup with the new name format
bash $HOME/ci-cd-server/backups/create_backup.sh $PROJECT_DIR deployment-$current_date

# Get a sorted list of the backup files
backup_files=($(ls -t $BACKUP_DIR/deployment-*))

# If the number of backups is greater than DEPLOYMENT_BACKUP_RETENTION
# then remove the oldest backups until we keep just enough backups
if [ ${#backup_files[@]} -gt $DEPLOYMENT_BACKUP_RETENTION ]; then
  for (( i=$DEPLOYMENT_BACKUP_RETENTION; i<${#backup_files[@]}; i++ ))
  do
    rm ${backup_files[$i]}
  done
fi
