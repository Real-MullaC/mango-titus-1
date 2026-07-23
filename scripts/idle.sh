#!/usr/bin/env bash
# Idle daemon — lock / optional monitor sleep from ~/.config/mango-titus/power.conf
# Defaults match dwm-titus caution: lock at 300s, no automatic monitor sleep.
set -euo pipefail

lock="${HOME}/.config/mango-titus/scripts/lock.sh"
monitor_sleep="${HOME}/.config/mango-titus/scripts/monitor-sleep.sh"
power_conf="${XDG_CONFIG_HOME:-$HOME/.config}/mango-titus/power.conf"
chmod +x "$lock" 2>/dev/null || true

dpms_enabled=0
dpms_timeout=600
lock_enabled=1
lock_timeout=300

if [[ -r $power_conf ]]; then
	while IFS='=' read -r key value || [[ -n $key ]]; do
		key=${key%%#*}
		key=${key//[[:space:]]/}
		[[ -z $key ]] && continue
		value=${value%%#*}
		value=${value#"${value%%[![:space:]]*}"}
		value=${value%"${value##*[![:space:]]}"}
		case $key in
		dpms_enabled)
			case ${value,,} in 1 | true | yes | on | enabled) dpms_enabled=1 ;; *) dpms_enabled=0 ;; esac
			;;
		dpms_timeout) [[ $value =~ ^[0-9]+$ ]] && ((value >= 60)) && dpms_timeout=$value ;;
		lock_enabled)
			case ${value,,} in 1 | true | yes | on | enabled) lock_enabled=1 ;; *) lock_enabled=0 ;; esac
			;;
		lock_timeout) [[ $value =~ ^[0-9]+$ ]] && ((value >= 60)) && lock_timeout=$value ;;
		esac
	done <"$power_conf"
fi

args=(-w)
if [[ $lock_enabled -eq 1 ]]; then
	args+=(timeout "$lock_timeout" "$lock")
fi
args+=(before-sleep "$lock")

if [[ $dpms_enabled -eq 1 && -x $monitor_sleep ]]; then
	args+=(
		timeout "$dpms_timeout" "$monitor_sleep sleep"
		resume "$monitor_sleep wake"
	)
fi

exec swayidle "${args[@]}"
