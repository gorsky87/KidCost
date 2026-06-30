#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="${repo_root}/scripts/verify_supabase_local.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

bin_dir="${tmp_dir}/bin"
mkdir -p "$bin_dir"

make_stubs() {
  local image_present="$1"
  local log_file="$2"

  cat >"${bin_dir}/docker" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "docker $*" >>"${KIDCOST_TEST_LOG}"

case "$1" in
  info)
    if [[ "${2:-}" == "--format" ]]; then
      echo "29.4.0 linux OrbStack"
    fi
    exit 0
    ;;
  image)
    if [[ "${2:-}" == "inspect" ]]; then
      if [[ "${KIDCOST_TEST_IMAGE_PRESENT}" == "1" ]]; then
        exit 0
      fi
      exit 1
    fi
    ;;
  pull)
    echo "pulled ${2:-}"
    exit 0
    ;;
esac

echo "unexpected docker invocation: $*" >&2
exit 2
STUB

  cat >"${bin_dir}/supabase" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "supabase $*" >>"${KIDCOST_TEST_LOG}"

case "${1:-}" in
  --version)
    echo "2.107.0"
    ;;
  start)
    echo "started"
    ;;
  db)
    if [[ "${2:-}" == "reset" ]]; then
      echo "reset"
      exit 0
    fi
    echo "unexpected supabase db invocation: $*" >&2
    exit 2
    ;;
  *)
    echo "unexpected supabase invocation: $*" >&2
    exit 2
    ;;
esac
STUB

  cat >"${bin_dir}/psql" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "psql $*" >>"${KIDCOST_TEST_LOG}"

if [[ "${1:-}" == "--version" ]]; then
  echo "psql (PostgreSQL) 17.5"
  exit 0
fi

for arg in "$@"; do
  if [[ "$arg" == *"to_regclass('public.families')"* ]]; then
    echo "families"
    exit 0
  fi

  if [[ "$arg" == "select 1" ]]; then
    echo "1"
    exit 0
  fi
done

previous=""
for arg in "$@"; do
  if [[ "$previous" == "-f" ]]; then
    echo "checked ${arg}"
    exit 0
  fi
  previous="$arg"
done

echo "unexpected psql invocation: $*" >&2
exit 2
STUB

  chmod +x "${bin_dir}/docker" "${bin_dir}/supabase" "${bin_dir}/psql"

  export PATH="${bin_dir}:${PATH}"
  export KIDCOST_TEST_IMAGE_PRESENT="$image_present"
  export KIDCOST_TEST_LOG="$log_file"
}

assert_contains() {
  local file="$1"
  local expected="$2"

  if ! grep -Fq -- "$expected" "$file"; then
    echo "Expected ${file} to contain: ${expected}" >&2
    echo "--- ${file} ---" >&2
    cat "$file" >&2
    exit 1
  fi
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"

  if grep -Fq -- "$unexpected" "$file"; then
    echo "Expected ${file} not to contain: ${unexpected}" >&2
    echo "--- ${file} ---" >&2
    cat "$file" >&2
    exit 1
  fi
}

log_file="${tmp_dir}/commands.log"
output_file="${tmp_dir}/output.log"
touch "$log_file"
make_stubs 1 "$log_file"

bash "$script" --preflight-only >"$output_file" 2>&1
assert_contains "$output_file" "Preflight completed; skipping supabase start and db reset."
assert_not_contains "$log_file" "supabase start"
assert_not_contains "$log_file" "supabase db reset"

>"$log_file"
bash "$script" >"$output_file" 2>&1
assert_contains "$log_file" "supabase start"
assert_contains "$log_file" "supabase db reset"

>"$log_file"
bash "$script" --run-manual-checks >"$output_file" 2>&1
assert_contains "$output_file" "Waiting for local Supabase database readiness"
assert_contains "$output_file" "Running 14 Supabase manual SQL checks."
assert_contains "$output_file" "PASS supabase/tests/family_expense_categories_manual_check.sql"
assert_contains "$output_file" "Supabase manual SQL checks passed."
assert_contains "$log_file" "supabase start"
assert_contains "$log_file" "supabase db reset"
assert_contains "$log_file" "to_regclass('public.families')"
assert_contains "$log_file" "-qAtc select 1"

>"$log_file"
cat >"${bin_dir}/supabase" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "supabase $*" >>"${KIDCOST_TEST_LOG}"

case "${1:-}" in
  --version)
    echo "2.107.0"
    ;;
  start)
    echo "started"
    ;;
  db)
    if [[ "${2:-}" == "reset" ]]; then
      echo "reset failed" >&2
      exit 7
    fi
    echo "unexpected supabase db invocation: $*" >&2
    exit 2
    ;;
  *)
    echo "unexpected supabase invocation: $*" >&2
    exit 2
    ;;
esac
STUB
chmod +x "${bin_dir}/supabase"

if bash "$script" --run-manual-checks >"$output_file" 2>&1; then
  echo "Expected reset failure to stop before manual SQL checks." >&2
  exit 1
fi
assert_contains "$output_file" "Local Supabase reset failed before manual SQL checks."
assert_not_contains "$output_file" "Running Supabase manual SQL checks."
assert_not_contains "$log_file" "-qAtc select 1"

>"$log_file"
make_stubs 0 "$log_file"
if bash "$script" --preflight-only --skip-image-pull >"$output_file" 2>&1; then
  echo "Expected missing-image preflight to fail." >&2
  exit 1
fi
assert_contains "$output_file" "Missing required image and --skip-image-pull was set"
assert_not_contains "$log_file" "docker pull"

>"$log_file"
make_stubs 1 "$log_file"
cat >"${bin_dir}/supabase" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
echo "supabase $*" >>"${KIDCOST_TEST_LOG}"

case "${1:-}" in
  --version)
    echo "2.107.0"
    ;;
  start)
    trap '' TERM
    while :; do
      :
    done
    ;;
  *)
    echo "unexpected supabase invocation: $*" >&2
    exit 2
    ;;
esac
STUB
chmod +x "${bin_dir}/supabase"

if KIDCOST_SUPABASE_START_TIMEOUT=1 bash "$script" >"$output_file" 2>&1; then
  echo "Expected ignored-TERM start timeout to fail." >&2
  exit 1
fi
assert_contains "$output_file" "Command timed out after 1s: supabase start"
assert_contains "$output_file" "Command did not stop after SIGTERM; sending SIGKILL: supabase start"
assert_not_contains "$log_file" "supabase db reset"

echo "verify_supabase_local.sh tests passed."
