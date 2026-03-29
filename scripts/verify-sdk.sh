#!/bin/bash
set -e

echo "=== SDK Check ==="
SDK=$(xcrun --show-sdk-path 2>/dev/null || echo "$SDKROOT")
echo "SDKROOT: $SDK"
TBD="$SDK/usr/lib/libSystem.tbd"

if [ ! -f "$TBD" ]; then
  echo "ERROR: $TBD not found"
  exit 1
fi

echo ""
echo "=== Top-level targets in libSystem.tbd ==="
# Only check the first "targets:" line (top-level, not re-exported sub-libraries)
FIRST_TARGETS=$(grep -m1 "^targets:" "$TBD")
echo "$FIRST_TARGETS"
echo ""

if echo "$FIRST_TARGETS" | grep -q "arm64-macos"; then
  echo "SKIP: Top-level targets still include arm64-macos, bug will not reproduce."
  echo "      This test requires a macOS SDK where libSystem.tbd top-level"
  echo "      targets only have arm64e-macos (macOS 26.3+/SDK 26.2+)."
  exit 1
fi

echo "CONFIRMED: libSystem.tbd top-level targets have NO arm64-macos, only arm64e-macos."
echo "           Bug should reproduce with conda-forge toolchain."
