#!/bin/sh
# Builds CodeSpot.app from the Swift package (no Xcode needed).
# UNIVERSAL=1 ./build.sh builds one binary for Apple silicon + Intel.
set -e
cd "$(dirname "$0")"
ARCHS=""
[ -n "$UNIVERSAL" ] && ARCHS="--arch arm64 --arch x86_64"
swift build -c release $ARCHS
BIN="$(swift build -c release $ARCHS --show-bin-path)"
rm -rf CodeSpot.app
mkdir -p CodeSpot.app/Contents/MacOS CodeSpot.app/Contents/Resources
cp "$BIN/CodeSpot" CodeSpot.app/Contents/MacOS/
cp Resources/Info.plist CodeSpot.app/Contents/
cp Resources/AppIcon.icns CodeSpot.app/Contents/Resources/
codesign --force --sign - CodeSpot.app
echo "Built $(pwd)/CodeSpot.app"
