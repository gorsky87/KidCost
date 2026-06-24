#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
expected_version="1.0.0+2"
expected_build_name="1.0.0"
expected_build_number="2"
expected_application_id="pl.kidcost.app"

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

cd "$repo_root"

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

if grep -Fq 'signingConfig = signingConfigs.getByName("debug")' \
  "$repo_root/apps/mobile/android/app/build.gradle.kts"; then
  echo "BLOCKER: Android release AAB is not store-ready until a release signing config replaces debug signing."
fi

echo "Beta release config checks passed for $expected_build_name+$expected_build_number ($expected_application_id)."
