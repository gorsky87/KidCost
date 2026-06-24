#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/run_android_demo.sh [--smoke] [--keep-emulator]

Starts or reuses an Android device for the KidCost Flutter demo.

Options:
  --smoke          Build, install, launch, capture a screenshot, then exit.
  --keep-emulator  Leave an emulator running when this script started it.

Environment:
  KIDCOST_ANDROID_AVD      AVD to launch when no device is connected.
                           Default: kidcost_demo_api36
  KIDCOST_ANDROID_DEVICE   Device id to use instead of auto-detecting.
  KIDCOST_SMOKE_SCREENSHOT Screenshot path for --smoke.
USAGE
}

mode="run"
keep_emulator=0

while (($#)); do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --smoke)
      mode="smoke"
      ;;
    --keep-emulator)
      keep_emulator=1
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mobile_dir="$repo_root/apps/mobile"
avd_name="${KIDCOST_ANDROID_AVD:-kidcost_demo_api36}"
screenshot_path="${KIDCOST_SMOKE_SCREENSHOT:-${TMPDIR:-/tmp}/kidcost-android-smoke.png}"
launched_emulator=0

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 127
  fi
}

first_android_device() {
  adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }'
}

wait_for_boot() {
  adb wait-for-device
  until [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
    sleep 2
  done
}

cleanup() {
  if [[ "$mode" == "smoke" && "$launched_emulator" == "1" && "$keep_emulator" != "1" ]]; then
    adb emu kill >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

require_command adb
require_command emulator
require_command flutter

device_id="${KIDCOST_ANDROID_DEVICE:-$(first_android_device)}"

if [[ -z "$device_id" ]]; then
  if ! emulator -list-avds | grep -Fxq "$avd_name"; then
    echo "Android AVD '$avd_name' was not found." >&2
    echo "Create it first or set KIDCOST_ANDROID_AVD to an existing AVD." >&2
    exit 1
  fi

  echo "Starting Android emulator: $avd_name"
  emulator -avd "$avd_name" -no-snapshot-load >/tmp/kidcost-android-emulator.log 2>&1 &
  launched_emulator=1
  wait_for_boot
  device_id="$(first_android_device)"
fi

if [[ -z "$device_id" ]]; then
  echo "No Android device is available after emulator startup." >&2
  exit 1
fi

echo "Using Android device: $device_id"

cd "$mobile_dir"

if [[ "$mode" == "smoke" ]]; then
  flutter build apk --debug
  adb -s "$device_id" install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
  adb -s "$device_id" shell am start -n app.kidcost.mobile/.MainActivity >/dev/null
  sleep 3
  adb -s "$device_id" exec-out screencap -p > "$screenshot_path"
  echo "Smoke screenshot: $screenshot_path"
else
  flutter run -d "$device_id" --debug
fi
