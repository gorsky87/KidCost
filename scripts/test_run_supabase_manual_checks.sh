#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="${repo_root}/scripts/run_supabase_manual_checks.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

bin_dir="${tmp_dir}/bin"
mkdir -p "$bin_dir"

cat >"${bin_dir}/psql" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

echo "psql $*" >>"${KIDCOST_TEST_LOG}"

for arg in "$@"; do
  if [[ "$arg" == "select 1" ]]; then
    echo "1"
    exit 0
  fi
done

check_file=""
previous=""
for arg in "$@"; do
  if [[ "$previous" == "-f" ]]; then
    check_file="$arg"
    break
  fi
  previous="$arg"
done

if [[ -n "$check_file" ]]; then
  if [[ -n "${KIDCOST_FAIL_CHECK:-}" && "$check_file" == *"${KIDCOST_FAIL_CHECK}" ]]; then
    echo "simulated failure for ${check_file}" >&2
    exit 5
  fi
  echo "simulated success for ${check_file}"
  exit 0
fi

echo "unexpected psql invocation: $*" >&2
exit 2
STUB
chmod +x "${bin_dir}/psql"

export PATH="${bin_dir}:${PATH}"
export KIDCOST_TEST_LOG="${tmp_dir}/commands.log"
output_file="${tmp_dir}/output.log"
touch "$KIDCOST_TEST_LOG"

assert_contains() {
  local file="$1"
  local expected="$2"

  if ! grep -Fq -- "$expected" "$file"; then
    echo "Expected ${file} to contain: ${expected}" >&2
    echo "--- ${file} ---" >&2
    sed -n '1,220p' "$file" >&2
    exit 1
  fi
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"

  if grep -Fq -- "$unexpected" "$file"; then
    echo "Expected ${file} not to contain: ${unexpected}" >&2
    echo "--- ${file} ---" >&2
    sed -n '1,220p' "$file" >&2
    exit 1
  fi
}

"$script" --list >"$output_file"
assert_contains "$output_file" "supabase/tests/family_expense_categories_manual_check.sql"
assert_contains "$output_file" "supabase/tests/storage_manual_check.sql"
assert_not_contains "$KIDCOST_TEST_LOG" "psql"

if "$script" supabase/tests/rls_manual_check.sql >"$output_file" 2>&1; then
  echo "Expected missing DATABASE_URL run to fail." >&2
  exit 1
fi
assert_contains "$output_file" "DATABASE_URL is required to run Supabase manual checks."

>"$KIDCOST_TEST_LOG"
DATABASE_URL="postgresql://example.test/kidcost" \
  "$script" \
  supabase/tests/rls_manual_check.sql \
  supabase/tests/storage_manual_check.sql >"$output_file" 2>&1
assert_contains "$output_file" "Checking database connection for Supabase manual SQL checks."
assert_contains "$output_file" "Planned Supabase manual SQL checks (2):"
assert_contains "$output_file" "PASS supabase/tests/rls_manual_check.sql"
assert_contains "$output_file" "PASS supabase/tests/storage_manual_check.sql"
assert_contains "$output_file" "Supabase manual SQL checks passed."
assert_contains "$KIDCOST_TEST_LOG" "-qAtc select 1"
assert_contains "$KIDCOST_TEST_LOG" "-v ON_ERROR_STOP=1 -f"

>"$KIDCOST_TEST_LOG"
if DATABASE_URL="postgresql://example.test/kidcost" \
  KIDCOST_FAIL_CHECK="storage_manual_check.sql" \
  "$script" \
  supabase/tests/rls_manual_check.sql \
  supabase/tests/storage_manual_check.sql \
  supabase/tests/family_bootstrap_manual_check.sql >"$output_file" 2>&1; then
  echo "Expected failing manual check run to fail." >&2
  exit 1
fi
assert_contains "$output_file" "PASS supabase/tests/rls_manual_check.sql"
assert_contains "$output_file" "FAIL supabase/tests/storage_manual_check.sql"
assert_contains "$output_file" "psql output for failed check (supabase/tests/storage_manual_check.sql):"
assert_contains "$output_file" "simulated failure for"
assert_not_contains "$output_file" "PASS supabase/tests/family_bootstrap_manual_check.sql"

>"$KIDCOST_TEST_LOG"
if DATABASE_URL="postgresql://example.test/kidcost" \
  KIDCOST_FAIL_CHECK="rls_manual_check.sql" \
  "$script" \
  supabase/tests/rls_manual_check.sql \
  supabase/tests/storage_manual_check.sql >"$output_file" 2>&1; then
  echo "Expected first manual check failure to fail." >&2
  exit 1
fi
assert_contains "$output_file" "FAIL supabase/tests/rls_manual_check.sql"
assert_contains "$output_file" "Supabase manual SQL check summary:"
assert_not_contains "$output_file" "PASS supabase/tests/storage_manual_check.sql"

echo "run_supabase_manual_checks.sh tests passed."
