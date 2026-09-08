pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // CPU
    property real cpuUsage: 0          // 0–1
    property int cpuPercent: 0
    property int cpuCores: 0
    property string cpuModel: ""
    property real cpuFreqMhz: 0        // promedio actual

    // RAM (bytes)
    property real memTotal: 0
    property real memUsed: 0
    property real memAvailable: 0
    property real memPercent: 0        // 0–1
    property int memPercentInt: 0

    // Swap
    property real swapTotal: 0
    property real swapUsed: 0
    property real swapPercent: 0

    // Disco raíz /
    property real diskTotal: 0
    property real diskUsed: 0
    property real diskFree: 0
    property real diskPercent: 0
    property int diskPercentInt: 0
    property string diskFs: ""
    property string diskDevice: ""

    // Uptime
    property real uptimeSeconds: 0
    property string uptimeText: "—"

    // Sistema
    property string hostname: ""
    property string kernel: ""
    property string osName: ""
    property string architecture: ""
    property int processCount: 0
    property real load1: 0
    property real load5: 0
    property real load15: 0

    // Valores previos de /proc/stat para delta
    property real _prevIdle: 0
    property real _prevTotal: 0
    property bool _cpuPrimed: false

    function refresh() {
        memProc.running = true;
        cpuProc.running = true;
        diskProc.running = true;
        uptimeProc.running = true;
        infoProc.running = true;
    }

    function formatBytes(bytes) {
        if (!bytes || bytes <= 0)
            return "0 B";
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        let v = bytes;
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024;
            i++;
        }
        return (i === 0 ? Math.round(v) : v.toFixed(v >= 10 ? 1 : 2)) + " " + units[i];
    }

    function formatUptime(secs) {
        secs = Math.floor(secs || 0);
        const d = Math.floor(secs / 86400);
        const h = Math.floor((secs % 86400) / 3600);
        const m = Math.floor((secs % 3600) / 60);
        const parts = [];
        if (d > 0)
            parts.push(d + "d");
        if (h > 0 || d > 0)
            parts.push(h + "h");
        parts.push(m + "m");
        return parts.join(" ");
    }

    // ─── Memoria + load + procesos ───────────────────────────────────────────
    Process {
        id: memProc
        command: ["sh", "-c",
            "awk '/MemTotal:/{t=$2} /MemAvailable:/{a=$2} /SwapTotal:/{st=$2} /SwapFree:/{sf=$2} END{print t,a,st,sf}' /proc/meminfo; " +
            "cut -d' ' -f1-3 /proc/loadavg; " +
            "ls /proc/[0-9]* 2>/dev/null | wc -l"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length >= 1) {
                    const p = lines[0].trim().split(/\s+/);
                    // kB → bytes
                    const totalKb = parseFloat(p[0]) || 0;
                    const availKb = parseFloat(p[1]) || 0;
                    const swapTKb = parseFloat(p[2]) || 0;
                    const swapFKb = parseFloat(p[3]) || 0;
                    root.memTotal = totalKb * 1024;
                    root.memAvailable = availKb * 1024;
                    root.memUsed = Math.max(0, root.memTotal - root.memAvailable);
                    root.memPercent = root.memTotal > 0 ? root.memUsed / root.memTotal : 0;
                    root.memPercentInt = Math.round(root.memPercent * 100);
                    root.swapTotal = swapTKb * 1024;
                    root.swapUsed = Math.max(0, (swapTKb - swapFKb) * 1024);
                    root.swapPercent = root.swapTotal > 0 ? root.swapUsed / root.swapTotal : 0;
                }
                if (lines.length >= 2) {
                    const l = lines[1].trim().split(/\s+/);
                    root.load1 = parseFloat(l[0]) || 0;
                    root.load5 = parseFloat(l[1]) || 0;
                    root.load15 = parseFloat(l[2]) || 0;
                }
                if (lines.length >= 3)
                    root.processCount = parseInt(lines[2]) || 0;
            }
        }
    }

    // ─── CPU usage + model + cores + freq ────────────────────────────────────
    Process {
        id: cpuProc
        command: ["sh", "-c",
            // línea cpu agregada de /proc/stat
            "head -1 /proc/stat; " +
            "echo '---'; " +
            "nproc; " +
            "echo '---'; " +
            // modelo
            "grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ //'; " +
            "echo '---'; " +
            // frecuencia media (kHz → MHz)
            "if [ -d /sys/devices/system/cpu ]; then " +
            "  sum=0; n=0; " +
            "  for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do " +
            "    [ -r \"$f\" ] || continue; v=$(cat \"$f\"); sum=$((sum+v)); n=$((n+1)); " +
            "  done; " +
            "  if [ \"$n\" -gt 0 ]; then echo $((sum/n/1000)); else " +
            "    grep -m1 'cpu MHz' /proc/cpuinfo 2>/dev/null | awk '{print int($4)}'; " +
            "  fi; " +
            "else echo 0; fi"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("---");
                // /proc/stat: cpu user nice system idle iowait irq softirq steal ...
                if (parts.length >= 1) {
                    const fields = parts[0].trim().split(/\s+/);
                    if (fields[0] === "cpu" && fields.length >= 5) {
                        let idle = parseFloat(fields[4]) || 0;
                        if (fields.length > 5)
                            idle += parseFloat(fields[5]) || 0; // iowait
                        let total = 0;
                        for (let i = 1; i < fields.length; i++)
                            total += parseFloat(fields[i]) || 0;

                        if (root._cpuPrimed && total > root._prevTotal) {
                            const dTotal = total - root._prevTotal;
                            const dIdle = idle - root._prevIdle;
                            const usage = dTotal > 0 ? 1 - (dIdle / dTotal) : 0;
                            root.cpuUsage = Math.max(0, Math.min(1, usage));
                            root.cpuPercent = Math.round(root.cpuUsage * 100);
                        }
                        root._prevIdle = idle;
                        root._prevTotal = total;
                        root._cpuPrimed = true;
                    }
                }
                if (parts.length >= 2)
                    root.cpuCores = parseInt(parts[1].trim()) || 0;
                if (parts.length >= 3) {
                    const model = parts[2].trim().replace(/\s+/g, " ");
                    if (model)
                        root.cpuModel = model;
                }
                if (parts.length >= 4)
                    root.cpuFreqMhz = parseFloat(parts[3].trim()) || 0;
            }
        }
    }

    // ─── Disco / ─────────────────────────────────────────────────────────────
    Process {
        id: diskProc
        command: ["sh", "-c",
            "df -B1 -P / 2>/dev/null | awk 'NR==2 {print $1,$2,$3,$4,$5,$6}'"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/);
                if (p.length >= 5) {
                    root.diskDevice = p[0] || "";
                    root.diskTotal = parseFloat(p[1]) || 0;
                    root.diskUsed = parseFloat(p[2]) || 0;
                    root.diskFree = parseFloat(p[3]) || 0;
                    root.diskPercent = root.diskTotal > 0 ? root.diskUsed / root.diskTotal : 0;
                    root.diskPercentInt = Math.round(root.diskPercent * 100);
                    root.diskFs = p[5] || "/";
                }
            }
        }
    }

    // ─── Uptime ──────────────────────────────────────────────────────────────
    Process {
        id: uptimeProc
        command: ["sh", "-c", "cut -d. -f1 /proc/uptime"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.uptimeSeconds = parseFloat(text.trim()) || 0;
                root.uptimeText = root.formatUptime(root.uptimeSeconds);
            }
        }
    }

    // ─── Info estática / semi-estática ───────────────────────────────────────
    Process {
        id: infoProc
        command: ["sh", "-c",
            "hostname; " +
            "uname -r; " +
            "uname -m; " +
            "if [ -f /etc/os-release ]; then . /etc/os-release; echo \"$PRETTY_NAME\"; else uname -s; fi"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length > 0 && lines[0])
                    root.hostname = lines[0].trim();
                if (lines.length > 1 && lines[1])
                    root.kernel = lines[1].trim();
                if (lines.length > 2 && lines[2])
                    root.architecture = lines[2].trim();
                if (lines.length > 3 && lines[3])
                    root.osName = lines[3].trim();
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            memProc.running = true;
            cpuProc.running = true;
            uptimeProc.running = true;
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            diskProc.running = true;
            infoProc.running = true;
        }
    }
}
