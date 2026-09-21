#!/usr/bin/env bash

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-backups}"
DB_NAME="${DB_NAME:-bookings}"
DB_USER="${DB_USER:-booking}"

mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.dump"

echo "Creating backup: ${BACKUP_FILE}"

docker compose exec -T db \
  pg_dump \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    -Fc \
  > "$BACKUP_FILE"

echo "Backup completed successfully."
ls -lh "$BACKUP_FILE"
