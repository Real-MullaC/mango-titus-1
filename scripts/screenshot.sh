#!/usr/bin/env bash
# Flameshot wrapper for mangowm (Wayland portals).
# Usage: screenshot.sh {full|gui|clip}
set -euo pipefail

sync_activation_environment() {
	local -a activation_vars=()
	[[ -n "${WAYLAND_DISPLAY:-}" ]] && activation_vars+=(WAYLAND_DISPLAY)
	[[ -n "${DISPLAY:-}" ]] && activation_vars+=(DISPLAY)
	[[ -n "${XDG_SESSION_TYPE:-}" ]] && activation_vars+=(XDG_SESSION_TYPE)
	[[ -n "${XDG_CURRENT_DESKTOP:-}" ]] && activation_vars+=(XDG_CURRENT_DESKTOP)

	((${#activation_vars[@]})) || return 0
	if command -v systemctl >/dev/null 2>&1; then
		systemctl --user import-environment "${activation_vars[@]}" >/dev/null 2>&1 || true
	fi
	if command -v dbus-update-activation-environment >/dev/null 2>&1; then
		dbus-update-activation-environment --systemd \
			"${activation_vars[@]}" >/dev/null 2>&1 || true
	fi
}

if ! command -v flameshot >/dev/null 2>&1; then
	printf 'screenshot: flameshot is not installed\n' >&2
	exit 127
fi

sync_activation_environment

SCREENSHOT_DIR=""
if command -v xdg-user-dir >/dev/null 2>&1; then
	pictures_dir=$(xdg-user-dir PICTURES 2>/dev/null || true)
	[[ -z "$pictures_dir" ]] || SCREENSHOT_DIR="$pictures_dir/Screenshots"
fi
SCREENSHOT_DIR="${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
mkdir -p "$SCREENSHOT_DIR"

ACTION="${1:-gui}"
case "$ACTION" in
full) exec flameshot full -p "$SCREENSHOT_DIR" ;;
gui) exec flameshot gui -p "$SCREENSHOT_DIR" ;;
clip) exec flameshot gui --clipboard ;;
*)
	printf 'Usage: %s {full|gui|clip}\n' "$0" >&2
	exit 1
	;;
esac
