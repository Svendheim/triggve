#!/usr/bin/env bash
#
# Triggve installer -- run it right after cloning, as often as you like:
#
#   git clone https://github.com/svendheim/triggve.git
#   cd triggve && ./install.sh
#
# It puts the two pieces where REAPER expects them and makes REAPER start the
# folder loader itself, which is what the plugin's Load buttons talk to:
#
#   Triggve.jsfx              -> <resource path>/Effects/Triggve/
#   scripts/Triggve_Load.lua  -> <resource path>/Scripts/
#   one dofile line           -> <resource path>/Scripts/__startup.lua
#
# Upgrade later with: git pull && ./install.sh
#
# REAPER's resource path is found automatically on Linux and macOS. For a
# portable install, or Windows (usually %APPDATA%\REAPER), say where it is:
#
#   REAPER_DIR="$HOME/portable/REAPER" ./install.sh
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$SRC/Triggve.jsfx" ] || [ ! -f "$SRC/scripts/Triggve_Load.lua" ]; then
  echo "This does not look like a Triggve checkout:"
  echo "  $SRC/Triggve.jsfx"
  echo "  $SRC/scripts/Triggve_Load.lua"
  exit 1
fi

if [ -z "${REAPER_DIR:-}" ]; then
  case "$(uname -s)" in
    Darwin) REAPER_DIR="$HOME/Library/Application Support/REAPER" ;;
    *)      REAPER_DIR="$HOME/.config/REAPER" ;;
  esac
fi

EFFECTS="$REAPER_DIR/Effects/Triggve"
SCRIPTS="$REAPER_DIR/Scripts"
STARTUP="$SCRIPTS/__startup.lua"
MARKER="Triggve_Load.lua"

echo "resource path: $REAPER_DIR"
if [ ! -d "$REAPER_DIR" ]; then
  echo
  echo "Nothing there. Start REAPER once so it creates its resource path, or run"
  echo "this with REAPER_DIR pointing at it (portable installs, Windows):"
  echo
  echo "  REAPER_DIR=/path/to/REAPER ./install.sh"
  exit 1
fi

mkdir -p "$EFFECTS" "$SCRIPTS"
cp "$SRC/Triggve.jsfx"              "$EFFECTS/"
cp "$SRC/scripts/Triggve_Load.lua"  "$SCRIPTS/"
echo "installed     $EFFECTS/Triggve.jsfx"
echo "installed     $SCRIPTS/$MARKER"

# REAPER runs Scripts/__startup.lua on launch, which is the only native way to
# keep a helper script running for the whole session. Anything already in that
# file is left alone; the line is added once and then detected on later runs.
if [ -f "$STARTUP" ] && grep -q "$MARKER" "$STARTUP"; then
  echo "startup hook  already registered in $STARTUP"
else
  {
    echo ""
    echo "-- Triggve folder loader (added by Triggve's install.sh)"
    echo 'dofile(reaper.GetResourcePath() .. "/Scripts/Triggve_Load.lua")'
  } >>"$STARTUP"
  echo "startup hook  added loader to $STARTUP"
fi

cat <<'NEXT'

Done.

  * Restart REAPER -- that starts the folder loader and picks up the new JSFX.
    (Without restarting: run Scripts/Triggve_Load.lua once from the action list,
    and refresh the plug-in with F5 in the FX browser or right-click -> Refresh.)
  * Put Triggve on a track, open it, and press Load on a row: REAPER's own file
    picker opens, and the folder of whatever you pick fills that row.

To undo the install, delete the two installed files and the line marked
"Triggve folder loader" from Scripts/__startup.lua.
NEXT
