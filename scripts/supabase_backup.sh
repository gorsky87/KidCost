#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Create a KidCost Supabase database backup and Storage manifest.

Required env:
  DATABASE_URL                 Postgres connection string for the target Supabase project.

Optional env:
  KIDCOST_BACKUP_DIR           Output directory. Defaults to ./backups/supabase.
  KIDCOST_BACKUP_ENV           Environment label: local, dev, beta, prod. Defaults to dev.

Examples:
  DATABASE_URL="$DATABASE_URL" KIDCOST_BACKUP_ENV=beta scripts/supabase_backup.sh
  KIDCOST_BACKUP_DIR=/secure/backups/kidcost DATABASE_URL="$DATABASE_URL" scripts/supabase_backup.sh
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is required." >&2
  usage >&2
  exit 64
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 69
  fi
}

require_command pg_dump
require_command psql

backup_env="${KIDCOST_BACKUP_ENV:-dev}"
backup_root="${KIDCOST_BACKUP_DIR:-$(pwd)/backups/supabase}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir="${backup_root}/${backup_env}/${timestamp}"

mkdir -p "$backup_dir"
chmod 700 "$backup_dir"

db_dump="${backup_dir}/kidcost-${backup_env}-${timestamp}.dump"
schema_dump="${backup_dir}/kidcost-${backup_env}-${timestamp}-schema.sql"
storage_manifest="${backup_dir}/kidcost-${backup_env}-${timestamp}-storage-objects.csv"
backup_notes="${backup_dir}/README.txt"

echo "Creating database backup in ${backup_dir}"
pg_dump \
  --dbname="$DATABASE_URL" \
  --format=custom \
  --no-owner \
  --no-privileges \
  --file="$db_dump"

pg_dump \
  --dbname="$DATABASE_URL" \
  --schema-only \
  --no-owner \
  --no-privileges \
  --file="$schema_dump"

psql "$DATABASE_URL" \
  --no-psqlrc \
  --command "\copy (select bucket_id, name, owner, created_at, updated_at, metadata from storage.objects order by bucket_id, name) to stdout with csv header" \
  > "$storage_manifest"

cat > "$backup_notes" <<NOTES
KidCost Supabase backup

Environment: ${backup_env}
Created UTC: ${timestamp}

Files:
- $(basename "$db_dump"): custom-format Postgres dump for pg_restore.
- $(basename "$schema_dump"): schema-only SQL dump for diff/review.
- $(basename "$storage_manifest"): manifest of Storage objects visible in storage.objects.

Storage object bytes are not copied by this script. Before beta/prod tester data,
copy private bucket objects from Supabase Storage or the provider dashboard into
the same backup folder and keep the manifest with those files.

Do not commit this backup folder. It may contain private family and financial data.
NOTES

echo "Backup complete:"
echo "  Database dump: ${db_dump}"
echo "  Schema dump: ${schema_dump}"
echo "  Storage manifest: ${storage_manifest}"
