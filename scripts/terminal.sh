#!/usr/bin/env bash
# Terminal launcher — same preference order as dwm-titus dwm-terminal.
set -euo pipefail

for terminal in "${MANGO_TERMINAL:-}" alacritty kitty st warp-terminal xterm; do
	[[ -z "$terminal" ]] && continue
	if command -v "$terminal" >/dev/null 2>&1; then
		exec "$terminal" "$@"
	fi
done

echo "no supported terminal found (tried alacritty, kitty, …)" >&2
exit 1
