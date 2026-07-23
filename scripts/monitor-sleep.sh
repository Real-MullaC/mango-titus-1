#!/usr/bin/env bash
# Opt-in monitor power via mmsg (not used by default idle policy).
# Usage: monitor-sleep.sh {sleep|wake|toggle} [OUTPUT]
set -euo pipefail

action=${1:-}
output=${2:-}

if ! command -v mmsg >/dev/null 2>&1; then
	echo "mmsg not found (is mangowm running?)" >&2
	exit 1
fi

if [[ -z "$output" ]]; then
	output=$(wlr-randr 2>/dev/null | awk '/^[^ ]/ { print $1; exit }')
fi
[[ -n "$output" ]] || {
	echo "no output specified/detected" >&2
	exit 1
}

case "$action" in
sleep) mmsg dispatch "sleep_monitor,$output" ;;
wake) mmsg dispatch "wakeup_monitor,$output" ;;
toggle) mmsg dispatch "sleep_toggle_monitor,$output" ;;
*)
	echo "Usage: $0 {sleep|wake|toggle} [OUTPUT]" >&2
	exit 1
	;;
esac
