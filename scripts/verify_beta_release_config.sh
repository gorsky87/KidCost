#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
expected_version="1.0.0+2"
expected_build_name="1.0.0"
expected_build_number="2"
expected_application_id="pl.kidcost.app"
analytics_enabled="${KIDCOST_ANALYTICS_ENABLED:-false}"
crash_reporting_enabled="${KIDCOST_CRASH_REPORTING_ENABLED:-false}"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_file_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if ! grep -Fq "$pattern" "$repo_root/$file"; then
    fail "$description was not found in $file"
  fi
}

is_true() {
  case "$1" in
    true|1) return 0 ;;
    *) return 1 ;;
  esac
}

validate_bool_env() {
  local name="$1"
  local value="$2"

  case "$value" in
    true|false|1|0) ;;
    *) fail "$name must be one of: true, false, 1, 0" ;;
  esac
}

is_repo_tracked() {
  local candidate="$1"
  local candidate_abs
  local tracked_path

  if [[ "$candidate" == /* ]]; then
    candidate_abs="$candidate"
  else
    candidate_abs="$repo_root/$candidate"
  fi

  while IFS= read -r tracked_path; do
    if [[ "$repo_root/$tracked_path" == "$candidate_abs" ]]; then
      return 0
    fi
  done < <(git ls-files)

  return 1
}

require_untracked_config_file() {
  local env_name="$1"
  local path="$2"
  local expected_name="$3"
  local content_marker="$4"

  if [[ -z "$path" ]]; then
    fail "$env_name must point to $expected_name when analytics or crash reporting is enabled"
  fi

  if [[ ! -f "$path" ]]; then
    fail "$env_name points to a missing file: $path"
  fi

  if [[ "$(basename "$path")" != "$expected_name" ]]; then
    fail "$env_name must point to a file named $expected_name"
  fi

  if is_repo_tracked "$path"; then
    fail "$env_name points to a tracked Firebase config file; keep it in local/CI secrets"
  fi

  if ! grep -Fq "$content_marker" "$path"; then
    fail "$env_name does not look like a Firebase $expected_name file"
  fi
}

require_firebase_runtime_wired() {
  require_file_contains \
    "apps/mobile/pubspec.yaml" \
    "firebase_core:" \
    "Firebase Core dependency"

  require_file_contains \
    "apps/mobile/pubspec.yaml" \
    "firebase_analytics:" \
    "Firebase Analytics dependency"

  require_file_contains \
    "apps/mobile/pubspec.yaml" \
    "firebase_crashlytics:" \
    "Firebase Crashlytics dependency"

  if grep -Fq "telemetry: NoopTelemetry()" "$repo_root/apps/mobile/lib/main.dart"; then
    fail "Firebase observability is enabled, but main.dart still wires NoopTelemetry"
  fi
}

cd "$repo_root"

validate_bool_env "KIDCOST_ANALYTICS_ENABLED" "$analytics_enabled"
validate_bool_env "KIDCOST_CRASH_REPORTING_ENABLED" "$crash_reporting_enabled"

require_file_contains \
  "apps/mobile/pubspec.yaml" \
  "version: $expected_version" \
  "Flutter version $expected_version"

require_file_contains \
  "apps/mobile/lib/src/config/app_config.dart" \
  "defaultValue: '$expected_build_number'" \
  "AppConfig default build number $expected_build_number"

require_file_contains \
  "apps/mobile/android/app/build.gradle.kts" \
  "applicationId = \"$expected_application_id\"" \
  "Android application id $expected_application_id"

require_file_contains \
  "apps/mobile/ios/Runner.xcodeproj/project.pbxproj" \
  "PRODUCT_BUNDLE_IDENTIFIER = $expected_application_id;" \
  "iOS bundle id $expected_application_id"

if grep -Fq "PRODUCT_BUNDLE_IDENTIFIER = app.kidcost.mobile;" \
  "$repo_root/apps/mobile/ios/Runner.xcodeproj/project.pbxproj"; then
  fail "legacy iOS bundle id app.kidcost.mobile is still configured"
fi

require_file_contains \
  "scripts/run_android_demo.sh" \
  "KIDCOST_ANDROID_PACKAGE:-$expected_application_id" \
  "Android smoke launch package $expected_application_id"

require_file_contains \
  "docs/RELEASE.md" \
  "Android package name: \`$expected_application_id\`" \
  "release Android package name"

require_file_contains \
  "docs/RELEASE.md" \
  "iOS bundle id: \`$expected_application_id\`" \
  "release iOS bundle id"

if git ls-files | grep -E '(^|/)(\.env|.*\.jks|.*\.keystore|.*\.mobileprovision|.*\.p12|GoogleService-Info\.plist|google-services\.json|.*service-account.*\.json)$' >/dev/null; then
  fail "tracked release secret or signing file detected"
fi

if is_true "$analytics_enabled" || is_true "$crash_reporting_enabled"; then
  require_untracked_config_file \
    "KIDCOST_FIREBASE_ANDROID_CONFIG" \
    "${KIDCOST_FIREBASE_ANDROID_CONFIG:-}" \
    "google-services.json" \
    '"mobilesdk_app_id"'

  require_untracked_config_file \
    "KIDCOST_FIREBASE_IOS_CONFIG" \
    "${KIDCOST_FIREBASE_IOS_CONFIG:-}" \
    "GoogleService-Info.plist" \
    "GOOGLE_APP_ID"

  require_firebase_runtime_wired
else
  echo "Observability flags are disabled; Firebase config files are not required for this build check."
fi

if grep -Fq 'signingConfig = signingConfigs.getByName("debug")' \
  "$repo_root/apps/mobile/android/app/build.gradle.kts"; then
  echo "BLOCKER: Android release AAB is not store-ready until a release signing config replaces debug signing."
fi

echo "Beta release config checks passed for $expected_build_name+$expected_build_number ($expected_application_id)."
