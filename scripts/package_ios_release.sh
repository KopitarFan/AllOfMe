#!/usr/bin/env bash
set -euo pipefail

BUILD_NAME="${BUILD_NAME:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
CODESIGN="${CODESIGN:-0}"

echo "== All Of Me iOS release package =="
echo "Build name:   ${BUILD_NAME}"
echo "Build number: ${BUILD_NUMBER}"
echo "Codesign:     ${CODESIGN}"
echo

flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test

if [[ "${CODESIGN}" == "1" ]]; then
  flutter build ipa --release \
    --build-name "${BUILD_NAME}" \
    --build-number "${BUILD_NUMBER}"
else
  flutter build ios --release --no-codesign \
    --build-name "${BUILD_NAME}" \
    --build-number "${BUILD_NUMBER}"
fi

echo
echo "Release package step complete."
