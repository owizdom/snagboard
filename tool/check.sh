#!/usr/bin/env bash
# Gate: analyzer clean, Dart suite and rules suite each run >0 tests with
# 0 skipped and 0 failed. Usage: tool/check.sh [dart|rules]
set -u
cd "$(dirname "$0")/.."
export JAVA_HOME=/opt/homebrew/opt/openjdk
export PATH="$JAVA_HOME/bin:$PATH"
mkdir -p .check
what="${1:-all}"
status=0

if [ "$what" = all ] || [ "$what" = dart ]; then
  flutter analyze || status=1
  flutter test --reporter json > .check/dart.json 2>/dev/null
  python3 - .check/dart.json <<'PY' || status=1
import json, sys
tests = {}; done = []
for line in open(sys.argv[1]):
    try: e = json.loads(line)
    except ValueError: continue
    if e.get('type') == 'testStart': tests[e['test']['id']] = e['test']['name']
    if e.get('type') == 'testDone' and not e.get('hidden'): done.append(e)
ok = sum(1 for e in done if e['result'] == 'success' and not e['skipped'])
skip = sum(1 for e in done if e['skipped'])
bad = [tests.get(e['testID'], '?') for e in done if e['result'] != 'success']
print(f"dart: {len(done)} run, {ok} passed, {len(bad)} failed, {skip} skipped")
for n in bad[:40]: print("  FAIL", n)
sys.exit(0 if done and not bad and not skip else 1)
PY
fi

if [ "$what" = all ] || [ "$what" = rules ]; then
  firebase emulators:exec --only firestore,storage --project demo-snagboard \
    "cd rules_test && node --test --test-reporter=tap" > .check/rules.tap 2>&1
  python3 - .check/rules.tap <<'PY' || status=1
import re, sys
t = open(sys.argv[1]).read()
def n(k):
    m = re.findall(rf"^# {k} (\d+)", t, re.M); return int(m[-1]) if m else 0
tests, passed, failed, skipped = n('tests'), n('pass'), n('fail'), n('skipped') + n('todo')
print(f"rules: {tests} run, {passed} passed, {failed} failed, {skipped} skipped")
for m in re.findall(r"^\s*not ok \d+ - (.*)$", t, re.M)[:40]: print("  FAIL", m)
sys.exit(0 if tests and not failed and not skipped else 1)
PY
fi
exit $status
