pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: manager

    //
    // ALL MONITORS
    //

    readonly property var monitors: Quickshell.screens

    //
    // PRIMARY MONITOR
    //

    readonly property var primaryMonitor:
        monitors.length > 0
        ? monitors[0]
        : null

    //
    // HELPERS
    //

    function forEachMonitor(callback) {
        for (let i = 0; i < monitors.length; i++) {
            callback(monitors[i], i)
        }
    }

    function monitorByName(name) {
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].name === name)
                return monitors[i]
        }

        return null
    }
}
