#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/build_beta_artifacts.sh [--check-only] [--android-only] [--ios-only]

Checks KidCost beta release readiness and builds store artifacts only when
required signing/upload configuration is present.

Environment:
  KIDCOST_ALLOW_DEBUG_SIGNED_RELEASE=1  Build Android AAB even with debug signing.
  KIDCOST_IOS_EXPORT_OPTIONS_PLIST      ExportOptions.plist for signed iOS IPA export.
  KIDCOST_ENABLE_BETA_OBSERVABILITY=1   Enable analytics/crash reporting only
                                         when local Firebase config files exist.
USAGE
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mobile_dir="$repo_root/apps/mobile"
report_dir="$repo_root/build/release"
report_path="$report_dir/beta-readiness-report.md"

mode="all"

while (($#)); do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --check-only)
      mode="check"
      ;;
    --android-only)
      mode="android"
      ;;
    --ios-only)
      mode="ios"
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 127
  fi
}

append_report() {
  printf '%s\n' "$*" >> "$report_path"
}

require_command flutter

mkdir -p "$report_dir"
cat > "$report_path" <<'REPORT'
# KidCost Beta Build Readiness

REPORT

"$repo_root/scripts/verify_beta_release_config.sh" | tee -a "$report_path"

android_blocked=0
ios_blocked=0
android_observability_enabled=0
ios_observability_enabled=0

if grep -Fq 'signingConfig = signingConfigs.getByName("debug")' \
  "$repo_root/apps/mobile/android/app/build.gradle.kts" &&
  [[ "${KIDCOST_ALLOW_DEBUG_SIGNED_RELEASE:-0}" != "1" ]]; then
  android_blocked=1
  append_report ""
  append_report "## Android blocker"
  append_report ""
  append_report "- Release signing still uses the debug key. Configure a release keystore in local/CI secrets before building a Play-ready AAB."
fi

if [[ -z "${KIDCOST_IOS_EXPORT_OPTIONS_PLIST:-}" ]]; then
  ios_blocked=1
  append_report ""
  append_report "## iOS blocker"
  append_report ""
  append_report "- KIDCOST_IOS_EXPORT_OPTIONS_PLIST is not set. Provide an ExportOptions.plist and Apple distribution signing in local/CI secrets before exporting a TestFlight IPA."
fi

if [[ "${KIDCOST_ENABLE_BETA_OBSERVABILITY:-0}" == "1" ]]; then
  if [[ -f "$repo_root/apps/mobile/android/app/google-services.json" ]]; then
    android_observability_enabled=1
  else
    android_blocked=1
    append_report ""
    append_report "## Android observability blocker"
    append_report ""
    append_report "- KIDCOST_ENABLE_BETA_OBSERVABILITY=1 but apps/mobile/android/app/google-services.json is missing. Supply it through local/CI secrets and keep it untracked."
  fi

  if [[ -f "$repo_root/apps/mobile/ios/Runner/GoogleService-Info.plist" ]]; then
    ios_observability_enabled=1
  else
    ios_blocked=1
    append_report ""
    append_report "## iOS observability blocker"
    append_report ""
    append_report "- KIDCOST_ENABLE_BETA_OBSERVABILITY=1 but apps/mobile/ios/Runner/GoogleService-Info.plist is missing. Supply it through local/CI secrets and keep it untracked."
  fi
fi

if [[ "$mode" == "check" ]]; then
  echo "Readiness report: $report_path"
  exit 0
fi

cd "$mobile_dir"
flutter pub get

if [[ "$mode" == "all" || "$mode" == "android" ]]; then
  if [[ "$android_blocked" == "1" ]]; then
    echo "Skipping Android AAB: release signing blocker recorded in $report_path"
  else
    flutter build appbundle \
      --release \
      --build-name=1.0.0 \
      --build-number=2 \
      --dart-define=KIDCOST_RELEASE_CHANNEL=beta \
      --dart-define=KIDCOST_BUILD_NAME=1.0.0 \
      --dart-define=KIDCOST_BUILD_NUMBER=2 \
      --dart-define=KIDCOST_ANALYTICS_ENABLED=$([[ "$android_observability_enabled" == "1" ]] && echo true || echo false) \
      --dart-define=KIDCOST_CRASH_REPORTING_ENABLED=$([[ "$android_observability_enabled" == "1" ]] && echo true || echo false) \
      --dart-define=KIDCOST_FIREBASE_CONFIGURED=$([[ "$android_observability_enabled" == "1" ]] && echo true || echo false)
    append_report ""
    append_report "## Android artifact"
    append_report ""
    append_report "- apps/mobile/build/app/outputs/bundle/release/app-release.aab"
  fi
fi

if [[ "$mode" == "all" || "$mode" == "ios" ]]; then
  if [[ "$ios_blocked" == "1" ]]; then
    echo "Skipping iOS IPA: signing/export blocker recorded in $report_path"
  else
    flutter build ipa \
      --release \
      --build-name=1.0.0 \
      --build-number=2 \
      --export-options-plist="$KIDCOST_IOS_EXPORT_OPTIONS_PLIST" \
      --dart-define=KIDCOST_RELEASE_CHANNEL=beta \
      --dart-define=KIDCOST_BUILD_NAME=1.0.0 \
      --dart-define=KIDCOST_BUILD_NUMBER=2 \
      --dart-define=KIDCOST_ANALYTICS_ENABLED=$([[ "$ios_observability_enabled" == "1" ]] && echo true || echo false) \
      --dart-define=KIDCOST_CRASH_REPORTING_ENABLED=$([[ "$ios_observability_enabled" == "1" ]] && echo true || echo false) \
      --dart-define=KIDCOST_FIREBASE_CONFIGURED=$([[ "$ios_observability_enabled" == "1" ]] && echo true || echo false)
    append_report ""
    append_report "## iOS artifact"
    append_report ""
    append_report "- apps/mobile/build/ios/ipa/*.ipa"
  fi
fi

echo "Readiness report: $report_path"
