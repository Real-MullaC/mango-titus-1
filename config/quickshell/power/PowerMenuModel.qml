import Quickshell
import qs.core

Scope {
    id: root

    property bool visible: false
    property bool confirming: false
    property var pendingAction: null
    property string status: ""

    readonly property var sessionActions: [
        {
            "id": "reboot",
            "label": "Reboot",
            "detail": "Restart this system",
            // qs is often outside the seat session; mango-titus-power spawns via
            // mmsg so systemctl runs as a mango child (polkit allow_active=yes).
            "command": Commands.powerHelperCommand("reboot"),
            "confirm": true
        },
        {
            "id": "logout",
            "label": "Log Out",
            "detail": "End the current session",
            // Do not trust qs XDG_SESSION_ID (often a tty/ssh session). Prefer the
            // user's seat-backed graphical session; fall back to killing mangowm.
            "command": ["sh", "-c", "sid=$(loginctl list-sessions --no-legend 2>/dev/null | awk -v u=\"${USER:-}\" '$3==u && $4!=\"-\" { print $1; exit }'); if [ -n \"$sid\" ]; then exec loginctl terminate-session \"$sid\"; fi; exec pkill -TERM -x mango"],
            "confirm": true
        },
        {
            "id": "lock",
            "label": "Lock",
            "detail": "Secure this session",
            "command": Commands.lockHelperCommand(),
            "confirm": false
        },
        {
            "id": "shutdown",
            "label": "Shutdown",
            "detail": "Power off this system",
            "command": Commands.powerHelperCommand("poweroff"),
            "confirm": true
        }
    ]

    function open() {
        root.visible = true;
        root.confirming = false;
        root.pendingAction = null;
        root.status = "";
    }

    function close() {
        root.visible = false;
        root.confirming = false;
        root.pendingAction = null;
        root.status = "";
    }

    function toggle() {
        if (root.visible) {
            root.close();
        } else {
            root.open();
        }
    }

    function requestAction(action) {
        if (!action) {
            return;
        }

        if (action.confirm) {
            root.pendingAction = action;
            root.confirming = true;
            root.status = "";
            return;
        }

        root.runAction(action);
    }

    function cancelConfirmation() {
        root.confirming = false;
        root.pendingAction = null;
        root.status = "";
    }

    function confirmAction() {
        if (!root.pendingAction) {
            root.cancelConfirmation();
            return;
        }

        root.runAction(root.pendingAction);
    }

    function runAction(action) {
        if (!action || !action.command || action.command.length === 0) {
            return;
        }

        // Detached so closing the menu cannot cancel poweroff/reboot.
        Quickshell.execDetached(action.command);
        root.close();
    }
}
