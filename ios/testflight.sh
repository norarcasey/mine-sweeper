#!/usr/bin/env bash
# Archive the app and send it to App Store Connect, for TestFlight (MINE-4).
#
#   ios/testflight.sh export   Archive and export a signed .ipa into ios/build/.
#                              Nothing leaves the laptop.
#   ios/testflight.sh upload   The same, but the export uploads it to App Store
#                              Connect. Publishes a build to Nora's team, so it
#                              needs a Shipit.
#
# Signing is automatic, through the Apple ID that Xcode is signed in with
# (Xcode › Settings › Accounts). -allowProvisioningUpdates lets it fetch
# profiles and the cloud-managed Apple Distribution certificate. No key,
# certificate or profile is read from or written to the repo, which is public.
#
# The build number is the commit count of HEAD. It only grows on main, so every
# upload gets a new one without a commit to bump it. The version
# (MARKETING_VERSION) is set in the project.
set -euo pipefail

mode="${1:-}"
here="$(cd "$(dirname "$0")" && pwd)"

case "$mode" in
  export | upload) ;;
  *) echo "usage: ios/testflight.sh export|upload" >&2; exit 2 ;;
esac

if [ -n "$(git -C "$here" status --porcelain)" ]; then
  echo "refusing: the tree has uncommitted changes, so the build would match no commit" >&2
  exit 1
fi
if [ "$mode" = upload ]; then
  git -C "$here" fetch --quiet origin main
  if ! git -C "$here" merge-base --is-ancestor HEAD origin/main; then
    echo "refusing: HEAD is not on origin/main, so its build number could be reused" >&2
    exit 1
  fi
fi

build="$(git -C "$here" rev-list --count HEAD)"
archive="$here/build/MineSweeper.xcarchive"
out="$here/build/export"
options="$here/build/ExportOptions.plist"
rm -rf "$archive" "$out"
mkdir -p "$here/build"

# ExportOptions.plist: destination is the only thing the two modes differ in.
cat >"$options" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>$mode</string>
  <key>teamID</key><string>6W9DVVF8CY</string>
  <key>signingStyle</key><string>automatic</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
  <key>uploadSymbols</key><true/>
</dict>
</plist>
PLIST

echo "archiving Mine Sweeper, build $build"
xcodebuild archive \
  -project "$here/MineSweeper.xcodeproj" \
  -scheme MineSweeper \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath "$archive" \
  -allowProvisioningUpdates \
  CURRENT_PROJECT_VERSION="$build" \
  -quiet

echo "exporting ($mode)"
xcodebuild -exportArchive \
  -archivePath "$archive" \
  -exportPath "$out" \
  -exportOptionsPlist "$options" \
  -allowProvisioningUpdates \
  -quiet

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  "$archive/Products/Applications/MineSweeper.app/Info.plist")"
if [ "$mode" = upload ]; then
  echo "uploaded Mine Sweeper $version ($build). App Store Connect processes it before TestFlight shows it."
else
  echo "exported Mine Sweeper $version ($build) to $out"
fi
