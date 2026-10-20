#!/bin/sh
# Builds CodeSpot.app from the Swift package (no Xcode needed).
set -e
cd "$(dirname "$0")"
swift build -c release
rm -rf CodeSpot.app
mkdir -p CodeSpot.app/Contents/MacOS
cp .build/release/CodeSpot CodeSpot.app/Contents/MacOS/
mkdir -p CodeSpot.app/Contents/Resources
cp Resources/Info.plist CodeSpot.app/Contents/
cp Resources/AppIcon.icns CodeSpot.app/Contents/Resources/
codesign --force --sign - CodeSpot.app
echo "Built $(pwd)/CodeSpot.app"
