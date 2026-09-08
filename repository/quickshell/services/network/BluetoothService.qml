pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool powered: false
    property bool discovering: false
    property int connectedCount: 0
    property string connectedName: ""
    property var devices: []       // paired + connected visible
    property var discovered: []    // scan results [{name, mac, connected, paired}]
    property string busyMac: ""

    readonly property string icon: {
        if (!powered)
            return "󰂲";
        if (connectedCount > 0)
            return "󰂱";
        return "󰂯";
    }

    readonly property string display: {
        if (!powered)
            return icon + " Off";
        if (connectedCount > 0)
            return icon + " " + (connectedName || (connectedCount + " disp."));
        return icon + " On";
    }

    // Lista combinada para la UI (conectados primero)
    readonly property var allDevices: {
        const map = {};
        for (const d of devices) {
            map[d.mac] = Object.assign({}, d, { paired: true });
        }
        for (const d of discovered) {
            if (!map[d.mac])
                map[d.mac] = d;
            else
                map[d.mac] = Object.assign({}, map[d.mac], d);
        }
        const list = Object.keys(map).map(k => map[k]);
        list.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            return (a.name || "").localeCompare(b.name || "");
        });
        return list;
    }

    function refresh() {
        statusProc.running = true;
    }

    function toggle() {
        setPowered(!powered);
    }

    function setPowered(on) {
        powerProc.command = ["bluetoothctl", "power", on ? "on" : "off"];
        powerProc.running = true;
    }

    function startScan() {
        if (!powered)
            return;
        discovering = true;
        scanProc.command = ["sh", "-c",
            "bluetoothctl --timeout 8 scan on 2>/dev/null; " +
            "bluetoothctl devices 2>/dev/null"
        ];
        scanProc.running = true;
    }

    function stopScan() {
        actionProc.command = ["bluetoothctl", "scan", "off"];
        actionProc.running = true;
        discovering = false;
    }

    function connectDevice(mac) {
        if (!mac)
            return;
        busyMac = mac;
        actionProc.command = ["bluetoothctl", "connect", mac];
        actionProc.running = true;
    }

    function disconnectDevice(mac) {
        if (!mac)
            return;
        busyMac = mac;
        actionProc.command = ["bluetoothctl", "disconnect", mac];
        actionProc.running = true;
    }

    function pairDevice(mac) {
        if (!mac)
            return;
        busyMac = mac;
        actionProc.command = ["sh", "-c",
            "bluetoothctl pair '" + mac + "' && bluetoothctl connect '" + mac + "'"
        ];
        actionProc.running = true;
    }

    Process {
        id: statusProc
        command: ["sh", "-c",
            "bluetoothctl show 2>/dev/null | grep -E 'Powered:|Discovering:'; " +
            "echo '---CONNECTED---'; " +
            "bluetoothctl devices Connected 2>/dev/null; " +
            "echo '---PAIRED---'; " +
            "bluetoothctl devices Paired 2>/dev/null"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text;
                root.powered = /Powered:\s*yes/i.test(text);
                root.discovering = /Discovering:\s*yes/i.test(text);

                const connectedMacs = {};
                const list = [];
                let firstName = "";

                const connSection = (text.split("---CONNECTED---")[1] || "").split("---PAIRED---")[0] || "";
                for (const line of connSection.split("\n")) {
                    const m = line.match(/^Device\s+([0-9A-Fa-f:]+)\s+(.*)$/);
                    if (m) {
                        connectedMacs[m[1]] = true;
                        list.push({ mac: m[1], name: m[2] || m[1], connected: true, paired: true });
                        if (!firstName)
                            firstName = m[2];
                    }
                }

                const pairedSection = text.split("---PAIRED---")[1] || "";
                for (const line of pairedSection.split("\n")) {
                    const m = line.match(/^Device\s+([0-9A-Fa-f:]+)\s+(.*)$/);
                    if (m && !connectedMacs[m[1]]) {
                        list.push({ mac: m[1], name: m[2] || m[1], connected: false, paired: true });
                    }
                }

                root.devices = list;
                root.connectedCount = Object.keys(connectedMacs).length;
                root.connectedName = firstName;
            }
        }
    }

    Process {
        id: scanProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const list = [];
                const seen = {};
                for (const line of lines) {
                    const m = line.match(/^Device\s+([0-9A-Fa-f:]+)\s+(.*)$/);
                    if (m && !seen[m[1]]) {
                        seen[m[1]] = true;
                        list.push({
                            mac: m[1],
                            name: m[2] || m[1],
                            connected: false,
                            paired: false
                        });
                    }
                }
                root.discovered = list;
                root.discovering = false;
                statusProc.running = true;
            }
        }
        onExited: {
            root.discovering = false;
            statusProc.running = true;
        }
    }

    Process {
        id: powerProc
        running: false
        onExited: Qt.callLater(() => statusProc.running = true)
    }

    Process {
        id: actionProc
        running: false
        onExited: {
            root.busyMac = "";
            Qt.callLater(() => statusProc.running = true)
        }
    }

    Timer {
        interval: 6000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }
}
