#!/usr/bin/env bash
# The iPhone half's checks, one command for CI and the laptop alike.
#
#   ios/test.sh gate   MineSweeperKit's swift test, then the app's unit tests.
#                      What CI's macOS job runs.
#   ios/test.sh all    The gate, then the UI tests (a win and a loss on a seeded
#                      board), less the store screenshots, which check nothing
#                      (ios/screenshots.sh). What `yarn verify` runs. The UI tests stay out of
#                      CI: they are the slow suite, and macOS minutes cost ten
#                      times Linux ones (the ci skill, LIN-20).
set -euo pipefail

mode="${1:-gate}"
here="$(cd "$(dirname "$0")" && pwd)"

swift test --package-path "$here/MineSweeperKit"

# The first available iPhone simulator: runners and laptops have different ones.
device="$(xcrun simctl list devices available --json | /usr/bin/python3 -c '
import json, sys
runtimes = json.load(sys.stdin)["devices"]
ios = sorted((k for k in runtimes if ".iOS-" in k), reverse=True)
for runtime in ios:
    for device in runtimes[runtime]:
        if device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit(0)
sys.exit("no iPhone simulator is available")
')"

case "$mode" in
  gate) only=(-only-testing:MineSweeperTests) ;;
  all) only=(-skip-testing:MineSweeperUITests/StoreScreenshots) ;;
  *) echo "usage: ios/test.sh gate|all" >&2; exit 2 ;;
esac

results="$here/build/$mode.xcresult"
rm -rf "$results"

# Signing is for devices; the simulator needs none, and CI has no account.
status=0
xcodebuild test \
  -project "$here/MineSweeper.xcodeproj" \
  -scheme MineSweeper \
  -destination "id=$device" \
  -derivedDataPath "$here/build" \
  -resultBundlePath "$results" \
  CODE_SIGNING_ALLOWED=NO \
  ${only[@]+"${only[@]}"} \
  -quiet || status=$?

# -quiet hides Swift Testing's results, so say what ran and what failed.
if [ -d "$results" ]; then
  xcrun xcresulttool get test-results summary --path "$results" --compact | /usr/bin/python3 -c '
import json, sys
s = json.load(sys.stdin)
print("app tests: %s passed, %s failed, %s skipped" % (s["passedTests"], s["failedTests"], s["skippedTests"]))
for failure in s.get("testFailures", []):
    print("  FAILED %s: %s" % (failure["testName"], failure["failureText"]))
'
fi
exit "$status"
