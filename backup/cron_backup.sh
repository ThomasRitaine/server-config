#!/usr/bin/env bash

# ------------------------------------------------------------------------------------
# Script: cron_backup.sh
# Description: Back up application directories, skipping subdirectories over a certain
#              size limit, and optionally back up Docker volumes (defined in .backup).
#              The final TAR archive contains:
#                 1. "source": the application files/directories under the size limit
#                 2. "volumes": Docker volumes specified in .backup (or wildcard "*")
#
# Usage: Typically invoked by systemd or cron. No arguments needed.
# ------------------------------------------------------------------------------------

# Load environment variables (S3_BUCKET_NAME, S3_ENDPOINT, etc.).
. "$HOME/server-config/.env"

# Log with timestamp
log_with_timestamp() {
  local TIMESTAMP
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$TIMESTAMP] $1"
}

# Define the size limit (in MB) for subdirectories/files.
MAX_SIZE_MB=1000

# Determine the lifecycle - Daily or Weekly.
DAY_OF_WEEK=$(date +"%u") # Monday is 1, Sunday is 7
if [ "$DAY_OF_WEEK" -eq "7" ]; then
  LIFECYCLE="weekly"
else
  LIFECYCLE="daily"
fi

# Define base paths.
APPS_DIR="$HOME/applications"
S3_TARGET="s3://$S3_BUCKET_NAME/$LIFECYCLE"

#
# Iterate over each application directory in $APPS_DIR.
#
for APP_DIR in "$APPS_DIR"/*; do
  # Skip if not a directory.
  [ -d "$APP_DIR" ] || continue
  APP_NAME=$(basename "$APP_DIR")

  #
  # 1) Always back up the source, skipping any subdirectories > $MAX_SIZE_MB.
  #
  log_with_timestamp "$APP_NAME: Backing up source files..."
  TIMESTAMP=$(date +"%Y-%m-%d-%H-%M")
  BACKUP_FILENAME="$APP_NAME-$TIMESTAMP"
  BACKUP_FILEPATH="$APP_DIR/$BACKUP_FILENAME.tar.gz"

  # Create a temp directory to build the archive.
  TMP_DIR=$(mktemp -d)
  chmod 755 "$TMP_DIR"
  mkdir -p "$TMP_DIR/$BACKUP_FILENAME/source"

  for ITEM in "$APP_DIR"/*; do
    ITEM_NAME=$(basename "$ITEM")

    # Avoid recursively backing up the backup folder itself (if present).
    # For instance, skip /home/app-manager/applications/app-name/server-config/backup
    if [ "$ITEM_NAME" = "server-config" ] && [ -d "$ITEM/backup" ]; then
      continue
    fi

    if [ -d "$ITEM" ]; then
      # Check size of subdirectory
      SUBDIR_SIZE_MB=$(du -sm "$ITEM" 2>/dev/null | cut -f1)
      if [ "$SUBDIR_SIZE_MB" -le "$MAX_SIZE_MB" ]; then
        cp -a "$ITEM" "$TMP_DIR/$BACKUP_FILENAME/source/"
      else
        log_with_timestamp "$APP_NAME: Skipping subdirectory '$ITEM_NAME' (size > ${MAX_SIZE_MB}MB)"
      fi
    else
      # Copy files directly
      cp -a "$ITEM" "$TMP_DIR/$BACKUP_FILENAME/source/"
    fi
  done

  #
  # 2) Back up Docker volumes only if there's a .backup file.
  #
  if [ -f "$APP_DIR/.backup" ]; then
    # Figure out which compose file(s) exist, if any.
    COMPOSE_FILES=""
    if [ -f "$APP_DIR/docker-compose.yml" ] && [ -f "$APP_DIR/docker-compose.prod.yml" ]; then
      COMPOSE_FILES="-f $APP_DIR/docker-compose.yml -f $APP_DIR/docker-compose.prod.yml"
    elif [ -f "$APP_DIR/docker-compose.yml" ]; then
      COMPOSE_FILES="-f $APP_DIR/docker-compose.yml"
    elif [ -f "$APP_DIR/docker-compose.prod.yml" ]; then
      COMPOSE_FILES="-f $APP_DIR/docker-compose.prod.yml"
    fi

    # If no compose files found, skip volumes (but not the source backup).
    if [ -z "$COMPOSE_FILES" ]; then
      log_with_timestamp "$APP_NAME: No docker-compose file found, skipping volume backup..."
    else
      # Retrieve the full list of volumes from the Docker Compose config
      # Use '|| true' to avoid errors if .volumes is missing from the config
      ALL_VOLUMES_JSON=$(docker compose $COMPOSE_FILES config --format json || true)
      if [ -n "$ALL_VOLUMES_JSON" ]; then
        ALL_VOLUMES=$(echo "$ALL_VOLUMES_JSON" | jq -r '.volumes[].name' 2>/dev/null || true)
      fi

      if [ -n "$ALL_VOLUMES" ]; then
        # Build the list of volumes to back up from .backup
        # Check if there's a wildcard '*' that means "all volumes"
        BACKUP_HAS_WILDCARD=false
        VOLUMES_TO_BACKUP=()
        while IFS= read -r line || [ -n "$line" ]; do
          if [ "$line" = "*" ]; then
            BACKUP_HAS_WILDCARD=true
            break
          else
            VOLUMES_TO_BACKUP+=("$line")
          fi
        done <"$APP_DIR/.backup"

        if [ "$BACKUP_HAS_WILDCARD" = true ]; then
          # Replace all volumes
          IFS=$'\n' read -r -d '' -a VOLUMES_TO_BACKUP <<<"$ALL_VOLUMES"
        fi

        if [ "${#VOLUMES_TO_BACKUP[@]}" -gt 0 ]; then
          mkdir -p "$TMP_DIR/$BACKUP_FILENAME/volumes"
          for VOLUME in "${VOLUMES_TO_BACKUP[@]}"; do
            log_with_timestamp "$APP_NAME: Backing up volume '$VOLUME'..."
            docker run --rm \
              -v "$VOLUME":/source \
              -v "$TMP_DIR/$BACKUP_FILENAME/volumes":/backup \
              busybox sh -c "cp -R /source /backup/$VOLUME && chown -R $(id -u):$(id -g) /backup/$VOLUME"
          done
        fi
      fi
    fi
  else
    log_with_timestamp "$APP_NAME: No .backup file found, skipping volume backup..."
  fi

  #
  # 3) Create the archive
  #
  log_with_timestamp "$APP_NAME: Creating archive..."
  (cd "$TMP_DIR" && tar -czf "$BACKUP_FILEPATH" "$BACKUP_FILENAME")

  #
  # 4) Push to S3
  #
  log_with_timestamp "$APP_NAME: Uploading archive to S3..."
  aws s3 cp "$BACKUP_FILEPATH" "$S3_TARGET/$APP_NAME/" \
    --endpoint-url="$S3_ENDPOINT" --quiet

  #
  # 5) Clean up older archives locally (keep only the latest)
  #
  find "$APP_DIR" -type f -name "$APP_NAME-*.tar.gz" ! -name "$BACKUP_FILENAME.tar.gz" -delete

  #
  # 6) Remove the temporary directory
  #
  rm -rf "$TMP_DIR"

  log_with_timestamp "$APP_NAME: Backup complete."
done
