#!/usr/bin/env bash

# ------------------------------------------------------------------------------------
# Script: cron_backup.sh
# Description:
#   - Backs up each directory under ~/applications, including hidden files, skipping
#     subdirectories if they exceed MAX_SIZE_MB in size.
#   - Skips any file ending with .tar.gz so old backups are not re-archived.
#   - If a .backup file exists in the application directory,
#     reads Docker volume names (or uses '*' to back up all volumes),
#     archiving them under "volumes".
#   - Uses 'docker compose' for volume definitions.
#   - Logs events with timestamps and continues on permission errors.
#
# Usage: Typically invoked by systemd or cron. No arguments needed.
# ------------------------------------------------------------------------------------

# Load environment variables (e.g., S3_BUCKET_NAME, S3_ENDPOINT).
. "$HOME/server-config/.env"

# Log with timestamp.
log_with_timestamp() {
  local TIMESTAMP
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$TIMESTAMP] $1"
}

# Define the size limit (in MB) for subdirectories.
MAX_SIZE_MB=1000

# Determine the lifecycle: Daily or Weekly.
DAY_OF_WEEK=$(date +"%u") # Monday=1, Sunday=7
if [ "$DAY_OF_WEEK" -eq 7 ]; then
  LIFECYCLE="weekly"
else
  LIFECYCLE="daily"
fi

# Define base paths.
APPS_DIR="$HOME/applications"
S3_TARGET="s3://$S3_BUCKET_NAME/$LIFECYCLE"

# Iterate over each application directory in $APPS_DIR.
for APP_DIR in "$APPS_DIR"/*; do
  [ -d "$APP_DIR" ] || continue

  APP_NAME=$(basename "$APP_DIR")
  log_with_timestamp "$APP_NAME: Backing up source files..."

  TIMESTAMP=$(date +"%Y-%m-%d-%H-%M")
  BACKUP_FILENAME="$APP_NAME-$TIMESTAMP"
  BACKUP_FILEPATH="$APP_DIR/$BACKUP_FILENAME.tar.gz"

  # Create a temporary directory for building the archive.
  TMP_DIR=$(mktemp -d)
  chmod 755 "$TMP_DIR"
  mkdir -p "$TMP_DIR/$BACKUP_FILENAME/source"

  #
  # Copy top-level files/directories (including hidden) using 'find',
  # skipping:
  #   - .tar.gz files
  #   - subdirectories over MAX_SIZE_MB
  #   - items that cause permission errors (logs and continues)
  #
  while IFS= read -r -d '' ITEM; do
    ITEM_BASENAME=$(basename "$ITEM")

    # Skip old backup archives
    if [[ "$ITEM_BASENAME" == *.tar.gz ]]; then
      continue
    fi

    if [ -d "$ITEM" ]; then
      SUBDIR_SIZE_MB=$(du -sm "$ITEM" 2>/dev/null | cut -f1)
      if [ "$SUBDIR_SIZE_MB" -le "$MAX_SIZE_MB" ]; then
        cp -a "$ITEM" "$TMP_DIR/$BACKUP_FILENAME/source/" 2>/dev/null ||
          log_with_timestamp "$APP_NAME: Skipping directory '$ITEM_BASENAME' due to permission error"
      else
        log_with_timestamp "$APP_NAME: Skipping subdirectory '$ITEM_BASENAME' (size > ${MAX_SIZE_MB}MB)"
      fi
    else
      cp -a "$ITEM" "$TMP_DIR/$BACKUP_FILENAME/source/" 2>/dev/null ||
        log_with_timestamp "$APP_NAME: Skipping file '$ITEM_BASENAME' due to permission error"
    fi
  done < <(find "$APP_DIR" -mindepth 1 -maxdepth 1 -print0)

  #
  # If a .backup file exists, back up Docker volumes.
  #
  if [ -f "$APP_DIR/.backup" ]; then
    # Gather all docker-compose*.yml files.
    COMPOSE_ARGS=()
    for FILE in "$APP_DIR"/docker-compose*.yml; do
      [ -f "$FILE" ] && COMPOSE_ARGS+=("-f" "$FILE")
    done

    if [ ${#COMPOSE_ARGS[@]} -eq 0 ]; then
      log_with_timestamp "$APP_NAME: No docker-compose files found, skipping volume backup..."
    else
      # Retrieve volumes from docker compose config
      ALL_VOLUMES_JSON=$(docker compose "${COMPOSE_ARGS[@]}" config --format json 2>/dev/null || true)
      ALL_VOLUMES_ARRAY=()

      if [ -n "$ALL_VOLUMES_JSON" ]; then
        # Parse volume names into ALL_VOLUMES_ARRAY
        while IFS= read -r volumeName || [ -n "$volumeName" ]; do
          ALL_VOLUMES_ARRAY+=("$volumeName")
        done < <(echo "$ALL_VOLUMES_JSON" | jq -r '.volumes[].name // empty' 2>/dev/null)
      fi

      if [ ${#ALL_VOLUMES_ARRAY[@]} -eq 0 ]; then
        log_with_timestamp "$APP_NAME: No volumes declared in compose config..."
      else
        # Build the list of volumes to back up from .backup
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

        # If .backup contains '*', replace with all volumes
        if [ "$BACKUP_HAS_WILDCARD" = true ]; then
          VOLUMES_TO_BACKUP=("${ALL_VOLUMES_ARRAY[@]}")
        fi

        # Perform volume backups
        if [ ${#VOLUMES_TO_BACKUP[@]} -gt 0 ]; then
          mkdir -p "$TMP_DIR/$BACKUP_FILENAME/volumes"
          for VOLUME in "${VOLUMES_TO_BACKUP[@]}"; do
            log_with_timestamp "$APP_NAME: Backing up volume '$VOLUME'..."
            docker run --rm \
              -v "$VOLUME":/source \
              -v "$TMP_DIR/$BACKUP_FILENAME/volumes":/backup \
              busybox sh -c "cp -a /source /backup/$VOLUME && chown -R $(id -u):$(id -g) /backup/$VOLUME" 2>/dev/null ||
              log_with_timestamp "$APP_NAME: Skipping volume '$VOLUME' due to permission or Docker error"
          done
        fi
      fi
    fi
  else
    log_with_timestamp "$APP_NAME: No .backup file found, skipping volume backup..."
  fi

  #
  # Create the archive
  #
  log_with_timestamp "$APP_NAME: Creating archive..."
  (
    cd "$TMP_DIR" || exit 1
    tar -czf "$BACKUP_FILEPATH" "$BACKUP_FILENAME"
  )

  #
  # Upload to S3
  #
  log_with_timestamp "$APP_NAME: Uploading archive to S3..."
  aws s3 cp "$BACKUP_FILEPATH" "$S3_TARGET/$APP_NAME/" \
    --endpoint-url="$S3_ENDPOINT" --quiet

  #
  # Clean up older archives locally (keep only the latest)
  #
  find "$APP_DIR" -type f -name "$APP_NAME-*.tar.gz" ! -name "$BACKUP_FILENAME.tar.gz" -delete

  #
  # Remove the temporary directory
  #
  rm -rf "$TMP_DIR"

  log_with_timestamp "$APP_NAME: Backup complete."
done
