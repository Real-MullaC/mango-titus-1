//@ pragma UseQApplication
//@ pragma ShellId mango-titus
//@ pragma AppId mango-titus

import QtQuick
import Quickshell
import qs.controlcenter
import qs.controls
import qs.core
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

    WmState {
        id: wmState
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

    Bar {
        id: panelWindow

        state: wmState
        clock: clock
        networkModel: networkModel
        controlsModel: controlsModel
        bluetoothModel: bluetoothModel
        controlCenterModel: controlCenterModel
        powerMenuModel: powerMenuModel
    }

    IpcBridge {
        launcherModel: launcherModel
        powerMenuModel: powerMenuModel
        networkModel: networkModel
        controlsModel: controlsModel
        notificationModel: notificationModel
        controlCenterModel: controlCenterModel
        systemHealthModel: systemHealthModel
        panelWindow: panelWindow
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
