#!/usr/bin/env bash
# Builds the signed Android release (AAB + APKs), verifies it, and writes an
# evidence log. Usage, from frontend/mobile:
#
#   scripts/release_android.sh            # build + verify
#   scripts/release_android.sh --verify   # verify existing artefacts only
#
# Signing comes from android/key.properties or FITFLOW_* environment variables
# (see docs/lab06/01-signed-build.md). The script never prints passwords.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$(pwd)
SDK=${ANDROID_HOME:-$HOME/Library/Android/sdk}
BUILD_TOOLS=$(ls -d "$SDK"/build-tools/* | sort -V | tail -1)
JAVA_HOME=${JAVA_HOME:-"/Applications/Android Studio.app/Contents/jbr/Contents/Home"}
export JAVA_HOME
BUNDLETOOL=${BUNDLETOOL:-$HOME/.fitflow-signing/bundletool.jar}

AAB=build/app/outputs/bundle/release/app-release.aab
APK=build/app/outputs/flutter-apk/app-release.apk
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
OUT=build/release-evidence-$VERSION.txt

if [[ "${1:-}" != "--verify" ]]; then
  flutter clean >/dev/null
  flutter pub get >/dev/null
  flutter analyze
  flutter test
  flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
  flutter build apk --release --obfuscate --split-debug-info=build/debug-info
  flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
fi

{
  echo "FitFlow Android release evidence"
  echo "Version (pubspec): $VERSION"
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'uncommitted')"
  echo "Flutter: $(flutter --version 2>/dev/null | head -1)"
  echo

  echo "== Artefacts =="
  ls -l "$AAB" "$APK" build/app/outputs/flutter-apk/app-*-release.apk | awk '{printf "%10d  %s\n", $5, $9}'
  echo
  echo "== SHA-256 checksums =="
  shasum -a 256 "$AAB" "$APK"
  echo

  echo "== AAB signature (jarsigner) =="
  "$JAVA_HOME/bin/jarsigner" -verify "$AAB" | grep -E '^jar (verified|is unsigned)' 
  "$JAVA_HOME/bin/keytool" -printcert -jarfile "$AAB" | grep -E 'Owner|SHA256:|Signature algorithm|Valid'
  echo

  echo "== APK signature (apksigner) =="
  "$BUILD_TOOLS/apksigner" verify --verbose --print-certs "$APK" 2>/dev/null \
    | grep -E '^Verifies|scheme|certificate DN|certificate SHA-256|key size'
  echo

  echo "== Manifest (aapt2) =="
  "$BUILD_TOOLS/aapt2" dump badging "$APK" 2>/dev/null \
    | grep -E "^package|minSdkVersion|targetSdkVersion|uses-permission|native-code" \
    | sed -E "s/ platformBuild.*//"
  echo

  echo "== R8 shrinking =="
  if [[ -f build/app/outputs/mapping/release/mapping.txt ]]; then
    echo "mapping.txt present ($(wc -l < build/app/outputs/mapping/release/mapping.txt) lines) - code was obfuscated"
  else
    echo "WARNING: no R8 mapping file found"
  fi
  echo "Dart symbols split to build/debug-info: $(ls build/debug-info 2>/dev/null | tr '\n' ' ')"
  echo

  if [[ -f "$BUNDLETOOL" ]]; then
    echo "== Estimated Play download size per device (bytes, bundletool) =="
    TMP=$(mktemp -d)
    "$JAVA_HOME/bin/java" -jar "$BUNDLETOOL" build-apks --bundle="$AAB" --output="$TMP/app.apks" >/dev/null
    "$JAVA_HOME/bin/java" -jar "$BUNDLETOOL" get-size total --apks="$TMP/app.apks" --dimensions=ABI,SDK
    rm -rf "$TMP"
  else
    echo "(bundletool not found at $BUNDLETOOL - download size skipped)"
  fi
} | tee "$OUT"

mkdir -p ../../docs/lab06/evidence
cp "$OUT" ../../docs/lab06/evidence/
echo
echo "Evidence written to $ROOT/$OUT and docs/lab06/evidence/"
