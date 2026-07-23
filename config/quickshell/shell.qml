//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import qs.controlcenter
import qs.controls
import qs.health
import qs.launcher
import qs.network
import qs.notifications
import qs.panel
import qs.power
import qs.state

pragma ComponentBehavior: Bound

ShellRoot {
    id: root

    DwmState {
        id: dwmState
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    LauncherModel {
        id: launcherModel
    }

    PowerMenuModel {
        id: powerMenuModel
    }

    NetworkModel {
        id: networkModel
    }

    ControlsModel {
        id: controlsModel
    }

    BluetoothModel {
        id: bluetoothModel
    }

    ControlCenterModel {
        id: controlCenterModel
    }

    SystemHealthModel {
        id: systemHealthModel
    }

    NotificationModel {
        id: notificationModel
    }

    Component.onCompleted: {
        networkModel.refresh();
        controlsModel.refresh();
    }

    IpcHandler {
        target: "launcher"

        function close(): void {
            launcherModel.close();
        }

        function open(): void {
            launcherModel.open();
        }

        function toggle(): void {
            launcherModel.toggle();
        }
    }

    IpcHandler {
        target: "power"

        function close(): void {
            powerMenuModel.close();
        }

        function open(): void {
            powerMenuModel.open();
        }

        function toggle(): void {
            powerMenuModel.toggle();
        }
    }

    IpcHandler {
        target: "network"

        function close(): void {
            networkModel.close();
        }

        function open(): void {
            networkModel.open();
        }

        function refresh(): void {
            networkModel.refresh();
        }

        function status(): string {
            return networkModel.statusText;
        }

        function toggle(): void {
            networkModel.toggle();
        }
    }

    IpcHandler {
        target: "controls"

        function close(): void {
            controlsModel.close();
        }

        function bluetoothStatus(): string {
            return controlsModel.bluetoothText;
        }

        function open(): void {
            controlsModel.open();
        }

        function refresh(): void {
            controlsModel.refresh();
        }

        function micStatus(): string {
            return controlsModel.micText;
        }

        function mediaStatus(): string {
            return controlsModel.mediaText;
        }

        function mediaNext(): void {
            controlsModel.mediaNext();
        }

        function mediaPlayPause(): void {
            controlsModel.mediaPlayPause();
        }

        function mediaPrevious(): void {
            controlsModel.mediaPrevious();
        }

        function toggle(): void {
            controlsModel.toggle();
        }

        function volumeDown(): void {
            controlsModel.volumeDown();
        }

        function volumeStatus(): string {
            return controlsModel.volumeDisplayText;
        }

        function volumeSet(percent: int): void {
            controlsModel.volumeSet(percent);
        }

        function volumeToggleMute(): void {
            controlsModel.volumeToggleMute();
        }

        function volumeUp(): void {
            controlsModel.volumeUp();
        }
    }

    IpcHandler {
        target: "notifications"

        function clear(): void {
            notificationModel.clear();
        }

        function count(): int {
            return notificationModel.notifications.length;
        }

        function clearHistory(): void {
            notificationModel.clearHistory();
        }

        function closeHistory(): void {
            notificationModel.closeHistory();
        }

        function historyCount(): int {
            return notificationModel.history.length;
        }

        function historyLatestSummary(): string {
            return notificationModel.historyLatestSummary();
        }

        function openHistory(): void {
            notificationModel.openHistory();
        }

        function toggleHistory(): void {
            notificationModel.toggleHistory();
        }
    }

    IpcHandler {
        target: "controlcenter"

        function close(): void {
            controlCenterModel.close();
        }

        function open(): void {
            controlCenterModel.open();
        }

        function openKeybinds(): void {
            controlCenterModel.openKeybinds();
        }

        function refresh(): void {
            controlCenterModel.refresh();
        }

        function toggle(): void {
            controlCenterModel.toggle();
        }
    }

    IpcHandler {
        target: "systemhealth"

        function close(): void {
            systemHealthModel.close();
        }

        function open(): void {
            systemHealthModel.openOnScreen(panelWindow.screen);
        }

        function refresh(): void {
            systemHealthModel.refresh();
        }

        function toggle(): void {
            if (systemHealthModel.visible) {
                systemHealthModel.close();
            } else {
                systemHealthModel.openOnScreen(panelWindow.screen);
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

    DwmPanel {
        id: panelWindow

        state: dwmState
        clock: clock
        networkModel: networkModel
        controlsModel: controlsModel
        bluetoothModel: bluetoothModel
        controlCenterModel: controlCenterModel
        powerMenuModel: powerMenuModel
    }

    // Keep toasts eager so the first notification is not delayed by Loader.
    NotificationPopupWindow {
        notificationModel: notificationModel
        panelWindow: panelWindow
    }

    LazyLoader {
        active: launcherModel.visible

        component: LauncherWindow {
            launcherModel: launcherModel
        }
    }

    LazyLoader {
        active: powerMenuModel.visible

        component: PowerMenuWindow {
            powerMenuModel: powerMenuModel
            panelWindow: panelWindow
        }
    }

    LazyLoader {
        active: networkModel.visible

        component: NetworkWindow {
            networkModel: networkModel
            panelWindow: panelWindow
        }
    }

    LazyLoader {
        active: notificationModel.historyVisible

        component: NotificationHistoryWindow {
            notificationModel: notificationModel
        }
    }

    LazyLoader {
        active: controlsModel.visible

        component: ControlsWindow {
            controlsModel: controlsModel
            panelWindow: panelWindow
        }
    }

    LazyLoader {
        active: bluetoothModel.visible

        component: BluetoothWindow {
            bluetoothModel: bluetoothModel
            panelWindow: panelWindow
        }
    }

    LazyLoader {
        active: controlCenterModel.visible

        component: ControlCenterWindow {
            controlCenterModel: controlCenterModel
            panelWindow: panelWindow
            powerMenuModel: powerMenuModel
            healthModel: systemHealthModel
        }
    }

    LazyLoader {
        active: controlCenterModel.utilityVisible

        component: UtilityDetailWindow {
            controlCenterModel: controlCenterModel
        }
    }

    LazyLoader {
        active: systemHealthModel.visible

        component: SystemHealthWindow {
            healthModel: systemHealthModel
            screen: systemHealthModel.targetScreen ? systemHealthModel.targetScreen : panelWindow.screen
        }
    }
}
