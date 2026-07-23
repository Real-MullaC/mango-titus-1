#!/usr/bin/env bash
# Run XDG autostart after Quickshell tray host is ready (dwm-titus ordering).
set -euo pipefail

qs_config="${XDG_CONFIG_HOME:-$HOME/.config}/mango-titus/quickshell/shell.qml"

if [[ -f "$qs_config" ]] && command -v quickshell >/dev/null 2>&1; then
	i=0
	while ((i < 50)); do
		if quickshell ipc --path "$qs_config" call tray count >/dev/null 2>&1; then
			break
		fi
		i=$((i + 1))
		sleep 0.1
	done
else
	sleep 1
fi

if command -v dex >/dev/null 2>&1; then
	exec dex -a
elif command -v dex-autostart >/dev/null 2>&1; then
	exec dex-autostart -a
fi

exit 0
