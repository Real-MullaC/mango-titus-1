import Quickshell
import Quickshell.Io
import qs.core

Scope {
    id: root

    property int currentWorkspace: 0
    property var workspaceNames: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
    property string activeWindowTitle: "Desktop"
    property string statusText: ""
    property var statusSegments: []

    function parseState(text) {
        const lines = text.trim().split("\n");

        for (const line of lines) {
            const separator = line.indexOf("=");

            if (separator < 0) {
                continue;
            }

            const key = line.slice(0, separator);
            const value = line.slice(separator + 1);

            if (key === "current") {
                // mango-titus-state emits a 0-based workspace index.
                const parsed = parseInt(value, 10);

                root.currentWorkspace = isNaN(parsed) ? 0 : Math.max(0, parsed);
            } else if (key === "names") {
                root.workspaceNames = value.length > 0 ? value.split("|") : [];
            } else if (key === "title") {
                // Ignore IPC/helper JSON errors (e.g. {"error":"unknown command"}).
                const bad = value.length === 0 || value.indexOf("{\"error\"") === 0;

                root.activeWindowTitle = bad ? "Desktop" : value;
            } else if (key === "status") {
                root.statusText = value;
                root.updateStatusSegments();
            }
        }
    }

    function updateStatusSegments() {
        const text = root.statusText.trim();

        if (text.length === 0 || text.indexOf("dwm-titus:") === 0) {
            root.statusSegments = [];
            return;
        }

        root.statusSegments = text.split(/\s+\|\s+| {2,}/).filter(function(segment) {
            const trimmed = segment.trim();

            return trimmed.length > 0 && trimmed.indexOf("NET ") !== 0 && trimmed.indexOf("VOL ") !== 0;
        });
    }

    function switchWorkspace(index) {
        switchWorkspaceProcess.command = Commands.stateHelperCommand("switch", [index.toString()]);
        switchWorkspaceProcess.running = true;
    }

    Process {
        command: Commands.stateHelperCommand("watch")
        running: true

        stdout: SplitParser {
            splitMarker: "\n\n"
            onRead: function(data) {
                root.parseState(data);
            }
        }
    }

    Process {
        id: switchWorkspaceProcess

        command: Commands.stateHelperCommand("switch", ["0"])
        running: false
    }
}
