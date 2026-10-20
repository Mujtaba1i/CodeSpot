#!/bin/sh
# Packs CodeSpot.app into CodeSpot.dmg with an Applications shortcut for drag-to-install.
set -e
cd "$(dirname "$0")"
rm -rf .build/dmg CodeSpot.dmg
mkdir -p .build/dmg
cp -R CodeSpot.app .build/dmg/
ln -s /Applications .build/dmg/Applications
hdiutil create -volname CodeSpot -srcfolder .build/dmg -ov -format UDZO CodeSpot.dmg
echo "Built $(pwd)/CodeSpot.dmg"
