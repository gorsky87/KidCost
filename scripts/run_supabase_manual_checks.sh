#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Run KidCost Supabase manual SQL checks against an already-reset database.

Usage:
  DATABASE_URL="postgres://..." scripts/run_supabase_manual_checks.sh [check.sql ...]
  scripts/run_supabase_manual_checks.sh --list

By default the script runs every supabase/tests/*_manual_check.sql file in
lexicographic order. Pass one or more SQL files to run a focused subset.

Run scripts/verify_supabase_local.sh --run-manual-checks when verifying a clean
local stack from reset through the full SQL regression pack.
USAGE
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
checks_dir="${repo_root}/supabase/tests"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 69
  fi
}

manual_checks() {
  find "$checks_dir" \
    -maxdepth 1 \
    -type f \
    -name '*_manual_check.sql' \
    -print | sort
}

display_path() {
  local path="$1"
  if [[ "$path" == "${repo_root}/"* ]]; then
    printf '%s\n' "${path#${repo_root}/}"
  else
    printf '%s\n' "$path"
  fi
}

resolve_check() {
  local check="$1"

  if [[ -f "$check" ]]; then
    realpath "$check"
    return
  fi

  if [[ -f "${repo_root}/${check}" ]]; then
    realpath "${repo_root}/${check}"
    return
  fi

  echo "Manual check file does not exist: $check" >&2
  exit 66
}

print_summary() {
  local failed="${1:-}"
  local check

  echo "Supabase manual SQL check summary:"
  if ((${#passed_checks[@]} > 0)); then
    for check in "${passed_checks[@]}"; do
      echo "PASS $(display_path "$check")"
    done
  fi

  if [[ -n "$failed" ]]; then
    echo "FAIL $(display_path "$failed")"
  fi
}

if (($# > 0)); then
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --list)
      manual_checks | while IFS= read -r check; do
        display_path "$check"
      done
      exit 0
      ;;
  esac
fi

require_command psql
require_command realpath

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is required to run Supabase manual checks." >&2
  exit 64
fi

if (($# > 0)); then
  checks=()
  for check in "$@"; do
    checks+=("$(resolve_check "$check")")
  done
else
  checks=()
  while IFS= read -r check; do
    checks+=("$check")
  done < <(manual_checks)
fi

if ((${#checks[@]} == 0)); then
  echo "No Supabase manual checks found." >&2
  exit 66
fi

echo "Checking database connection for Supabase manual SQL checks."
if ! psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -qAtc "select 1" >/dev/null; then
  echo "Database connection failed before Supabase manual SQL checks." >&2
  exit 69
fi

echo "Planned Supabase manual SQL checks (${#checks[@]}):"
for check in "${checks[@]}"; do
  echo " - $(display_path "$check")"
done

echo "Running ${#checks[@]} Supabase manual SQL checks."
passed_checks=()

for check in "${checks[@]}"; do
  check_output="${tmp_dir}/$(basename "$check").log"
  if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$check" >"$check_output" 2>&1; then
    passed_checks+=("$check")
    echo "PASS $(display_path "$check")"
    continue
  else
    status=$?
  fi

  echo "FAIL $(display_path "$check")" >&2
  print_summary "$check" >&2
  echo "psql output for failed check ($(display_path "$check")):" >&2
  sed 's/^/  /' "$check_output" >&2
  exit "$status"
done

print_summary
echo "Supabase manual SQL checks passed."
