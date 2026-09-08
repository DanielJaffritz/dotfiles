pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property int temperature: 4500  // Kelvin nocturno

    readonly property string icon: enabled ? "󰖔" : "󰖙"
    readonly property string display: enabled ? (icon + " Noche") : (icon + " Día")

    function refresh() {
        checkProc.running = true;
    }

    function toggle() {
        setEnabled(!enabled);
    }

    function setEnabled(on) {
        if (on) {
            // Matar instancia previa y lanzar gammastep con temperatura fija
            actionProc.command = ["sh", "-c",
                "pkill -x gammastep 2>/dev/null; " +
                "gammastep -O " + root.temperature + " >/dev/null 2>&1 &"
            ];
        } else {
            actionProc.command = ["sh", "-c",
                "pkill -x gammastep 2>/dev/null; " +
                "gammastep -x >/dev/null 2>&1 & sleep 0.3; pkill -x gammastep 2>/dev/null; true"
            ];
        }
        actionProc.running = true;
        enabled = on; // optimistic
    }

    Process {
        id: checkProc
        command: ["sh", "-c", "pgrep -x gammastep >/dev/null && echo on || echo off"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.enabled = text.trim() === "on";
            }
        }
    }

    Process {
        id: actionProc
        running: false
        onExited: Qt.callLater(() => checkProc.running = true)
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkProc.running = true
    }
}

