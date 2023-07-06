#!/bin/bash

# Script that is called by cron_create_backups.sh or by the ci-cd pipeline to create a backup an app.
# First argument : The directory of the app to be backed up (Necessary)
# Second argument : The name of the backup file without the extension, by default crurrent the date and time (Optional)

# Stop the script if an error is thrown
set -e

if [ -z "$1" ]; then
    echo "Error, missing argument : Directory of the application to backup needed"
    exit 1
fi

PROJECT_DIR="$1"
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Import env variables for that project
if [ -e "$PROJECT_DIR/.env" ]; then
    . "$PROJECT_DIR/.env"
fi

# Generate the backup directory path
BACKUP_DIR="$PROJECT_DIR/backups"
# Create the backup directory if not already created
mkdir -p "$BACKUP_DIR"

# Generate the backup filename with the argument provided or the current date and time
if [ -n "$2" ]; then
    BACKUP_FILENAME="$2.tar.gz"
else
    BACKUP_FILENAME="$(date +'%Y-%m-%d-%H-%M').tar.gz"
fi
BACKUP_FILEPATH="$BACKUP_DIR/$BACKUP_FILENAME"


# Create a temporary directory on the host to store file to compress
TEMP_DIR=$(mktemp -d)


# Find the MySQL container ID for the project, if any
mysql_container_id=$(docker ps --format json | jq -r --arg name "$PROJECT_NAME" '. | select(.Image | startswith("mysql")) | select(.Names | startswith($name)) | .ID')
# Check if a MySQL container was found
if [ -n "$mysql_container_id" ]; then

    # Export the database within a mysql docker container
    docker exec $mysql_container_id mysqldump -u root -p"$DATABASE_ROOT_PASSWORD" $PROJECT_NAME > $TEMP_DIR/database.sql 2>/dev/null

    echo "$PROJECT_NAME : MySQL database backup complete."
fi


# Find the application container ID for the project
app_container_id=$(docker ps --filter "ancestor=$DOCKER_REGISTRY/$REPO_NAME:$IMAGE_TAG" -q)
# Check if a WordPress container was found
if [ -n "$app_container_id" ]; then

    # Get the working directory within the container
    app_container_working_directory=$(docker container inspect -f '{{.Config.WorkingDir}}' $app_container_id)

    # Copy all files in the current working directory within the docker container to the host temp directory
    mkdir "$TEMP_DIR/source_code"
    docker cp --quiet "$app_container_id:$app_container_working_directory/." "$TEMP_DIR/source_code"

    echo "$PROJECT_NAME : Source code backup complete."
fi


# If the temp dir is not empty, create an archive of its content
if [ "$(ls -A $TEMP_DIR)" ]; then
    # Import backups env
    . "$HOME/ci-cd-server/backups/.env"

    # Archive the temp directory into a tar.gz file
    tar -zcf "$BACKUP_FILEPATH" -C $TEMP_DIR .
    echo "$PROJECT_NAME : Backup archive created, $BACKUP_FILENAME"

    # Upload the generated backup to cloud
    aws s3 cp $BACKUP_FILEPATH s3://$S3_BUCKET_NAME/$PROJECT_NAME/ --endpoint-url=$S3_ENDPOINT --quiet

    echo "$PROJECT_NAME : Backup uploaded to cloud storage."
fi

# Remove the temp directory after creating the archive
rm -rf $TEMP_DIR
