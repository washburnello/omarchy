#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
mkdir -p "$mock_bin"

cat >"$mock_bin/omarchy-cmd-present" <<'SH'
#!/bin/bash
[[ ${OMARCHY_TEST_INSTALLED:-false} == "true" ]]
SH

cat >"$mock_bin/setsid" <<'SH'
#!/bin/bash
shift
printf 'launch:%s\n' "$*" >"$OMARCHY_TEST_LOG"
SH

cat >"$mock_bin/omarchy-launch-floating-terminal-with-presentation" <<'SH'
#!/bin/bash
printf 'install:%s\n' "$*" >"$OMARCHY_TEST_LOG"
SH

chmod +x "$mock_bin"/*

launch_log="$test_tmp/launch-log"
PATH="$mock_bin:$PATH" OMARCHY_TEST_INSTALLED=true OMARCHY_TEST_LOG="$launch_log" \
  bash "$ROOT/bin/omarchy-launch-1password"
grep -Fxq 'launch:-- 1password --force-device-scale-factor=1' "$launch_log" ||
  fail "1Password launcher starts the installed app at a fixed scale factor"
pass "1Password launcher starts the installed app at a fixed scale factor"

# The .desktop override passes %U, so onepassword:// links have to survive the
# launcher rather than stop at the scale flag.
PATH="$mock_bin:$PATH" OMARCHY_TEST_INSTALLED=true OMARCHY_TEST_LOG="$launch_log" \
  bash "$ROOT/bin/omarchy-launch-1password" onepassword://open
grep -Fxq 'launch:-- 1password --force-device-scale-factor=1 onepassword://open' "$launch_log" ||
  fail "1Password launcher forwards the link it was opened with"
pass "1Password launcher forwards the link it was opened with"

PATH="$mock_bin:$PATH" OMARCHY_TEST_INSTALLED=false OMARCHY_TEST_LOG="$launch_log" \
  bash "$ROOT/bin/omarchy-launch-1password"
grep -Fxq 'install:omarchy-install-service-1password' "$launch_log" ||
  fail "1Password launcher starts the installer when missing"
pass "1Password launcher starts the installer when missing"

grep -Fq '{ omarchy = "1password" }' "$ROOT/default/hypr/bindings/applications.lua" ||
  fail "1Password keybinding uses the conditional launcher"
pass "1Password keybinding uses the conditional launcher"

desktop="$ROOT/default/applications/1password.desktop"

[[ ! -f $ROOT/applications/1password.desktop ]] ||
  fail "1Password entry is not part of the default application refresh"
pass "1Password entry is not part of the default application refresh"

grep -Fq 'Exec=omarchy-launch-1password %U' "$desktop" ||
  fail "1Password entry starts through the launcher"
pass "1Password entry starts through the launcher"

# The packaged entry carries these, and an override that drops them breaks
# onepassword:// links and window matching.
grep -Fq 'MimeType=x-scheme-handler/onepassword;' "$desktop" ||
  fail "1Password entry keeps the onepassword scheme handler"
pass "1Password entry keeps the onepassword scheme handler"

grep -Fq 'StartupWMClass=1Password' "$desktop" ||
  fail "1Password entry keeps its startup window class"
pass "1Password entry keeps its startup window class"

for script in \
  "$ROOT/bin/omarchy-install-service-1password" \
  "$ROOT/migrations/1788800900.sh"; do
  grep -Fq '$OMARCHY_PATH/default/applications/1password.desktop' "$script" ||
    fail "installs the desktop override: ${script#$ROOT/}"
  pass "installs the desktop override: ${script#$ROOT/}"
done

grep -Fq '.local/share/applications/1password.desktop' "$ROOT/bin/omarchy-remove-service-1password" ||
  fail "1Password removal takes the desktop override with it"
pass "1Password removal takes the desktop override with it"
