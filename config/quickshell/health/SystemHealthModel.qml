import Quickshell
import Quickshell.Io
import qs.core

Scope {
    id: root

    property bool visible: false
    property bool userRunning: false
    property bool systemRunning: false
    property bool repairRunning: false
    property bool shareRunning: false
    property bool repairSucceeded: false
    property bool confirming: false
    property bool showIssuesOnly: false
    // Suppress "cancelled scan → restricted" when closing/refreshing intentionally.
    property bool suppressScanCancel: false
    // True once privileged scan emits a terminal meta line (complete or restricted).
    // Prevents onRunningChanged from clobbering that reason with a generic cancel.
    property bool privilegedSettled: false
    // Bumped on each refresh so a killed privileged process cannot settle the next scan.
    property int systemScanEpoch: 0
    property int activeSystemScanEpoch: 0
    property string selectedCategory: "overview"
    property string coverageMessage: qsTr("Waiting for scan")
    property string repairMessage: ""
    property string repairError: ""
    property var rows: []
    property var pendingRepair: null
    property var targetScreen: null
    property var expandedIds: ({})
    // Optional elevated (pkexec) scan — off by default to avoid password prompts.
    property bool elevatedAvailable: true
    property bool elevatedDone: false

    readonly property bool busy: root.userRunning || root.systemRunning || root.repairRunning || root.shareRunning
    readonly property var categories: [
        { "id": "overview", "label": qsTr("Overview") },
        { "id": "boot", "label": qsTr("Boot & Kernel") },
        { "id": "services", "label": qsTr("Services") },
        { "id": "resources", "label": qsTr("Resources") },
        { "id": "storage", "label": qsTr("Storage") },
        { "id": "network", "label": qsTr("Network") },
        { "id": "desktop", "label": qsTr("Desktop") },
        { "id": "dependencies", "label": qsTr("Dependencies") }
    ]
    readonly property var visibleRows: root.rows.filter(function(row) {
        const issue = row.status === "error" || row.status === "warn" || row.status === "restricted";
        if (root.showIssuesOnly && !issue) {
            return false;
        }
        if (root.selectedCategory === "overview") {
            return row.category === "overview" || issue;
        }
        return row.category === root.selectedCategory;
    })

    // Single-pass tallies rebuilt when rows change — avoid O(n) per badge/chip binding.
    property int errorCount: 0
    property int warnCount: 0
    property int restrictedCount: 0
    property int okCount: 0
    property var categoryIssueCounts: ({})
    readonly property string overallLabelText: {
        if (root.errorCount > 0) {
            return qsTr("Critical");
        }
        if (root.warnCount > 0) {
            return qsTr("Needs Attention");
        }
        if (root.restrictedCount > 0 || root.systemRunning) {
            return qsTr("Scan Incomplete");
        }
        return root.rows.length > 0 ? qsTr("Healthy") : qsTr("Scanning");
    }

    function isExpanded(id) {
        return !!root.expandedIds[id];
    }

    function toggleExpanded(id) {
        const next = Object.assign({}, root.expandedIds);
        if (next[id]) {
            delete next[id];
        } else {
            next[id] = true;
        }
        root.expandedIds = next;
    }

    function openOnScreen(screen) {
        if (screen) {
            root.targetScreen = screen;
        }
        root.visible = true;
        root.refresh();
    }

    function open() {
        root.visible = true;
        root.refresh();
    }

    function close() {
        root.suppressScanCancel = true;
        userScanProcess.running = false;
        systemScanProcess.running = false;
        repairProcess.running = false;
        evidenceProcess.running = false;
        root.userRunning = false;
        root.systemRunning = false;
        root.visible = false;
        root.confirming = false;
        root.pendingRepair = null;
        root.suppressScanCancel = false;
    }

    function toggle() {
        if (root.visible) {
            root.close();
        } else {
            root.open();
        }
    }

    function refresh() {
        if (root.repairRunning || root.shareRunning) {
            return;
        }
        // User scan only — no pkexec/sudo prompt on open/Refresh.
        root.systemScanEpoch += 1;
        root.activeSystemScanEpoch = -1;
        root.suppressScanCancel = true;
        root.privilegedSettled = true;
        root.elevatedDone = false;
        userScanProcess.running = false;
        systemScanProcess.running = false;
        root.userRunning = false;
        root.systemRunning = false;
        root.rows = [];
        root.rebuildTallies();
        root.coverageMessage = qsTr("Scanning session...");
        root.repairMessage = "";
        root.repairError = "";
        root.repairSucceeded = false;
        const epoch = root.systemScanEpoch;
        Qt.callLater(function() {
            if (!root.visible || epoch !== root.systemScanEpoch) {
                root.suppressScanCancel = false;
                return;
            }
            root.suppressScanCancel = false;
            root.userRunning = true;
            userScanProcess.running = true;
        });
    }

    function refreshElevated() {
        if (root.busy || root.repairRunning || root.shareRunning) {
            return;
        }
        root.systemScanEpoch += 1;
        root.activeSystemScanEpoch = -1;
        root.suppressScanCancel = true;
        root.privilegedSettled = false;
        systemScanProcess.running = false;
        // Set before pkexec so fullscreen drops and the polkit dialog is visible.
        root.systemRunning = true;
        root.coverageMessage = qsTr("Waiting for polkit password dialog (may appear behind or beside this window)...");
        const epoch = root.systemScanEpoch;
        Qt.callLater(function() {
            if (!root.visible || epoch !== root.systemScanEpoch) {
                root.suppressScanCancel = false;
                root.systemRunning = false;
                return;
            }
            root.activeSystemScanEpoch = epoch;
            root.suppressScanCancel = false;
            systemScanProcess.running = true;
        });
    }

    function ingestLine(data) {
        const line = data.trim();
        if (line.length === 0) {
            return;
        }
        const fields = line.split("\t");
        if (fields.length < 10) {
            return;
        }
        const record = {
            "kind": fields[0],
            "category": fields[1],
            "status": fields[2],
            "id": fields[3],
            "title": fields[4],
            "summary": fields[5],
            "evidence": fields[6],
            "repairId": fields[7],
            "repairLabel": fields[8],
            "privilege": fields[9]
        };

        if (record.kind === "meta") {
            if (record.id === "scan-user-complete") {
                if (!root.systemRunning && !root.elevatedDone) {
                    root.coverageMessage = qsTr("Session scan complete");
                }
            } else if (record.id === "scan-system") {
                root.coverageMessage = record.status === "restricted" ? record.summary : qsTr("Elevated scan running...");
                if (record.status === "restricted") {
                    root.privilegedSettled = true;
                    root.markRestricted(record.summary, record.evidence);
                }
            } else if (record.id === "scan-system-skipped") {
                root.privilegedSettled = true;
                root.coverageMessage = record.summary;
                root.upsertRecord({
                    "kind": "check",
                    "category": "overview",
                    "status": "info",
                    "id": "privileged-coverage",
                    "title": qsTr("Elevated diagnostics"),
                    "summary": record.summary,
                    "evidence": record.evidence || qsTr("Optional root checks (SMART, system services) were not run"),
                    "repairId": "",
                    "repairLabel": "",
                    "privilege": "system"
                });
            } else if (record.id === "scan-system-complete") {
                root.privilegedSettled = true;
                root.elevatedDone = true;
                root.coverageMessage = qsTr("Elevated scan complete");
            }
            return;
        }
        if (record.kind !== "check") {
            return;
        }

        root.upsertRecord(record);
    }

    function upsertRecord(record) {
        const updated = root.rows.slice();
        let replaced = false;
        for (let i = 0; i < updated.length; i++) {
            if (updated[i].id === record.id) {
                updated[i] = record;
                replaced = true;
                break;
            }
        }
        if (!replaced) {
            updated.push(record);
        }
        root.rows = updated;
        root.rebuildTallies();
    }

    function rebuildTallies() {
        let errors = 0;
        let warns = 0;
        let restricted = 0;
        let ok = 0;
        const byCat = {};
        let overviewIssues = 0;

        for (let i = 0; i < root.rows.length; i++) {
            const row = root.rows[i];
            if (row.status === "error") {
                errors++;
            } else if (row.status === "warn") {
                warns++;
            } else if (row.status === "restricted") {
                restricted++;
            } else if (row.status === "ok") {
                ok++;
            }

            if (row.status === "error" || row.status === "warn" || row.status === "restricted") {
                overviewIssues++;
                byCat[row.category] = (byCat[row.category] || 0) + 1;
            }
        }

        byCat["overview"] = overviewIssues;
        root.errorCount = errors;
        root.warnCount = warns;
        root.restrictedCount = restricted;
        root.okCount = ok;
        root.categoryIssueCounts = byCat;
    }

    function markRestricted(summary, evidence) {
        root.upsertRecord({
            "kind": "check",
            "category": "overview",
            "status": "restricted",
            "id": "privileged-coverage",
            "title": qsTr("Privileged diagnostics"),
            "summary": summary,
            "evidence": evidence || qsTr("Current-boot journal, kernel, system service, and drive checks are incomplete"),
            "repairId": "",
            "repairLabel": "",
            "privilege": "system"
        });
    }

    function countStatus(status) {
        if (status === "error") {
            return root.errorCount;
        }
        if (status === "warn") {
            return root.warnCount;
        }
        if (status === "restricted") {
            return root.restrictedCount;
        }
        if (status === "ok") {
            return root.okCount;
        }
        return 0;
    }

    function categoryIssueCount(category) {
        return root.categoryIssueCounts[category] || 0;
    }

    function overallLabel() {
        return root.overallLabelText;
    }

    function requestRepair(row) {
        if (!row || row.repairId.length === 0 || root.busy) {
            return;
        }
        root.pendingRepair = row;
        root.confirming = true;
        root.repairError = "";
    }

    function requestServiceAction(row, action, label) {
        if (!row || root.busy) {
            return;
        }
        const parts = row.repairId.split("|");
        if (parts.length !== 2 || parts[0].indexOf("manage-") !== 0) {
            return;
        }
        root.pendingRepair = {
            "kind": row.kind,
            "category": row.category,
            "status": row.status,
            "id": row.id,
            "title": row.title,
            "summary": row.summary,
            "evidence": row.evidence,
            "repairId": parts[0] + "|" + action + "|" + parts[1],
            "repairLabel": qsTr("%1 %2").arg(label).arg(parts[1]),
            "privilege": row.privilege
        };
        root.confirming = true;
        root.repairError = "";
    }

    function shareEvidence(row, mode) {
        if (!row || root.busy || (row.id !== "journal-errors" && row.id !== "kernel-errors")) {
            return;
        }
        root.shareRunning = true;
        root.repairMessage = mode === "copy" ? qsTr("Copying diagnostics...") : qsTr("Exporting diagnostics...");
        root.repairError = "";
        evidenceProcess.command = Commands.systemHealthHelperCommand(
            "share-evidence",
            [mode, row.id, row.title, row.summary, row.evidence]
        );
        evidenceProcess.running = true;
    }

    function cancelRepair() {
        root.confirming = false;
        root.pendingRepair = null;
    }

    function repairImpact(id) {
        if (id.indexOf("manage-") === 0) {
            const parts = id.split("|");
            const action = parts.length > 1 ? parts[1] : "change";
            const unit = parts.length > 2 ? parts[2] : qsTr("this service");
            if (action === "enable") {
                return qsTr("%1 will be enabled for future starts. It will not be started now.").arg(unit);
            }
            if (action === "disable") {
                return qsTr("%1 will be disabled for future starts. It will not be stopped now.").arg(unit);
            }
            if (action === "stop") {
                return qsTr("%1 will be stopped for the current session.").arg(unit);
            }
            if (action === "restart") {
                return qsTr("%1 will be stopped and started again.").arg(unit);
            }
            return qsTr("%1 will be started now.").arg(unit);
        }
        if (id === "restart-networkmanager") {
            return qsTr("Network connectivity will drop briefly while NetworkManager restarts.");
        }
        if (id === "restart-bluetooth") {
            return qsTr("Connected Bluetooth devices will disconnect briefly.");
        }
        if (id === "repair-time-sync") {
            return qsTr("The detected time synchronization provider will be enabled and restarted.");
        }
        if (id === "restart-quickshell") {
            return qsTr("Quickshell will restart and this dashboard will close.");
        }
        if (id === "install-dependencies") {
            return qsTr("The interactive dependency installer or detailed dependency check will open in a terminal.");
        }
        return qsTr("The affected desktop component will be restarted.");
    }

    function confirmRepair() {
        if (!root.pendingRepair || root.repairRunning) {
            return;
        }
        const row = root.pendingRepair;
        root.confirming = false;
        root.pendingRepair = null;
        root.repairRunning = true;
        root.repairSucceeded = false;
        root.repairMessage = qsTr("Running %1...").arg(row.repairLabel);
        root.repairError = "";
        repairProcess.command = Commands.systemHealthHelperCommand(
            row.privilege === "system" ? "repair-privileged" : "repair-user",
            [row.repairId]
        );
        repairProcess.running = true;
    }

    Process {
        id: userScanProcess

        command: Commands.systemHealthHelperCommand("scan-user")
        running: false
        onRunningChanged: {
            if (!running && root.userRunning) {
                root.userRunning = false;
            }
        }

        stdout: SplitParser {
            onRead: function(data) {
                root.ingestLine(data);
            }
        }
    }

    Process {
        id: systemScanProcess

        command: Commands.systemHealthHelperCommand("scan-privileged")
        running: false
        onRunningChanged: {
            if (!running && root.systemRunning && root.activeSystemScanEpoch === root.systemScanEpoch) {
                root.systemRunning = false;
            }
            if (!running
                    && root.activeSystemScanEpoch === root.systemScanEpoch
                    && !root.suppressScanCancel
                    && !root.privilegedSettled) {
                root.privilegedSettled = true;
                root.coverageMessage = qsTr("Privileged scan was cancelled or unavailable");
                root.markRestricted(root.coverageMessage, qsTr("Use Refresh to retry authorization"));
            }
        }

        stdout: SplitParser {
            onRead: function(data) {
                if (root.activeSystemScanEpoch !== root.systemScanEpoch) {
                    return;
                }
                root.ingestLine(data);
            }
        }
    }

    Process {
        id: evidenceProcess

        command: ["sh", "-c", "exit 0"]
        running: false
        onRunningChanged: {
            if (!running && root.shareRunning) {
                root.shareRunning = false;
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const message = this.text.trim();
                if (message.length > 0) {
                    root.repairMessage = message;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = this.text.trim();
                root.repairError = message;
                if (message.length > 0) {
                    root.repairMessage = message;
                }
            }
        }
    }

    Process {
        id: repairProcess

        command: ["sh", "-c", "exit 0"]
        running: false
        onRunningChanged: {
            if (!running && root.repairRunning) {
                root.repairRunning = false;
                if (root.repairSucceeded) {
                    root.repairMessage = qsTr("Repair completed; rescanning...");
                    Qt.callLater(root.refresh);
                } else {
                    root.repairMessage = root.repairError.length > 0 ? root.repairError : qsTr("Repair failed");
                }
            }
        }

        stdout: SplitParser {
            onRead: function(data) {
                if (data.indexOf("repair\t") === 0) {
                    root.repairSucceeded = true;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: root.repairError = this.text.trim()
        }
    }
}
