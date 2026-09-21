#!/usr/bin/env bash

set -euo pipefail

DB_USER="${DB_USER:-booking}"
SOURCE_DB="${SOURCE_DB:-bookings}"
RESTORE_DB="${RESTORE_DB:-bookings_restore}"

BACKUP_FILE="${1:-}"

if [[ -z "$BACKUP_FILE" ]]; then
  echo "Usage: ./scripts/restore.sh backups/bookings_YYYYMMDD_HHMMSS.dump"
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "Backup file does not exist: $BACKUP_FILE"
  exit 1
fi

echo "Creating fresh database: ${RESTORE_DB}"

docker compose exec -T db \
  psql -U "$DB_USER" -d postgres \
  -v ON_ERROR_STOP=1 \
  -c "DROP DATABASE IF EXISTS ${RESTORE_DB};" \
  -c "CREATE DATABASE ${RESTORE_DB};"

echo "Restoring ${BACKUP_FILE}"

cat "$BACKUP_FILE" | docker compose exec -T db \
  pg_restore \
    -U "$DB_USER" \
    -d "$RESTORE_DB" \
    --no-owner \
    --no-privileges \
    --exit-on-error

echo "Restore completed successfully."

echo "Verifying restored row counts..."

docker compose exec -T db \
  psql -U "$DB_USER" -d "$RESTORE_DB" \
  -c "SELECT 'hotel_bookings' AS table_name, COUNT(*) AS rows FROM hotel_bookings
      UNION ALL
      SELECT 'booking_events', COUNT(*) FROM booking_events;"
