#!/bin/bash
# Terminous: every macOS Terminal tab shows just its Claude Code thread name.
#
#   bash terminous.sh          build a "Terminous" profile from your default profile
#                              and switch every open tab to it, live
#   bash terminous.sh --undo   put every tab back on the profile you had before
#
# Claude Code names each tab after its thread ("✳ My thread"). Terminal then
# adds things to that name and, when tabs get narrow, cuts from the FRONT, so
# the thread name is the part that disappears. Terminous turns those extras off
# in a copy of your own profile (your fonts and colours stay), including the
# activity indicator, which otherwise draws the running process as a second
# label on every tab you're not on.
#
# Terminal ignores preference edits made from outside while it's running, so
# this imports the profile the way double-clicking a .terminal file does, then
# uses Terminal's own AppleScript to apply it. No restart, and running sessions
# keep running. Uses only what ships with macOS: defaults, PlistBuddy, open,
# osascript.
set -euo pipefail

PROFILE="Terminous"
STATE_DIR="$HOME/Library/Application Support/Terminous"
PB=/usr/libexec/PlistBuddy

# Everything Terminal can add to a tab or window title, plus the activity
# indicator. All off, so a tab reads only the title Claude Code sets.
OFF_KEYS=(
  ShowActiveProcessInTitle ShowActiveProcessArgumentsInTitle
  ShowActiveProcessInTabTitle ShowActiveProcessArgumentsInTabTitle
  ShowComponentsWhenTabHasCustomTitle
  ShowRepresentedURLInTitle ShowRepresentedURLPathInTitle
  ShowRepresentedURLInTabTitle ShowRepresentedURLPathInTabTitle
  ShowDimensionsInTitle ShowTTYNameInTitle ShowTTYNameInTabTitle
  ShowShellCommandInTitle ShowWindowSettingsNameInTitle ShowCommandKeyInTitle
  ShowActivityIndicatorInTab
)

die() { echo "terminous: $*" >&2; exit 1; }
[[ "$(uname)" == Darwin ]] || die "this is for macOS Terminal"
[[ -d /System/Applications/Utilities/Terminal.app ]] || die "Terminal.app not found"

# Switches every tab in every window to a profile and makes it the default for
# new windows and for Terminal's next launch.
use_profile() {
  osascript - "$1" <<'APPLESCRIPT'
on run argv
  set profileName to item 1 of argv
  tell application "Terminal"
    set switched to 0
    repeat with w in windows
      repeat with t in tabs of w
        if name of current settings of t is not profileName then
          set current settings of t to settings set profileName
          set switched to switched + 1
        end if
      end repeat
    end repeat
    set default settings to settings set profileName
    set startup settings to settings set profileName
    return switched
  end tell
end run
APPLESCRIPT
}

has_profile() {
  [[ "$(osascript -e "tell application \"Terminal\" to (name of every settings set) contains \"$1\"")" == true ]]
}

if [[ "${1:-}" == "--undo" ]]; then
  previous=$(cat "$STATE_DIR/previous-profile" 2>/dev/null || echo "Basic")
  has_profile "$previous" || previous="Basic"
  n=$(use_profile "$previous")
  echo "Switched $n tabs back to \"$previous\", which is the default again."
  echo "The \"$PROFILE\" profile is still in Terminal → Settings → Profiles; delete it there if you like."
  exit 0
fi

current=$(osascript -e 'tell application "Terminal" to name of default settings')

if has_profile "$PROFILE"; then
  # Already built once: just make sure every tab and new window uses it.
  n=$(use_profile "$PROFILE")
  echo "Terminous was already set up. Switched $n tabs to it; every tab shows just its thread name."
  exit 0
fi

mkdir -p "$STATE_DIR"
echo "$current" > "$STATE_DIR/previous-profile"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
defaults export com.apple.Terminal "$tmp/prefs.plist"

# Start from your current default profile, so its look carries over.
entry=":Window\\ Settings:${current// /\\ }"
if ! "$PB" -x -c "Print $entry" "$tmp/prefs.plist" > "$tmp/Terminous.terminal" 2>/dev/null; then
  # A built-in profile you've never changed isn't saved yet: start from
  # Terminal's defaults instead.
  rm -f "$tmp/Terminous.terminal"
  "$PB" -c "Add :type string Window Settings" "$tmp/Terminous.terminal" >/dev/null
fi
"$PB" -c "Delete :name" "$tmp/Terminous.terminal" 2>/dev/null || true
"$PB" -c "Add :name string $PROFILE" "$tmp/Terminous.terminal"
for key in "${OFF_KEYS[@]}"; do
  "$PB" -c "Delete :$key" "$tmp/Terminous.terminal" 2>/dev/null || true
  "$PB" -c "Add :$key bool false" "$tmp/Terminous.terminal"
done

# Importing opens one window with the new profile; note what's open first so
# that window can be closed again afterwards.
before=$(osascript -e 'tell application "Terminal" to get id of every window')
open "$tmp/Terminous.terminal"
for _ in {1..40}; do
  has_profile "$PROFILE" && break
  sleep 0.25
done
has_profile "$PROFILE" || die "Terminal didn't import the profile"
sleep 0.5

n=$(use_profile "$PROFILE")

osascript - "$before" <<'APPLESCRIPT'
on run argv
  -- Whole ids only (", 123," can't match inside ", 1234,").
  set oldIDs to ", " & (item 1 of argv) & ","
  tell application "Terminal"
    set newIDs to {}
    repeat with w in windows
      if oldIDs does not contain (", " & (id of w as text) & ",") then set end of newIDs to id of w
    end repeat
    repeat with i in newIDs
      close (every window whose id is (contents of i))
    end repeat
  end tell
end run
APPLESCRIPT

echo "Done. Built \"$PROFILE\" from \"$current\" and switched $n tabs to it."
echo "Every tab now shows just its thread name. New windows use it too."
echo "Undo any time: bash terminous.sh --undo"
