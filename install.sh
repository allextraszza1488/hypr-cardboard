#!/bin/sh
# Install hypr-cardboard for the current user. No root needed.
# usage: ./install.sh            install, and add the Cardboard app to Sunshine
#        ./install.sh uninstall  remove it again
set -e

src="$(cd "$(dirname "$0")" && pwd)"
bin="$HOME/.local/bin"
share="${XDG_DATA_HOME:-$HOME/.local/share}/hypr-cardboard"
apps="${XDG_CONFIG_HOME:-$HOME/.config}/sunshine/apps.json"

# Add or remove the Cardboard entry without touching the user's other apps.
sunshine_app() {
    [ -f "$apps" ] || { [ "$1" = add ] || return 0; mkdir -p "$(dirname "$apps")"; echo '{"apps": []}' >"$apps"; }
    python3 - "$apps" "$1" "$bin/cardboard-sbs" <<'PY'
import json, sys
path, action, cmd = sys.argv[1:]
with open(path) as f:
    cfg = json.load(f)
apps = [a for a in cfg.get("apps", []) if a.get("name") != "Cardboard"]
if action == "add":
    apps.insert(0, {
        "name": "Cardboard",
        "image-path": "desktop.png",
        "prep-cmd": [{"do": f"setsid -f {cmd} auto", "undo": f"{cmd} stop"}],
    })
cfg["apps"] = apps
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
PY
}

if [ "$1" = uninstall ]; then
    "$bin/cardboard-sbs" stop 2>/dev/null || true
    rm -f "$bin/cardboard-sbs"
    rm -rf "$share"
    sunshine_app remove
    echo "Removed. Restart Sunshine to drop the Cardboard app."
    exit 0
fi

missing=""
for cmd in hyprctl python3 sed awk pkill; do
    command -v "$cmd" >/dev/null || missing="$missing $cmd"
done
[ -z "$missing" ] || { echo "Missing:$missing"; exit 1; }
command -v sunshine >/dev/null || echo "Note: Sunshine not found. Install it to stream (AUR: sunshine or sunshine-bin)."

# hyprctl eval only exists with Hyprland's Lua config.
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && ! hyprctl eval 'return 1' >/dev/null 2>&1; then
    echo "Warning: 'hyprctl eval' failed. hypr-cardboard needs Hyprland with the Lua config."
fi

install -Dm755 "$src/bin/cardboard-sbs" "$bin/cardboard-sbs"
install -Dm644 "$src/share/cardboard.frag" "$share/cardboard.frag"
sunshine_app add

echo "Installed cardboard-sbs to $bin and added the Cardboard app to $apps."
echo "Restart Sunshine (systemctl --user restart sunshine) to see it in Moonlight."
case ":$PATH:" in *":$bin:"*) ;; *) echo "Add $bin to your PATH to run cardboard-sbs by hand." ;; esac
