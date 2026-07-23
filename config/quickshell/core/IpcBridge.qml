import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import qs.controlcenter
import qs.controls
import qs.health
import qs.launcher
import qs.network
import qs.notifications
import qs.power

Scope {
    id: root

    required property LauncherModel launcherModel
    required property PowerMenuModel powerMenuModel
    required property NetworkModel networkModel
    required property ControlsModel controlsModel
    required property NotificationModel notificationModel
    required property ControlCenterModel controlCenterModel
    required property SystemHealthModel systemHealthModel
    required property PanelWindow panelWindow

    IpcHandler {
        target: "launcher"

        function close(): void {
            root.launcherModel.close();
        }

        function open(): void {
            root.launcherModel.open();
        }

        function toggle(): void {
            root.launcherModel.toggle();
        }
    }

    IpcHandler {
        target: "power"

        function close(): void {
            root.powerMenuModel.close();
        }

        function open(): void {
            root.powerMenuModel.open();
        }

        function toggle(): void {
            root.powerMenuModel.toggle();
        }
    }

    IpcHandler {
        target: "network"

        function close(): void {
            root.networkModel.close();
        }

        function open(): void {
            root.networkModel.open();
        }

        function refresh(): void {
            root.networkModel.refresh();
        }

        function status(): string {
            return root.networkModel.statusText;
        }

        function toggle(): void {
            root.networkModel.toggle();
        }
    }

    IpcHandler {
        target: "controls"

        function close(): void {
            root.controlsModel.close();
        }

        function bluetoothStatus(): string {
            return root.controlsModel.bluetoothText;
        }

        function open(): void {
            root.controlsModel.open();
        }

        function refresh(): void {
            root.controlsModel.refresh();
        }

        function micStatus(): string {
            return root.controlsModel.micText;
        }

        function mediaStatus(): string {
            return root.controlsModel.mediaText;
        }

        function mediaNext(): void {
            root.controlsModel.mediaNext();
        }

        function mediaPlayPause(): void {
            root.controlsModel.mediaPlayPause();
        }

        function mediaPrevious(): void {
            root.controlsModel.mediaPrevious();
        }

        function toggle(): void {
            root.controlsModel.toggle();
        }

        function volumeDown(): void {
            root.controlsModel.volumeDown();
        }

        function volumeStatus(): string {
            return root.controlsModel.volumeDisplayText;
        }

        function volumeSet(percent: int): void {
            root.controlsModel.volumeSet(percent);
        }

        function volumeToggleMute(): void {
            root.controlsModel.volumeToggleMute();
        }

        function volumeUp(): void {
            root.controlsModel.volumeUp();
        }
    }

    IpcHandler {
        target: "notifications"

        function clear(): void {
            root.notificationModel.clear();
        }

        function count(): int {
            return root.notificationModel.notifications.length;
        }

        function clearHistory(): void {
            root.notificationModel.clearHistory();
        }

        function closeHistory(): void {
            root.notificationModel.closeHistory();
        }

        function historyCount(): int {
            return root.notificationModel.history.length;
        }

        function historyLatestSummary(): string {
            return root.notificationModel.historyLatestSummary();
        }

        function openHistory(): void {
            root.notificationModel.openHistory();
        }

        function toggleHistory(): void {
            root.notificationModel.toggleHistory();
        }
    }

    IpcHandler {
        target: "controlcenter"

        function close(): void {
            root.controlCenterModel.close();
        }

        function open(): void {
            root.controlCenterModel.open();
        }

        function openKeybinds(): void {
            root.controlCenterModel.openKeybinds();
        }

        function refresh(): void {
            root.controlCenterModel.refresh();
        }

        function toggle(): void {
            root.controlCenterModel.toggle();
        }
    }

    IpcHandler {
        target: "systemhealth"

        function close(): void {
            root.systemHealthModel.close();
        }

        function open(): void {
            root.systemHealthModel.openOnScreen(root.panelWindow.screen);
        }

        function refresh(): void {
            root.systemHealthModel.refresh();
        }

        function toggle(): void {
            if (root.systemHealthModel.visible) {
                root.systemHealthModel.close();
            } else {
                root.systemHealthModel.openOnScreen(root.panelWindow.screen);
            }
        }
    }

    IpcHandler {
        target: "tray"

        function count(): int {
            return SystemTray.items.values.length;
        }

        function ids(): string {
            const items = SystemTray.items.values;
            const ids = [];

            for (let i = 0; i < items.length; i++) {
                ids.push(items[i].id || items[i].title || items[i].tooltipTitle || "unknown");
            }

            return ids.join("\n");
        }

        function details(): string {
            const items = SystemTray.items.values;
            const rows = [];

            for (let i = 0; i < items.length; i++) {
                const item = items[i];
                rows.push([
                    item.id || "unknown",
                    item.title || "",
                    item.icon || "",
                    item.hasMenu ? "menu" : "no-menu",
                    item.status || ""
                ].join("\t"));
            }

            return rows.join("\n");
        }
    }
}
