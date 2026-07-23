#!/usr/bin/env bash
# Clipboard history picker (cliphist). Interim UI until Quickshell wraps it.
set -euo pipefail

if ! command -v cliphist >/dev/null 2>&1; then
	echo "cliphist not installed" >&2
	exit 1
fi

# Prefer a simple dmenu-style picker when present; else print list for debugging
if command -v wofi >/dev/null 2>&1; then
	cliphist list | wofi --dmenu | cliphist decode | wl-copy
elif command -v rofi >/dev/null 2>&1; then
	cliphist list | rofi -dmenu | cliphist decode | wl-copy
elif command -v fuzzel >/dev/null 2>&1; then
	cliphist list | fuzzel --dmenu | cliphist decode | wl-copy
else
	# No picker — still decode newest entry to clipboard as a fallback
	cliphist list | head -n1 | cliphist decode | wl-copy
fi
