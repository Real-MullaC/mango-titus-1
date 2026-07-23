#!/usr/bin/env bash
# Random wallpaper from ~/Pictures/backgrounds (awww / swww).
set -euo pipefail

dir="${WALLPAPER_DIR:-$HOME/Pictures/backgrounds}"
if [[ ! -d "$dir" ]]; then
	echo "wallpaper dir missing: $dir" >&2
	exit 1
fi

# Arch renamed swww → awww; prefer awww, fall back to swww.
if command -v awww >/dev/null 2>&1; then
	CLI=awww
	DAEMON=awww-daemon
elif command -v swww >/dev/null 2>&1; then
	CLI=swww
	DAEMON=swww-daemon
else
	echo "neither awww nor swww found in PATH" >&2
	exit 1
fi

if ! pgrep -u "$(id -u)" -x "$DAEMON" >/dev/null 2>&1; then
	"$DAEMON" &
	for _ in $(seq 1 30); do
		"$CLI" query >/dev/null 2>&1 && break
		sleep 0.1
	done
fi

mapfile -t images < <(find "$dir" -type f \
	\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) \
	2>/dev/null | shuf)

if ((${#images[@]} == 0)); then
	echo "no loadable wallpaper images found in $dir" >&2
	exit 1
fi

"$CLI" img "${images[0]}" --transition-type fade --transition-duration 0.5
