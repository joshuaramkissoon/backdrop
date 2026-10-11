#!/bin/zsh
# Builds Backdrop.app, installs it to /Applications and opens it.
set -e
cd ${0:A:h}
swift build -c release
app=/Applications/Backdrop.app
pkill -x Backdrop 2>/dev/null || true
rm -rf $app
mkdir -p $app/Contents/MacOS
cp .build/release/Backdrop $app/Contents/MacOS/
cp Resources/Info.plist $app/Contents/
codesign --force --sign - $app
open $app
