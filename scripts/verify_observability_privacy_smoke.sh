#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/verify_observability_privacy_smoke.sh [--check-only]

Verifies the KidCost beta telemetry privacy contract and writes a QA smoke
checklist to build/release/observability-privacy-smoke.md.
USAGE
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
telemetry_file="$repo_root/apps/mobile/lib/src/telemetry/app_telemetry.dart"
test_file="$repo_root/apps/mobile/test/widget_test.dart"
report_dir="$repo_root/build/release"
report_path="$report_dir/observability-privacy-smoke.md"
mode="write"

while (($#)); do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --check-only)
      mode="check"
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_file_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if ! grep -Fq "$pattern" "$file"; then
    fail "$description was not found in ${file#$repo_root/}"
  fi
}

forbidden_parameter_keys=(
  amount
  amount_cents
  child_name
  child_birth_date
  email
  family_name
  file_name
  merchant
  note
  payment_purpose
  receipt_text
  signed_url
  storage_path
  support_payment_note
  url
)

mvp_events=(
  signup_started
  signup_completed
  family_created
  child_added
  expense_created
  receipt_attached
  balance_viewed
  report_viewed
)

cd "$repo_root"

[[ -f "$telemetry_file" ]] || fail "telemetry source file is missing"
[[ -f "$test_file" ]] || fail "widget telemetry test file is missing"

require_file_contains "$telemetry_file" "sanitizeTelemetryParameters" "Telemetry sanitizer"
require_file_contains "$test_file" "telemetry sanitizer removes PII and precise amounts" "Telemetry sanitizer regression test"

for event in "${mvp_events[@]}"; do
  require_file_contains "$telemetry_file" "'$event'" "MVP telemetry event $event"
done

for key in "${forbidden_parameter_keys[@]}"; do
  if grep -Eq "'$key'" "$telemetry_file"; then
    fail "forbidden telemetry parameter key is allowlisted: $key"
  fi
done

if git ls-files | grep -E '(^|/)(\.env|.*\.jks|.*\.keystore|.*\.mobileprovision|.*\.p12|GoogleService-Info\.plist|google-services\.json|.*service-account.*\.json)$' >/dev/null; then
  fail "tracked observability, signing, or environment secret detected"
fi

mkdir -p "$report_dir"
cat > "$report_path" <<'REPORT'
# KidCost Observability Privacy Smoke

This smoke checklist is for a beta build produced with:

```sh
KIDCOST_RELEASE_CHANNEL=beta
KIDCOST_ANALYTICS_ENABLED=true
KIDCOST_CRASH_REPORTING_ENABLED=true
```

## Automated preflight

- [x] MVP telemetry events are declared in `apps/mobile/lib/src/telemetry/app_telemetry.dart`.
- [x] Telemetry parameters pass through `sanitizeTelemetryParameters`.
- [x] The sanitizer regression test covers PII and precise amount removal.
- [x] Git is not tracking Firebase config, signing keys, provisioning profiles, service accounts, or `.env` files.
- [x] The telemetry allowlist does not include child names, emails, notes, merchants, precise amounts, storage paths, signed URLs, receipt text, or file names.

## Required Firebase inputs

- [ ] `KIDCOST_FIREBASE_ANDROID_CONFIG` points to an untracked `google-services.json`.
- [ ] `KIDCOST_FIREBASE_IOS_CONFIG` points to an untracked `GoogleService-Info.plist`.
- [ ] Firebase Analytics and Crashlytics SDKs are wired in the mobile runtime before enabling the flags for a shipped beta.

## MVP event smoke

- [ ] `signup_started` appears after opening the signup flow.
- [ ] `signup_completed` appears after creating a beta test account.
- [ ] `family_created` appears after onboarding creates a family.
- [ ] `child_added` appears after adding a child profile.
- [ ] `expense_created` appears after saving a cost.
- [ ] `receipt_attached` appears after attaching a receipt/PDF.
- [ ] `balance_viewed` appears after opening the dashboard/balance view.
- [ ] `report_viewed` appears after opening Reports.

## Privacy inspection

- [ ] Event parameters do not include child names, account emails, free-text notes, merchant names, payment purpose, receipt OCR text, storage paths, signed URLs, or file names.
- [ ] Amounts are represented only as coarse counts or booleans, never precise currency values.
- [ ] Crashlytics logs for a controlled crash do not contain entered family data, Supabase URLs with paths, storage object keys, auth tokens, or request payloads.
- [ ] The test crash is visible in Crashlytics for the beta Firebase project.

## Controlled crash

- [ ] Trigger one controlled non-production test crash from a beta tester account.
- [ ] Confirm the crash is grouped in the beta Firebase project, not a dev/public project.
- [ ] Record the Crashlytics issue id and timestamp in the release ticket or PR.
REPORT

if [[ "$mode" == "check" ]]; then
  echo "Observability privacy smoke report: $report_path"
else
  echo "Wrote observability privacy smoke report: $report_path"
fi
