#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Verify the local KidCost Supabase stack from a clean database.

Usage:
  scripts/verify_supabase_local.sh [--preflight-only] [--skip-image-pull]

Environment:
  KIDCOST_SUPABASE_POSTGRES_IMAGE  Postgres image required by Supabase CLI.
                                   Default: public.ecr.aws/supabase/postgres:17.6.1.136
  KIDCOST_SUPABASE_PULL_TIMEOUT    Seconds to wait for the Postgres image pull.
                                   Default: 180
  KIDCOST_SUPABASE_START_TIMEOUT   Seconds to wait for `supabase start`.
                                   Default: 300
  KIDCOST_SUPABASE_RESET_TIMEOUT   Seconds to wait for `supabase db reset`.
                                   Default: 300

The script fails before `supabase start` when the required Postgres image cannot
be pulled in time. It also bounds `supabase start` and `supabase db reset`, so
demo audits fail with a clear diagnostic instead of hanging on local
Docker/OrbStack image transfer or container startup issues before migrations run.

Options:
  --preflight-only     Stop after prerequisite and Postgres image checks.
  --skip-image-pull    Fail when the Postgres image is missing instead of
                       attempting to pull it.
USAGE
}

preflight_only=0
skip_image_pull=0

while (($#)); do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --preflight-only)
      preflight_only=1
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
start_timeout="${KIDCOST_SUPABASE_START_TIMEOUT:-300}"
reset_timeout="${KIDCOST_SUPABASE_RESET_TIMEOUT:-300}"

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
  local term_grace_seconds=5

  while kill -0 "$child_pid" >/dev/null 2>&1; do
    if ((elapsed >= timeout_seconds)); then
      echo "Command timed out after ${timeout_seconds}s: $*" >&2
      kill "$child_pid" >/dev/null 2>&1 || true

      for ((grace_elapsed = 0; grace_elapsed < term_grace_seconds; grace_elapsed++)); do
        if ! kill -0 "$child_pid" >/dev/null 2>&1; then
          return 124
        fi
        sleep 1
      done

      if kill -0 "$child_pid" >/dev/null 2>&1; then
        echo "Command did not stop after SIGTERM; sending SIGKILL: $*" >&2
        kill -KILL "$child_pid" >/dev/null 2>&1 || true
      fi

      wait "$child_pid" >/dev/null 2>&1 || true
      return 124
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done

  wait "$child_pid"
}

require_positive_integer() {
  local name="$1"
  local value="$2"

  if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
    echo "${name} must be a positive integer number of seconds, got: ${value}" >&2
    exit 64
  fi
}

require_command docker
require_command psql
require_command supabase

require_positive_integer KIDCOST_SUPABASE_PULL_TIMEOUT "$pull_timeout"
require_positive_integer KIDCOST_SUPABASE_START_TIMEOUT "$start_timeout"
require_positive_integer KIDCOST_SUPABASE_RESET_TIMEOUT "$reset_timeout"

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

if [[ "$preflight_only" == "1" ]]; then
  echo "Preflight completed; skipping supabase start and db reset."
  exit 0
fi

echo "Starting local Supabase stack (timeout: ${start_timeout}s)."
run_with_timeout "$start_timeout" supabase start

echo "Resetting local Supabase database (timeout: ${reset_timeout}s)."
run_with_timeout "$reset_timeout" supabase db reset

echo "Local Supabase reset completed."
