import Quickshell
import Quickshell.Io
import qs.core

Scope {
    id: root

    property bool visible: false
    property bool busy: false
    property string page: "overview"
    property bool utilityVisible: false
    property string utilityPage: ""
    property bool showVolumeWidget: true
    property bool showBluetoothWidget: true
    property bool showNetworkWidget: true
    property bool showPowerWidget: true
    property bool showWorkspaceWidget: true
    property string message: ""
    property var infoRows: []
    property var themeRows: []
    property var keybindRows: []
    readonly property var actions: [
        { "id": "restart-quickshell", "label": "Restart Quickshell" },
        { "id": "reload-wallpaper", "label": "Reload Wallpaper" },
        { "id": "restart-networkmanager", "label": "Restart NetworkManager" },
        { "id": "dependency-check", "label": "Dependency Check" },
        { "id": "install-missing-deps", "label": "Install Missing Deps" },
        { "id": "open-wallpapers", "label": "Wallpaper Folder" },
        { "id": "gtk-settings", "label": "GTK Settings" }
    ]
    property var powerRows: []
    property bool powerDpmsAvailable: false
    property bool powerDpmsEnabled: false
    property int powerDpmsTimeout: 600
    property bool powerLockAvailable: false
    property bool powerLockEnabled: false
    property bool powerLockRunning: false
    property int powerLockTimeout: 300
    property string powerConfigFile: ""
    readonly property var powerPresets: [
        { "label": "5m", "seconds": 300 },
        { "label": "10m", "seconds": 600 },
        { "label": "15m", "seconds": 900 },
        { "label": "30m", "seconds": 1800 },
        { "label": "1h", "seconds": 3600 }
    ]

    function openPage(name, message, process) {
        root.page = name;
        root.message = message;
        if (process && !process.running) {
            process.running = true;
        }
    }

    function open() {
        root.visible = true;
        root.openOverview();
    }

    function close() {
        root.closeUtility();
        root.dismissMenu();
        root.busy = false;
    }

    // Hide the control-center popup only. Utility detail windows stay open.
    function dismissMenu() {
        root.visible = false;
    }

    function closeUtility() {
        root.utilityVisible = false;
        root.utilityPage = "";
        // Drop utility page so refresh/actions cannot resurrect the window.
        if (root.page === "appearance" || root.page === "keybinds"
                || root.page === "power" || root.page === "info") {
            root.page = "overview";
        }
        root.message = "";
        root.busy = false;
        themeSetProcess.running = false;
        powerActionProcess.running = false;
    }

    function widgetEnabled(name) {
        if (name === "Volume") return root.showVolumeWidget;
        if (name === "Bluetooth") return root.showBluetoothWidget;
        if (name === "Network") return root.showNetworkWidget;
        if (name === "Power") return root.showPowerWidget;
        return root.showWorkspaceWidget;
    }

    function toggleWidget(name) {
        if (name === "Volume") root.showVolumeWidget = !root.showVolumeWidget;
        else if (name === "Bluetooth") root.showBluetoothWidget = !root.showBluetoothWidget;
        else if (name === "Network") root.showNetworkWidget = !root.showNetworkWidget;
        else if (name === "Power") root.showPowerWidget = !root.showPowerWidget;
        else if (name === "Workspaces") root.showWorkspaceWidget = !root.showWorkspaceWidget;
    }

    function toggle() {
        // Menu and utility are separate surfaces; treat either as "open".
        if (root.visible || root.utilityVisible) {
            root.close();
        } else {
            root.open();
        }
    }

    function refresh() {
        root.refreshCurrentPage();
    }

    function openOverview() {
        root.openPage("overview", "", null);
    }

    function openActions() {
        root.openPage("actions", "", null);
    }

    function openAppearance() {
        root.utilityPage = "appearance";
        root.utilityVisible = true;
        root.dismissMenu();
        root.message = "Loading themes...";
        root.page = "appearance";
        // Force a fresh helper run (Quickshell Process won't restart if already "running")
        if (themesProcess.running) {
            themesProcess.running = false;
        }
        themesProcess.command = Commands.controlCenterHelperCommand("themes");
        themesProcess.running = true;
    }

    function openKeybinds() {
        root.utilityPage = "keybinds";
        root.utilityVisible = true;
        root.dismissMenu();
        root.openPage("keybinds", "Loading keybinds...", keybindsProcess);
    }

    function openPower() {
        root.utilityPage = "power";
        root.utilityVisible = true;
        root.dismissMenu();
        root.message = "Loading power settings...";
        root.page = "power";
        if (powerStatusProcess.running) {
            powerStatusProcess.running = false;
        }
        powerStatusProcess.command = Commands.controlCenterHelperCommand("power-status");
        powerStatusProcess.running = true;
    }

    function formatDuration(seconds) {
        if (seconds >= 3600 && seconds % 3600 === 0) {
            return (seconds / 3600) + "h";
        }
        if (seconds >= 60 && seconds % 60 === 0) {
            return (seconds / 60) + "m";
        }
        return seconds + "s";
    }

    function openInfo() {
        root.utilityPage = "info";
        root.utilityVisible = true;
        root.dismissMenu();
        root.openPage("info", "Loading system info...", infoProcess);
    }

    function refreshCurrentPage() {
        // Only reload an already-visible utility; never reopen after dismiss.
        if (!root.utilityVisible) {
            return;
        }
        if (root.page === "appearance") {
            root.openAppearance();
        } else if (root.page === "keybinds") {
            root.openKeybinds();
        } else if (root.page === "power") {
            root.openPower();
        } else if (root.page === "info") {
            root.openInfo();
        }
    }

    function parseRows(text, names) {
        const rows = [];
        const lines = text.trim().split("\n");

        for (let i = 0; i < lines.length; i++) {
            if (lines[i].trim().length === 0) {
                continue;
            }

            const fields = lines[i].split("\t");
            const row = {};
            for (let f = 0; f < names.length; f++) {
                row[names[f]] = fields.length > f ? fields[f] : "";
            }
            rows.push(row);
        }

        return rows;
    }

    function rowValue(rows, key, fallback) {
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].key === key) {
                return rows[i].value;
            }
        }

        return fallback;
    }

    function boolValue(value) {
        return value === "1" || value === "true" || value === "yes" || value === "enabled";
    }

    function intValue(value, fallback) {
        const parsed = parseInt(value, 10);
        return isNaN(parsed) ? fallback : parsed;
    }

    function applyPowerRows(rows) {
        root.powerRows = rows;
        root.powerDpmsAvailable = root.boolValue(root.rowValue(rows, "dpms_available", "0"));
        root.powerDpmsEnabled = root.boolValue(root.rowValue(rows, "dpms_enabled", "0"));
        root.powerDpmsTimeout = root.intValue(root.rowValue(rows, "dpms_timeout", "600"), 600);
        root.powerLockAvailable = root.boolValue(root.rowValue(rows, "lock_available", "0"));
        root.powerLockEnabled = root.boolValue(root.rowValue(rows, "lock_enabled", "0"));
        root.powerLockRunning = root.boolValue(root.rowValue(rows, "lock_running", "0"));
        root.powerLockTimeout = root.intValue(root.rowValue(rows, "lock_timeout", "600"), 600);
        root.powerConfigFile = root.rowValue(rows, "config_file", "");
    }

    function runAction(action) {
        if (root.busy) {
            return;
        }

        root.busy = true;
        root.message = "Running " + action + "...";
        // Hide the control popup so a polkit/terminal dialog is not covered.
        root.dismissMenu();
        actionProcess.command = Commands.controlCenterHelperCommand("action", [action]);
        actionProcess.running = true;
    }

    function setTheme(name) {
        if (root.busy) {
            return;
        }

        root.busy = true;
        root.message = "Applying " + name + "...";
        themeSetProcess.command = Commands.controlCenterHelperCommand("theme-set", [name]);
        themeSetProcess.running = true;
    }

    function runPowerAction(action, args) {
        if (root.busy) {
            return;
        }

        root.busy = true;
        root.message = "Updating power settings...";
        powerActionProcess.command = Commands.controlCenterHelperCommand(action, args || []);
        powerActionProcess.running = true;
    }

    function setPowerDpms(enabled) {
        root.runPowerAction("power-dpms", [enabled ? "on" : "off"]);
    }

    function setPowerDpmsTimeout(seconds) {
        root.runPowerAction("power-dpms-timeout", [seconds.toString()]);
    }

    function setPowerLock(enabled) {
        root.runPowerAction("power-lock", [enabled ? "on" : "off"]);
    }

    function setPowerLockTimeout(seconds) {
        root.runPowerAction("power-lock-timeout", [seconds.toString()]);
    }

    Process {
        id: infoProcess

        command: Commands.controlCenterHelperCommand("info")
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.infoRows = root.parseRows(this.text, ["label", "value"]);
                root.message = "";
            }
        }
    }

    Process {
        id: themesProcess

        command: Commands.controlCenterHelperCommand("themes")
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.themeRows = root.parseRows(this.text, ["status", "name"]);
                root.message = root.themeRows.length + " themes";
            }
        }
    }

    Process {
        id: keybindsProcess

        command: Commands.controlCenterHelperCommand("keybinds")
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.keybindRows = root.parseRows(this.text, ["keys", "description"]);
                root.message = root.keybindRows.length + " keybinds";
            }
        }
    }

    Process {
        id: powerStatusProcess

        command: Commands.controlCenterHelperCommand("power-status")
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const rows = root.parseRows(this.text, ["key", "value"]);
                root.applyPowerRows(rows);
                root.message = "";
            }
        }
    }

    Process {
        id: actionProcess

        command: ["sh", "-c", "exit 0"]
        running: false

        onRunningChanged: {
            if (!running && root.busy) {
                root.busy = false;
                root.message = "Action dispatched";
                root.refreshCurrentPage();
            }
        }
    }

    Process {
        id: themeSetProcess

        command: ["sh", "-c", "exit 0"]
        running: false

        onRunningChanged: {
            if (!running && root.busy) {
                root.busy = false;
                root.message = "Theme applied";
                // Do not reopen utility if the user already dismissed it.
                if (root.utilityVisible && root.utilityPage === "appearance") {
                    if (!themesProcess.running) {
                        themesProcess.running = true;
                    }
                }
            }
        }
    }

    Process {
        id: powerActionProcess

        command: ["sh", "-c", "exit 0"]
        running: false

        onRunningChanged: {
            if (!running && root.busy) {
                root.busy = false;
                root.message = "Power settings updated";
                if (root.utilityVisible && root.utilityPage === "power") {
                    if (!powerStatusProcess.running) {
                        powerStatusProcess.running = true;
                    }
                }
            }
        }
    }
}
