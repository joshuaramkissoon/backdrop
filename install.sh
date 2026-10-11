#!/bin/sh
# Installs Backdrop:  curl -fsSL https://raw.githubusercontent.com/joshuaramkissoon/backdrop/master/install.sh | sh
# Downloads the latest signed, notarized release into /Applications (or ~/Applications) and opens it.
# Running it again updates Backdrop. To remove it, quit Backdrop and delete the app.
set -e

URL="https://github.com/joshuaramkissoon/backdrop/releases/latest/download/Backdrop.zip"

if [ "$(uname)" != "Darwin" ]; then
  echo "Backdrop is a Mac app."
  exit 1
fi
if [ "$(sw_vers -productVersion | cut -d. -f1)" -lt 14 ]; then
  echo "Backdrop needs macOS 14 or newer."
  exit 1
fi

DEST=/Applications
if [ ! -w "$DEST" ]; then
  DEST="$HOME/Applications"
  mkdir -p "$DEST"
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading Backdrop..."
curl -fsSL "$URL" -o "$TMP/Backdrop.zip"
ditto -x -k "$TMP/Backdrop.zip" "$TMP"

pkill -x Backdrop 2>/dev/null || true
rm -rf "$DEST/Backdrop.app"
mv "$TMP/Backdrop.app" "$DEST/"
open "$DEST/Backdrop.app"
echo "Installed $DEST/Backdrop.app. Look for the half-filled circle in the menu bar."
