#!/bin/bash
# Regenerates project.pbxproj from source, builds Pillo for the simulator, installs,
# and launches it. Pass extra args through to the launched app (debug launch flags).
set -euo pipefail
cd "$(dirname "$0")"

PROJ="Pillo"
DEVICE="${PILLO_DEVICE:-iPhone 17 Pro}"

python3 gen_pbxproj.py

DEV_ID=$(xcrun simctl list devices available | awk -F'[()]' -v dev="$DEVICE" '$0 ~ dev {print $2; exit}')
if [ -z "$DEV_ID" ]; then
  echo "No simulator found matching '$DEVICE'. Available devices:"
  xcrun simctl list devices available
  exit 1
fi

# No explicit -sdk flag: the project now embeds a watchOS companion app + complications
# alongside the iOS app, and forcing a single -sdk for the whole build makes xcodebuild
# compile every target (including the watchOS ones) against that one SDK — -destination
# alone lets each target resolve its own platform from its own SDKROOT setting.
xcodebuild \
  -project "$PROJ.xcodeproj" \
  -scheme "$PROJ" \
  -configuration Debug \
  -destination "id=$DEV_ID" \
  SYMROOT="$(pwd)/build" \
  build

xcrun simctl boot "$DEV_ID" 2>/dev/null || true
open -a Simulator

APP_PATH="build/Debug-iphonesimulator/$PROJ.app"
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")

xcrun simctl install "$DEV_ID" "$APP_PATH"
xcrun simctl terminate "$DEV_ID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$DEV_ID" "$BUNDLE_ID" "$@"

echo "Launched $BUNDLE_ID on $DEVICE ($DEV_ID)"
