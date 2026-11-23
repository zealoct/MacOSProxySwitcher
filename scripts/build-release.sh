#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
release_dir="$project_root/build/release"
app="$release_dir/MPS.app"
mkdir -p "$release_dir"

xcodebuild \
    -project "$project_root/MPS.xcodeproj" \
    -scheme MPS \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$project_root/build/DerivedData" \
    CONFIGURATION_BUILD_DIR="$release_dir" \
    'ARCHS=arm64 x86_64' \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY=- \
    DEVELOPMENT_TEAM= \
    build

lipo "$app/Contents/MacOS/MPS" -verify_arch arm64 x86_64
codesign --verify --deep --strict "$app"
test -s "$app/Contents/Resources/AppIcon.icns"

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
archive="$release_dir/MPS-${version}-macOS-universal.zip"
ditto -c -k --sequesterRsrc --keepParent "$app" "$archive"
(
    cd "$release_dir"
    shasum -a 256 "$(basename "$archive")" > "$archive.sha256"
)
printf '\nRelease app: %s\nRelease ZIP: %s\n' "$app" "$archive"
