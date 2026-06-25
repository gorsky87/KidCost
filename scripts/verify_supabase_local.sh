#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Verify the local KidCost Supabase stack from a clean database.

Usage:
  scripts/verify_supabase_local.sh [--skip-image-pull]

Environment:
  KIDCOST_SUPABASE_POSTGRES_IMAGE  Postgres image required by Supabase CLI.
                                   Default: public.ecr.aws/supabase/postgres:17.6.1.136
  KIDCOST_SUPABASE_PULL_TIMEOUT    Seconds to wait for the Postgres image pull.
                                   Default: 180

The script fails before `supabase start` when the required Postgres image cannot
be pulled in time. That keeps demo audits from hanging on local Docker/OrbStack
image transfer issues before migrations can run.
USAGE
}

skip_image_pull=0

while (($#)); do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --skip-image-pull)
      skip_image_pull=1
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
  shift
done

postgres_image="${KIDCOST_SUPABASE_POSTGRES_IMAGE:-public.ecr.aws/supabase/postgres:17.6.1.136}"
pull_timeout="${KIDCOST_SUPABASE_PULL_TIMEOUT:-180}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 69
  fi
}

run_with_timeout() {
  local timeout_seconds="$1"
  shift

  "$@" &
  local child_pid=$!
  local elapsed=0

  while kill -0 "$child_pid" >/dev/null 2>&1; do
    if ((elapsed >= timeout_seconds)); then
      echo "Command timed out after ${timeout_seconds}s: $*" >&2
      kill "$child_pid" >/dev/null 2>&1 || true
      wait "$child_pid" >/dev/null 2>&1 || true
      return 124
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done

  wait "$child_pid"
}

require_command docker
require_command psql
require_command supabase

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running or is not reachable." >&2
  exit 69
fi

echo "Docker: $(docker info --format '{{.ServerVersion}} {{.OSType}} {{.OperatingSystem}}')"
echo "Supabase: $(supabase --version)"
echo "psql: $(psql --version)"

if ! docker image inspect "$postgres_image" >/dev/null 2>&1; then
  if [[ "$skip_image_pull" == "1" ]]; then
    echo "Missing required image and --skip-image-pull was set: ${postgres_image}" >&2
    exit 69
  fi

  echo "Pulling required Supabase Postgres image: ${postgres_image}"
  run_with_timeout "$pull_timeout" docker pull "$postgres_image"
fi

docker image inspect "$postgres_image" >/dev/null

supabase start
supabase db reset

echo "Local Supabase reset completed."
