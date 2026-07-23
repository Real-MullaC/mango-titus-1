#!/usr/bin/env bash
# Start mate-polkit (dwm-titus 1:1), with common path fallbacks.
set -euo pipefail

for agent in \
	/usr/lib/mate-polkit/polkit-mate-authentication-agent-1 \
	/usr/libexec/polkit-mate-authentication-agent-1 \
	/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
	/usr/libexec/polkit-gnome-authentication-agent-1; do
	if [[ -x "$agent" ]]; then
		exec "$agent"
	fi
done

echo "no polkit agent found" >&2
exit 1
