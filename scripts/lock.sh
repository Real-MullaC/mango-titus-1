#!/usr/bin/env bash
# Screen lock — solid-color swaylock (swaylock-effects provides /usr/bin/swaylock on Arch).
# Never rely on screenshots/blur: those fail under QEMU/virtio and leave a white screen.
set -euo pipefail

conf="${XDG_CONFIG_HOME:-$HOME/.config}/mango-titus/swaylock-effects.conf"
[[ -f "$conf" ]] || conf="${XDG_DATA_HOME:-$HOME/.local/share}/mango-titus/config/swaylock-effects.conf"
color="${SWAYLOCK_COLOR:-2e3440ff}"

# Prefer the effects build if named separately; Arch package usually installs as swaylock.
bin=""
if command -v swaylock-effects >/dev/null 2>&1; then
	bin=swaylock-effects
elif command -v swaylock >/dev/null 2>&1; then
	bin=swaylock
else
	echo "swaylock not found" >&2
	exit 1
fi

# Best-effort wake (ignore failures — mmsg needs a mango session env)
if [[ -x ${HOME}/.config/mango-titus/scripts/monitor-sleep.sh ]]; then
	"${HOME}/.config/mango-titus/scripts/monitor-sleep.sh" wake >/dev/null 2>&1 || true
fi

# Explicit args beat a stale config that still enables screenshots/blur.
args=(
	-f
	--color "$color"
	--ignore-empty-password
	--show-failed-attempts
	--indicator
	--indicator-idle-visible
	--clock
	--timestr '%H:%M'
	--datestr '%a, %b %d'
	--indicator-radius 100
	--indicator-thickness 10
	--ring-color 81a1c1ff
	--inside-color 3b4252ee
	--text-color eceff4ff
	--key-hl-color 88c0d0ff
	--line-color 00000000
)

if [[ -f "$conf" ]]; then
	args+=(-C "$conf")
fi

exec "$bin" "${args[@]}"
