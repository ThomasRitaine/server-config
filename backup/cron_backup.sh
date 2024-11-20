#!/bin/bash

# Load environment variables.
. "$HOME/server-config/.env"

# Define a function to log with timestamp.
log_with_timestamp() {
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] $1"
}

# Determine the lifecycle - Daily or Weekly.
DAY_OF_WEEK=$(date +"%u")  # Monday is 1, Sunday is 7.
if [ "$DAY_OF_WEEK" -eq "7" ]; then
    LIFECYCLE="weekly"
else
    LIFECYCLE="daily"
fi

# Backup directory path
APPS_DIR="$HOME/applications"

# Iterate over all applications.
for APP_DIR in $APPS_DIR/*; do
    if [ -d "$APP_DIR" ]; then
        APP_NAME=$(basename $APP_DIR)
        
        # Check for the .backup file.
        if [ ! -f "$APP_DIR/.backup" ]; then
            log_with_timestamp "$APP_NAME: No .backup file, skipping..."
            continue
        fi
        
        # Check if docker-compose.prod.yml exists
        COMPOSE_FILES="-f $APP_DIR/docker-compose.yml"
        if [ -f "$APP_DIR/docker-compose.prod.yml" ]; then
            COMPOSE_FILES="$COMPOSE_FILES -f $APP_DIR/docker-compose.prod.yml"
        fi

        # Get list of volume names
        ALL_VOLUMES=$(docker compose $COMPOSE_FILES config --format json | jq -r '.volumes[].name')
        
        # Convert ALL_VOLUMES to an array
        IFS=$'\n' read -rd '' -a ALL_VOLUMES_ARRAY <<< "$ALL_VOLUMES"

        # Extract volume details
        VOLUMES_TO_BACKUP=()
        if [ -f "$APP_DIR/.backup" ]; then
            while IFS= read -r line; do
                if [ "$line" = "*" ]; then
                    VOLUMES_TO_BACKUP=("${ALL_VOLUMES_ARRAY[@]}")
                    break
                else
                    for volume in "${ALL_VOLUMES_ARRAY[@]}"; do
                        if [ "$volume" == "$line" ]; then
                            VOLUMES_TO_BACKUP+=("$volume")
                        fi
                    done
                fi
            done < "$APP_DIR/.backup"
        fi

        TIMESTAMP=$(date +"%Y-%m-%d-%H-%M")
        BACKUP_FILENAME="$APP_NAME-$TIMESTAMP"
        BACKUP_FILEPATH="$APP_DIR/$BACKUP_FILENAME.tar.gz"

        TMP_DIR=$(mktemp -d)
        chmod 755 $TMP_DIR
        mkdir -p $TMP_DIR/$BACKUP_FILENAME

        # Backup and archive selected volumes.
        for VOLUME in "${VOLUMES_TO_BACKUP[@]}"; do
            log_with_timestamp "$APP_NAME: Backing up $VOLUME..."
            docker run --rm -v $VOLUME:/source -v $TMP_DIR:/backup busybox sh -c "cp -R /source /backup/$BACKUP_FILENAME/$VOLUME && chown -R $(id -u):$(id -g) /backup/$BACKUP_FILENAME/$VOLUME"
        done
        
        # Archive all volume backups.
        log_with_timestamp "$APP_NAME: Creating archive..."
        tar -czf $BACKUP_FILEPATH -C $TMP_DIR .

        # Push to S3.
        log_with_timestamp "$APP_NAME: Pushing to S3..."
        aws s3 cp $BACKUP_FILEPATH s3://$S3_BUCKET_NAME/$LIFECYCLE/$APP_NAME/ --endpoint-url=$S3_ENDPOINT --quiet

        # Clean up local older archives (keep the latest).
        find $APP_DIR -type f -name "$APP_NAME-*.tar.gz" ! -name $BACKUP_FILENAME.tar.gz -delete
        
        # Cleanup the temporary directory.
        rm -rf $TMP_DIR

        log_with_timestamp "$APP_NAME: Backup complete."
    fi
done
