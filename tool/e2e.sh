#!/usr/bin/env bash
# AT15: end-to-end test on the iPhone 17 Pro simulator against the Auth,
# Firestore and Storage emulators (local rules files). Usage: tool/e2e.sh
set -u
cd "$(dirname "$0")/.."
export JAVA_HOME=/opt/homebrew/opt/openjdk
export PATH="$JAVA_HOME/bin:$PATH"
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
firebase emulators:exec --only auth,firestore,storage --project fir-todo-1c2a6 \
  "flutter test integration_test/app_flow_test.dart -d 'iPhone 17 Pro' --dart-define=USE_EMULATORS=true"
exit $?
