#!/bin/zsh
# Builds a universal Backdrop.app, signs it with your Developer ID, notarizes and staples it,
# then publishes dist/Backdrop.zip as GitHub release v<CFBundleShortVersionString>.
# Needs Xcode, a "Developer ID Application" certificate and a notarytool keychain profile
# (BACKDROP_NOTARY_PROFILE, default patch-notary). Pass --no-publish to stop after the zip.
set -e
cd ${0:A:h}/..

version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)
sign_id=$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application: [^"]*\)".*/\1/p' | head -1)
[[ -n $sign_id ]] || { echo "No Developer ID Application identity in the keychain" >&2; exit 1 }
profile=${BACKDROP_NOTARY_PROFILE:-patch-notary}

swift build -c release --arch arm64 --arch x86_64
bin=$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Backdrop
app=dist/Backdrop.app
rm -rf dist
mkdir -p $app/Contents/MacOS
cp $bin $app/Contents/MacOS/
cp Resources/Info.plist $app/Contents/
codesign --force --timestamp --options runtime --sign $sign_id $app
codesign --verify --strict $app

ditto -c -k --keepParent $app dist/Backdrop.zip
xcrun notarytool submit dist/Backdrop.zip --keychain-profile $profile --wait
xcrun stapler staple $app
rm dist/Backdrop.zip
ditto -c -k --keepParent $app dist/Backdrop.zip
spctl --assess --type execute $app
echo "Built dist/Backdrop.zip (Backdrop $version)"

[[ $1 == --no-publish ]] && exit 0
gh release create v$version dist/Backdrop.zip --title "Backdrop $version" \
  --notes "Signed and notarized. Unzip and drag Backdrop to Applications, or run: curl -fsSL https://raw.githubusercontent.com/joshuaramkissoon/backdrop/master/install.sh | sh"
