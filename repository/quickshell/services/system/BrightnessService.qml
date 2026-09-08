pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root


    // 0.0 – 1.0
    property real value: 0
    property real maxRaw: 1
    property string backlightPath: ""
    property bool available: backlightPath !== ""

    readonly property int percent: Math.round(value * 100)

    readonly property string icon: {
        if (value < 0.33) return "󰃞";
        if (value < 0.66) return "󰃟";
        return "󰃠";
    }

    readonly property string display: available ? (icon + " " + percent + "%") : ""

    // Descubrir dispositivo de backlight
    Process {
        id: discovery
        command: ["sh", "-c",
            "p=$(ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -1); " +
            "[ -n \"$p\" ] && echo \"$p\" && cat \"${p%brightness}max_brightness\""
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length >= 2) {
                    const max = parseInt(lines[1]);
                    if (!isNaN(max) && max > 0)
                        root.maxRaw = max;
                    root.backlightPath = lines[0];
                    readProc.running = true;
                }
            }
        }
    }

    FileView {
        id: brightnessFile
        path: root.backlightPath
        watchChanges: true
        onFileChanged: readProc.running = true
    }

    Process {
        id: readProc
        command: ["brightnessctl", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim());
                if (!isNaN(val) && root.maxRaw > 0) {
                    const next = val / root.maxRaw;
                    if (Math.abs(next - root.value) > 0.001)
                        root.value = next;
                }
            }
        }
    }

    Process {
        id: setProc
        running: false
    }

    function set(v) {
        if (!available)
            return;
        const clamped = Math.max(0.01, Math.min(1, v));
        const pct = Math.round(clamped * 100);
        setProc.command = ["brightnessctl", "set", pct + "%"];
        setProc.running = true;
        // Optimistic update
        root.value = clamped;
    }

    function change(delta) {
        set(value + delta);
    }

    function increase(step) {
        change(step !== undefined ? step : 0.05);
    }

    function decrease(step) {
        change(-(step !== undefined ? step : 0.05));
    }
}
