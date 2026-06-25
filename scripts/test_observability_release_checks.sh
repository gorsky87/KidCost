#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

run_expect_failure() {
  local expected="$1"
  shift
  local output
  local status

  set +e
  output="$("$@" 2>&1)"
  status=$?
  set -e

  if [[ "$status" == "0" ]]; then
    printf '%s\n' "$output"
    fail "expected command to fail: $*"
  fi

  if ! grep -Fq "$expected" <<<"$output"; then
    printf '%s\n' "$output"
    fail "expected failure output to contain: $expected"
  fi
}

cd "$repo_root"

"$repo_root/scripts/verify_observability_privacy_smoke.sh" --check-only
"$repo_root/scripts/verify_beta_release_config.sh"

run_expect_failure \
  "KIDCOST_FIREBASE_ANDROID_CONFIG must point to google-services.json" \
  env KIDCOST_ANALYTICS_ENABLED=true "$repo_root/scripts/verify_beta_release_config.sh"

run_expect_failure \
  "KIDCOST_ANALYTICS_ENABLED must be one of: true, false, 1, 0" \
  env KIDCOST_ANALYTICS_ENABLED=maybe "$repo_root/scripts/verify_beta_release_config.sh"

run_expect_failure \
  "KIDCOST_FIREBASE_ANDROID_CONFIG must point to google-services.json" \
  env KIDCOST_CRASH_REPORTING_ENABLED=true "$repo_root/scripts/build_beta_artifacts.sh" --check-only

echo "Observability release script tests passed."
