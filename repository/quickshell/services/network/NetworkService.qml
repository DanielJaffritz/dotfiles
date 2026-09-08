pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property bool connected: false
    property string ssid: ""
    property string activeConnection: ""  // nombre de la conexión NM activa (wifi)
    property int signal: 0
    property string connectionType: "none"  // wifi | ethernet | none
    property string ipAddress: ""
    property bool scanning: false
    property bool airplaneMode: false
    property var networks: []       // visibles: [{ssid, signal, security, inUse, bars, saved, connectionName}]
    property var savedNetworks: []  // guardadas: [{name, uuid, ssid, active, device}]
    property string busySsid: ""
    property string busyUuid: ""

    // Set de SSIDs/nombres guardados para lookup rápido
    readonly property var savedNames: {
        const s = {};
        for (const c of savedNetworks) {
            if (c.name)
                s[c.name] = c;
            if (c.ssid)
                s[c.ssid] = c;
        }
        return s;
    }

    readonly property string icon: {
        if (airplaneMode)
            return "󰀝";
        if (connectionType === "ethernet")
            return "󰈀";
        if (!wifiEnabled)
            return "󰖪";
        if (!connected)
            return "󰖩";
        if (signal >= 75) return "󰤨";
        if (signal >= 50) return "󰤥";
        if (signal >= 25) return "󰤢";
        return "󰤟";
    }

    readonly property string display: {
        if (airplaneMode)
            return icon + " Avión";
        if (connectionType === "ethernet")
            return icon + " Ethernet";
        if (!wifiEnabled)
            return icon + " Off";
        if (!connected)
            return icon + " Desconectado";
        return icon + " " + (ssid || "Wi‑Fi");
    }

    function refresh() {
        statusProc.running = true;
        savedProc.running = true;
    }

    function scan() {
        if (!wifiEnabled || airplaneMode)
            return;
        scanning = true;
        savedProc.running = true;
        scanProc.running = true;
    }

    function toggleWifi() {
        if (airplaneMode)
            return;
        actionProc.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"];
        actionProc.running = true;
    }

    function setWifi(on) {
        actionProc.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        actionProc.running = true;
    }

    function connectTo(ssidName) {
        if (!ssidName)
            return;
        busySsid = ssidName;
        // Si está guardada, preferir connection up (más fiable)
        const saved = savedNames[ssidName];
        if (saved && saved.name) {
            actionProc.command = ["nmcli", "connection", "up", "id", saved.name];
        } else {
            actionProc.command = ["nmcli", "device", "wifi", "connect", ssidName];
        }
        actionProc.running = true;
    }

    function connectSaved(connectionName) {
        if (!connectionName)
            return;
        busySsid = connectionName;
        actionProc.command = ["nmcli", "connection", "up", "id", connectionName];
        actionProc.running = true;
    }

    function disconnect() {
        busySsid = ssid || activeConnection;
        actionProc.command = ["sh", "-c",
            "DEV=$(nmcli -t -f DEVICE,TYPE d | awk -F: '$2==\"wifi\"{print $1; exit}'); " +
            "[ -n \"$DEV\" ] && nmcli device disconnect \"$DEV\""
        ];
        actionProc.running = true;
    }

    // Olvidar red guardada por nombre de conexión o SSID
    function forget(nameOrSsid) {
        if (!nameOrSsid)
            return;
        const saved = savedNames[nameOrSsid];
        const id = saved ? (saved.name || nameOrSsid) : nameOrSsid;
        busySsid = id;
        busyUuid = saved ? (saved.uuid || "") : "";
        // Borrar por id (nombre); si falla, intentar por UUID
        actionProc.command = ["sh", "-c",
            "nmcli connection delete id " + shellQuote(id) +
            (saved && saved.uuid ? " 2>/dev/null || nmcli connection delete uuid " + shellQuote(saved.uuid) : "") +
            "; true"
        ];
        actionProc.running = true;
    }

    function forgetUuid(uuid) {
        if (!uuid)
            return;
        busyUuid = uuid;
        actionProc.command = ["nmcli", "connection", "delete", "uuid", uuid];
        actionProc.running = true;
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function toggleAirplane() {
        const enable = !airplaneMode;
        actionProc.command = ["sh", "-c",
            enable
                ? "nmcli radio all off; bluetoothctl power off 2>/dev/null; true"
                : "nmcli radio all on; bluetoothctl power on 2>/dev/null; true"
        ];
        actionProc.running = true;
        airplaneMode = enable;
        if (enable)
            wifiEnabled = false;
        Qt.callLater(() => {
            statusProc.running = true;
            savedProc.running = true;
        });
    }

    function isSaved(ssidName) {
        return !!savedNames[ssidName];
    }

    // Guardadas que no están en el último escaneo
    readonly property var savedOutOfRange: {
        const visible = {};
        for (const n of networks) {
            if (n.ssid)
                visible[n.ssid] = true;
        }
        return savedNetworks.filter(s => {
            const key = s.ssid || s.name;
            return key && !visible[s.ssid] && !visible[s.name];
        });
    }

    // ─── Estado general ──────────────────────────────────────────────────────
    Process {
        id: statusProc
        command: ["sh", "-c",
            "nmcli -t -f WIFI g 2>/dev/null; " +
            "echo '---ACTIVE---'; " +
            "nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null; " +
            "echo '---WIFI---'; " +
            "nmcli -t -f ACTIVE,SSID,SIGNAL device wifi list 2>/dev/null | grep '^yes:' | head -1; " +
            "echo '---IP---'; " +
            "nmcli -t -f IP4.ADDRESS device show 2>/dev/null | head -1"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text;
                const wifiLine = (text.split("\n")[0] || "");
                root.wifiEnabled = /enabled/i.test(wifiLine);

                let type = "none";
                let connected = false;
                root.activeConnection = "";
                root.ssid = "";
                root.signal = 0;

                const activeSec = (text.split("---ACTIVE---")[1] || "").split("---WIFI---")[0] || "";
                for (const line of activeSec.split("\n")) {
                    if (!line.trim())
                        continue;
                    const parts = line.split(":");
                    // NAME:TYPE:DEVICE
                    if (parts.length >= 2) {
                        const name = parts[0];
                        const typ = (parts[1] || "").toLowerCase();
                        if (typ.indexOf("wireless") !== -1 || typ === "wifi" || typ.indexOf("802-11") !== -1) {
                            type = "wifi";
                            connected = true;
                            root.activeConnection = name;
                        } else if (typ.indexOf("ethernet") !== -1 || typ.indexOf("802-3") !== -1) {
                            type = "ethernet";
                            connected = true;
                        }
                    }
                }

                const wifiSec = (text.split("---WIFI---")[1] || "").split("---IP---")[0] || "";
                for (const line of wifiSec.split("\n")) {
                    if (line.startsWith("yes:")) {
                        const parts = line.split(":");
                        if (parts.length >= 3) {
                            root.signal = parseInt(parts[parts.length - 1]) || 0;
                            root.ssid = parts.slice(1, parts.length - 1).join(":");
                        } else if (parts.length >= 2) {
                            root.ssid = parts.slice(1).join(":");
                        }
                    }
                }

                const ipSec = text.split("---IP---")[1] || "";
                const m = ipSec.match(/(\d+\.\d+\.\d+\.\d+)/);
                if (m)
                    root.ipAddress = m[1];

                root.connectionType = type;
                root.connected = connected || type !== "none";
            }
        }
    }

    // ─── Conexiones guardadas (solo wifi) ────────────────────────────────────
    Process {
        id: savedProc
        command: ["sh", "-c",
            // Listar conexiones wifi con UUID y SSID
            "nmcli -t -f NAME,UUID,TYPE,DEVICE connection show 2>/dev/null | while IFS= read -r line; do " +
            "  typ=$(echo \"$line\" | awk -F: '{print $(NF-1)}'); " +
            "  case \"$typ\" in *wireless*|wifi|WIFI|802-11*) " +
            "    name=$(echo \"$line\" | cut -d: -f1); " +
            "    uuid=$(echo \"$line\" | cut -d: -f2); " +
            "    dev=$(echo \"$line\" | awk -F: '{print $NF}'); " +
            "    ssid=$(nmcli -t -f 802-11-wireless.ssid connection show uuid \"$uuid\" 2>/dev/null | cut -d: -f2-); " +
            "    echo \"$name|$uuid|${ssid:-$name}|$dev\"; " +
            "  ;; esac; " +
            "done"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                const list = [];
                for (const line of lines) {
                    const parts = line.split("|");
                    if (parts.length < 3)
                        continue;
                    const name = parts[0];
                    const uuid = parts[1];
                    const ssid = parts[2] || name;
                    const dev = parts[3] || "";
                    const active = dev !== "" && dev !== "--";
                    list.push({
                        name: name,
                        uuid: uuid,
                        ssid: ssid,
                        active: active,
                        device: active ? dev : ""
                    });
                }
                list.sort((a, b) => {
                    if (a.active !== b.active)
                        return a.active ? -1 : 1;
                    return (a.ssid || a.name).localeCompare(b.ssid || b.name);
                });
                root.savedNetworks = list;
            }
        }
    }

    // ─── Escaneo de redes visibles ───────────────────────────────────────────
    Process {
        id: scanProc
        command: ["sh", "-c",
            "nmcli device wifi rescan 2>/dev/null; sleep 1.2; " +
            "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                const seen = {};
                const list = [];
                for (const line of lines) {
                    const parts = line.split(":");
                    if (parts.length < 3)
                        continue;
                    const inUse = parts[0] === "*";
                    const security = parts[parts.length - 1] || "";
                    const signal = parseInt(parts[parts.length - 2]) || 0;
                    const ssid = parts.slice(1, parts.length - 2).join(":");
                    if (!ssid || seen[ssid])
                        continue;
                    seen[ssid] = true;
                    const saved = root.savedNames[ssid];
                    list.push({
                        ssid: ssid,
                        signal: signal,
                        security: security,
                        inUse: inUse,
                        bars: signal >= 75 ? 4 : signal >= 50 ? 3 : signal >= 25 ? 2 : 1,
                        saved: !!saved,
                        connectionName: saved ? saved.name : ""
                    });
                }
                list.sort((a, b) => {
                    if (a.inUse !== b.inUse)
                        return a.inUse ? -1 : 1;
                    if (a.saved !== b.saved)
                        return a.saved ? -1 : 1;
                    return b.signal - a.signal;
                });
                root.networks = list;
                root.scanning = false;
            }
        }
        onExited: {
            if (exitCode !== 0)
                root.scanning = false;
            statusProc.running = true;
            savedProc.running = true;
        }
    }

    Process {
        id: actionProc
        running: false
        onExited: {
            root.busySsid = "";
            root.busyUuid = "";
            Qt.callLater(() => {
                statusProc.running = true;
                savedProc.running = true;
                if (root.wifiEnabled && !root.airplaneMode)
                    scanProc.running = true;
            });
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statusProc.running = true;
            savedProc.running = true;
        }
    }
}
