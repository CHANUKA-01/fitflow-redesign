#!/usr/bin/env bash
# Captures raw store screenshots (Flutter surface only - no system status bar) on each target device and orientation by
# running integration_test/screenshots_test.dart. Raw output goes to
# build/screenshots/<target>/; store-assets/_tools/frame_screenshots.py turns it
# into upload-ready images.
#
#   scripts/capture_screenshots.sh                 # every target
#   scripts/capture_screenshots.sh android-phone   # one target
#
# Targets: android-phone, android-tablet7-landscape, android-tablet7-portrait,
#          android-tablet10-landscape, android-tablet10-portrait,
#          ios-iphone69, ios-ipad13
#
# RECORD=1 also screen-records the run to build/recordings/<target>.mp4|.mov,
# starting once the app process appears (store-assets/_tools/make_videos.sh
# trims these into the store preview videos).
set -euo pipefail
cd "$(dirname "$0")/.."

SDK=${ANDROID_HOME:-$HOME/Library/Android/sdk}
ADB="$SDK/platform-tools/adb"
EMULATOR="$SDK/emulator/emulator"

drive() { # $1 device id, $2 target name
  rm -rf "build/screenshots/$2"
  SCREENSHOT_DIR="build/screenshots/$2" flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/screenshots_test.dart -d "$1"
}

android() { # $1 AVD, $2 target, $3 rotation (0 = natural, 1 = rotated 90°)
  "$ADB" devices | grep -q emulator && { "$ADB" emu kill || true; sleep 5; }
  "$EMULATOR" -avd "$1" -no-snapshot-save -no-boot-anim -no-audio >/dev/null 2>&1 &
  "$ADB" wait-for-device
  until [[ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == 1 ]]; do sleep 2; done
  # Keep the screen on and unlocked: a sleeping emulator backgrounds the app mid-run.
  "$ADB" shell svc power stayon true
  "$ADB" shell settings put system screen_off_timeout 1800000
  "$ADB" shell locksettings set-disabled true >/dev/null 2>&1 || true
  "$ADB" shell input keyevent KEYCODE_WAKEUP
  "$ADB" shell wm dismiss-keyguard >/dev/null 2>&1 || true
  "$ADB" shell settings put system accelerometer_rotation 0
  "$ADB" shell settings put system user_rotation "$3"
  "$ADB" uninstall io.fitflow.app >/dev/null 2>&1 || true
  if [[ "${RECORD:-}" == 1 ]]; then
    mkdir -p build/recordings
    ( until "$ADB" shell pidof io.fitflow.app >/dev/null 2>&1; do sleep 0.5; done
      "$ADB" shell screenrecord --bit-rate 8000000 --time-limit 120 /sdcard/ff.mp4 ) &
  fi
  drive "$("$ADB" devices | awk '/emulator/{print $1; exit}')" "$2"
  if [[ "${RECORD:-}" == 1 ]]; then
    "$ADB" shell pkill -INT screenrecord || true
    sleep 3
    "$ADB" pull /sdcard/ff.mp4 "build/recordings/$2.mp4" >/dev/null
  fi
  "$ADB" emu kill || true
  sleep 5
}

ios() { # $1 simulator device type, $2 target
  local name="FitFlow $2"
  local udid
  udid=$(xcrun simctl list devices | grep "$name (" | grep -oE '[0-9A-F-]{36}' | head -1 || true)
  [[ -z "$udid" ]] && udid=$(xcrun simctl create "$name" "$1")
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" >/dev/null
  local rec_pid=""
  if [[ "${RECORD:-}" == 1 ]]; then
    # Clean status bar for the recorded preview (screenshots are Flutter-only).
    xcrun simctl status_bar "$udid" override --time 9:41 --dataNetwork 5g --wifiMode active \
      --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
    mkdir -p build/recordings
    ( until pgrep -f "$udid.*Runner.app/Runner" >/dev/null; do sleep 0.5; done
      exec xcrun simctl io "$udid" recordVideo --codec h264 --force "build/recordings/$2.mov" ) &
    rec_pid=$!
  fi
  drive "$udid" "$2"
  if [[ -n "$rec_pid" ]]; then
    pkill -INT -f "recordVideo.*$2.mov" || true
    wait "$rec_pid" 2>/dev/null || true
  fi
  xcrun simctl status_bar "$udid" clear 2>/dev/null || true
  xcrun simctl shutdown "$udid" || true
}

run() {
  case "$1" in
    android-phone)              android Pixel_9a android-phone 0 ;;
    android-tablet7-landscape)  android FF_Tablet_7 "$1" 0 ;;
    android-tablet7-portrait)   android FF_Tablet_7 "$1" 1 ;;
    android-tablet10-landscape) android FF_Tablet_10 "$1" 0 ;;
    android-tablet10-portrait)  android FF_Tablet_10 "$1" 1 ;;
    ios-iphone69)               ios com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro-Max "$1" ;;
    ios-ipad13)                 ios com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB "$1" ;;
    *) echo "unknown target $1" >&2; exit 1 ;;
  esac
}

if [[ $# -gt 0 ]]; then
  for t in "$@"; do run "$t"; done
else
  for t in android-phone android-tablet7-landscape android-tablet7-portrait \
           android-tablet10-landscape android-tablet10-portrait ios-iphone69 ios-ipad13; do
    run "$t"
  done
fi
ls -R build/screenshots
