#!/usr/bin/env bash
# The App Store screenshots (MINE-5), from the simulator.
#
#   ios/screenshots.sh   Runs the StoreScreenshots UI tests on an iPhone 17 Pro
#                        Max, the 6.9" size App Store Connect asks for (1320 x
#                        2868), and writes the PNGs to ios/build/screenshots/.
#
# The games are seeded, so every run draws the same boards. The status bar is
# set to 9:41 with a full battery, and the simulator to light appearance.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
name="iPhone 17 Pro Max"

device="$(xcrun simctl list devices available --json | /usr/bin/python3 -c '
import json, sys
name = sys.argv[1]
for runtime, devices in sorted(json.load(sys.stdin)["devices"].items(), reverse=True):
    for device in devices:
        if ".iOS-" in runtime and device["name"] == name:
            print(device["udid"])
            sys.exit(0)
sys.exit("no %s simulator is available" % name)
' "$name")"

xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" >/dev/null
xcrun simctl ui "$device" appearance light
xcrun simctl status_bar "$device" override \
  --time 9:41 --dataNetwork wifi --wifiBars 3 --cellularBars 4 \
  --batteryState charged --batteryLevel 100

results="$here/build/screenshots.xcresult"
out="$here/build/screenshots"
rm -rf "$results" "$out"
mkdir -p "$out"

xcodebuild test \
  -project "$here/MineSweeper.xcodeproj" \
  -scheme MineSweeper \
  -destination "id=$device" \
  -derivedDataPath "$here/build" \
  -resultBundlePath "$results" \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:MineSweeperUITests/StoreScreenshots \
  -quiet

xcrun simctl status_bar "$device" clear

# Each attachment is exported under a UUID; the manifest has the names.
raw="$here/build/screenshots-raw"
rm -rf "$raw"
xcrun xcresulttool export attachments --path "$results" --output-path "$raw" >/dev/null
/usr/bin/python3 - "$raw" "$out" <<'PY'
import json, shutil, sys, os
raw, out = sys.argv[1], sys.argv[2]
for test in json.load(open(os.path.join(raw, "manifest.json"))):
    for attachment in test["attachments"]:
        name = attachment["suggestedHumanReadableName"].split("_")[0]
        shutil.copy(os.path.join(raw, attachment["exportedFileName"]), os.path.join(out, name + ".png"))
        print(os.path.join(out, name + ".png"))
PY

# The simulator captures in the portrait frame whatever way the phone is
# turned. The landscape shot is taken turned anticlockwise, so it turns back.
for shot in "$out"/*landscape*.png; do
  sips -r 270 "$shot" >/dev/null
done
