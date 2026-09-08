import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

Scope {
    id: root

    property bool panelOpen: GlobalState.isTimerOpen
    property string activeTab: "timer"   // timer | pomodoro
    property bool minimalMode: GlobalState.isTimerMinimal

    // ─── Timer normal ────────────────────────────────────────────────────────
    property int timerDurationSec: 5 * 60
    property int timerRemaining: 5 * 60
    property bool timerRunning: false
    property bool timerFinished: false

    // ─── Pomodoro ────────────────────────────────────────────────────────────
    property int pomoWorkSec: 25 * 60
    property int pomoBreakSec: 5 * 60
    property int pomoLongBreakSec: 15 * 60
    property int pomoCyclesUntilLong: 4
    property int pomoCompleted: 0          // ciclos de trabajo terminados
    property string pomoPhase: "work"      // work | break | longBreak
    property int pomoRemaining: 25 * 60
    property bool pomoRunning: false
    property bool pomoFinished: false      // fin de la fase actual (antes de auto-siguiente)

    // UI
    readonly property color bgPanel: "#ee141414"
    readonly property color bgCard: "#22ffffff"
    readonly property color borderColor: "#44ffffff"
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#aaffffff"
    readonly property color textMuted: "#66ffffff"
    readonly property color accent: "#c0e0ff"
    readonly property color accentWarm: "#ffcc66"
    readonly property color accentGo: "#66dd99"
    readonly property color accentStop: "#ff8866"

    readonly property int displayRemaining: activeTab === "pomodoro" ? pomoRemaining : timerRemaining
    readonly property bool isRunning: activeTab === "pomodoro" ? pomoRunning : timerRunning
    readonly property bool isFinished: activeTab === "pomodoro" ? pomoFinished : timerFinished

    signal closeRequested()

    function open() { GlobalState.isTimerOpen = true }
    function close() {
        GlobalState.isTimerOpen = false
        // No detener el cronómetro al cerrar el panel
        closeRequested()
    }
    function toggle() {
        if (panelOpen)
            close()
        else
            open()
    }

    function formatTime(secs) {
        secs = Math.max(0, Math.floor(secs))
        const h = Math.floor(secs / 3600)
        const m = Math.floor((secs % 3600) / 60)
        const s = secs % 60
        const mm = (m < 10 ? "0" : "") + m
        const ss = (s < 10 ? "0" : "") + s
        if (h > 0)
            return h + ":" + mm + ":" + ss
        return mm + ":" + ss
    }

    function notifyDone(title, body) {
        // notify-send si está disponible
        notifyProc.command = ["notify-send", "-a", "Timer", "-u", "normal", title, body]
        notifyProc.running = true
    }

    // ─── Timer normal ────────────────────────────────────────────────────────
    function timerStart() {
        if (timerRemaining <= 0) {
            timerRemaining = timerDurationSec
            timerFinished = false
        }
        timerRunning = true
        timerFinished = false
    }
    function timerPause() { timerRunning = false }
    function timerToggle() {
        if (timerRunning)
            timerPause()
        else
            timerStart()
    }
    function timerReset() {
        timerRunning = false
        timerFinished = false
        timerRemaining = timerDurationSec
    }
    function timerSetMinutes(mins) {
        mins = Math.max(0, Math.min(180, Math.floor(mins)))
        timerDurationSec = mins * 60
        if (!timerRunning) {
            timerRemaining = timerDurationSec
            timerFinished = false
        }
    }
    function timerAdjust(deltaSec) {
        const next = Math.max(0, Math.min(180 * 60, timerDurationSec + deltaSec))
        timerDurationSec = next
        if (!timerRunning) {
            timerRemaining = next
            timerFinished = false
        }
    }

    // ─── Pomodoro ────────────────────────────────────────────────────────────
    function pomoPhaseDuration() {
        if (pomoPhase === "longBreak")
            return pomoLongBreakSec
        if (pomoPhase === "break")
            return pomoBreakSec
        return pomoWorkSec
    }
    function pomoPhaseLabel() {
        if (pomoPhase === "longBreak")
            return "Descanso largo"
        if (pomoPhase === "break")
            return "Descanso"
        return "Enfoque"
    }
    function pomoStart() {
        if (pomoRemaining <= 0)
            pomoRemaining = pomoPhaseDuration()
        pomoRunning = true
        pomoFinished = false
    }
    function pomoPause() { pomoRunning = false }
    function pomoToggle() {
        if (pomoRunning)
            pomoPause()
        else
            pomoStart()
    }
    function pomoReset() {
        pomoRunning = false
        pomoFinished = false
        pomoPhase = "work"
        pomoRemaining = pomoWorkSec
        // no reinicia pomoCompleted a propósito; usar pomoResetAll
    }
    function pomoResetAll() {
        pomoRunning = false
        pomoFinished = false
        pomoPhase = "work"
        pomoRemaining = pomoWorkSec
        pomoCompleted = 0
    }
    function pomoNextPhase() {
        pomoRunning = false
        pomoFinished = false
        if (pomoPhase === "work") {
            pomoCompleted += 1
            if (pomoCompleted > 0 && pomoCompleted % pomoCyclesUntilLong === 0)
                pomoPhase = "longBreak"
            else
                pomoPhase = "break"
        } else {
            pomoPhase = "work"
        }
        pomoRemaining = pomoPhaseDuration()
    }
    function pomoAdjustWork(deltaMin) {
        const mins = Math.max(1, Math.min(60, Math.floor(pomoWorkSec / 60) + deltaMin))
        pomoWorkSec = mins * 60
        if (!pomoRunning && pomoPhase === "work")
            pomoRemaining = pomoWorkSec
    }
    function pomoAdjustBreak(deltaMin) {
        const mins = Math.max(1, Math.min(30, Math.floor(pomoBreakSec / 60) + deltaMin))
        pomoBreakSec = mins * 60
        if (!pomoRunning && pomoPhase === "break")
            pomoRemaining = pomoBreakSec
    }

    // Tick cada segundo
    Timer {
        interval: 1000
        running: root.timerRunning || root.pomoRunning
        repeat: true
        onTriggered: {
            if (root.timerRunning) {
                if (root.timerRemaining > 0) {
                    root.timerRemaining -= 1
                    if (root.timerRemaining <= 0) {
                        root.timerRunning = false
                        root.timerFinished = true
                        root.timerRemaining = 0
                        root.notifyDone("Timer terminado", "El temporizador ha finalizado")
                        // Mostrar panel si estaba cerrado
                        root.panelOpen = true
                        root.minimalMode = false
                    }
                }
            }
            if (root.pomoRunning) {
                if (root.pomoRemaining > 0) {
                    root.pomoRemaining -= 1
                    if (root.pomoRemaining <= 0) {
                        root.pomoRunning = false
                        root.pomoFinished = true
                        root.pomoRemaining = 0
                        const label = root.pomoPhaseLabel()
                        root.notifyDone("Pomodoro", label + " terminado")
                        root.panelOpen = true
                        root.minimalMode = false
                        // Auto avanzar a la siguiente fase tras un instante
                        Qt.callLater(() => root.pomoNextPhase())
                    }
                }
            }
        }
    }

    Process {
        id: notifyProc
        running: false
    }

    // ─── Ventana ─────────────────────────────────────────────────────────────
    PanelWindow {
        id: panel
        visible: root.panelOpen
        color: "transparent"
        exclusiveZone: 0
        focusable: true

        anchors {
            top: true
            right: true
        }

        margins {
            top: 12
            right: 12
        }

        implicitWidth: root.minimalMode ? 160 : 300
        implicitHeight: container.implicitHeight

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-timer"
        WlrLayershell.keyboardFocus: root.panelOpen && !root.minimalMode
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        mask: Region { item: container }

        // Esc cierra (solo modo completo)
        Item {
            anchors.fill: parent
            focus: root.panelOpen && !root.minimalMode
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                } else if (event.key === Qt.Key_Space) {
                    if (root.activeTab === "pomodoro")
                        root.pomoToggle()
                    else
                        root.timerToggle()
                    event.accepted = true
                }
            }
        }

        Rectangle {
            id: container
            anchors.top: parent.top
            anchors.right: parent.right
            width: root.minimalMode ? 160 : 300
            implicitHeight: mainCol.implicitHeight + (root.minimalMode ? 20 : 24)
            radius: 14
            color: root.bgPanel
            border.color: root.borderColor
            border.width: 1
            clip: true

            Behavior on width {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                id: mainCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.minimalMode ? 10 : 12
                spacing: root.minimalMode ? 0 : 10

                // ─── Cabecera / pestañas (oculta en minimal) ───
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: !root.minimalMode

                    Repeater {
                        model: [
                            { id: "timer", label: "Timer" },
                            { id: "pomodoro", label: "Pomodoro" }
                        ]
                        Rectangle {
                            required property var modelData
                            Layout.preferredHeight: 28
                            Layout.preferredWidth: tabLbl.implicitWidth + 18
                            radius: 8
                            color: root.activeTab === modelData.id ? "#44ffffff" : "transparent"
                            border.color: root.activeTab === modelData.id ? "#66ffffff" : "transparent"
                            border.width: 1

                            Text {
                                id: tabLbl
                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.activeTab === modelData.id ? root.textPrimary : root.textSecondary
                                font.pixelSize: 12
                                font.bold: root.activeTab === modelData.id
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = modelData.id
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Minimal
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 8
                        color: minBtn.containsMouse ? "#33ffffff" : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰊓"
                            color: root.textSecondary
                            font.pixelSize: 14
                        }
                        MouseArea {
                            id: minBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: GlobalState.isTimerMinimal = true
                        }
                    }

                    // Cerrar
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 8
                        color: closeBtn.containsMouse ? "#44ff6666" : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: root.textPrimary
                            font.pixelSize: 14
                        }
                        MouseArea {
                            id: closeBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }

                // Separador
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: root.borderColor
                    visible: !root.minimalMode
                }

                // ─── Display del tiempo ───
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Etiqueta de fase (pomodoro)
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.activeTab === "pomodoro"
                        text: root.pomoPhaseLabel() + (root.pomoCompleted > 0 ? (" · " + root.pomoCompleted) : "")
                        color: root.pomoPhase === "work" ? root.accent : root.accentWarm
                        font.pixelSize: root.minimalMode ? 11 : 12
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.formatTime(root.displayRemaining)
                        color: root.isFinished ? root.accentStop
                             : (root.isRunning ? root.accentGo : root.textPrimary)
                        font.pixelSize: root.minimalMode ? 28 : 42
                        font.bold: true
                        font.family: "monospace"

                        // Click en minimal: expandir o pausar/reanudar
                        MouseArea {
                            anchors.fill: parent
                            enabled: root.minimalMode
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activeTab === "pomodoro")
                                    root.pomoToggle()
                                else
                                    root.timerToggle()
                            }
                            onDoubleClicked: root.minimalMode = false
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.minimalMode
                        text: root.isRunning ? "▶" : "⏸"
                        color: root.textMuted
                        font.pixelSize: 12
                    }
                }

                // ─── Controles (ocultos en minimal) ───
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: !root.minimalMode

                    // Ajuste de duración — Timer
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        visible: root.activeTab === "timer"

                        RoundBtn {
                            label: "−5"
                            onClicked: root.timerAdjust(-5 * 60)
                        }
                        RoundBtn {
                            label: "−1"
                            onClicked: root.timerAdjust(-60)
                        }
                        Text {
                            text: Math.floor(root.timerDurationSec / 60) + " min"
                            color: root.textSecondary
                            font.pixelSize: 12
                            Layout.preferredWidth: 52
                            horizontalAlignment: Text.AlignHCenter
                        }
                        RoundBtn {
                            label: "+1"
                            onClicked: root.timerAdjust(60)
                        }
                        RoundBtn {
                            label: "+5"
                            onClicked: root.timerAdjust(5 * 60)
                        }
                    }

                    // Presets timer
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6
                        visible: root.activeTab === "timer"
                        Repeater {
                            model: [5, 10, 15, 25, 45]
                            Rectangle {
                                required property int modelData
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: presetTxt.implicitWidth + 12
                                radius: 6
                                color: Math.floor(root.timerDurationSec / 60) === modelData
                                       ? "#44ffffff" : "#18ffffff"
                                Text {
                                    id: presetTxt
                                    anchors.centerIn: parent
                                    text: modelData + "m"
                                    color: root.textSecondary
                                    font.pixelSize: 11
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.timerSetMinutes(modelData)
                                }
                            }
                        }
                    }

                    // Ajuste pomodoro
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: root.activeTab === "pomodoro"

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8
                            Text {
                                text: "Trabajo"
                                color: root.textMuted
                                font.pixelSize: 11
                                Layout.preferredWidth: 56
                            }
                            RoundBtn { label: "−"; onClicked: root.pomoAdjustWork(-1) }
                            Text {
                                text: Math.floor(root.pomoWorkSec / 60) + "m"
                                color: root.textSecondary
                                font.pixelSize: 12
                                Layout.preferredWidth: 36
                                horizontalAlignment: Text.AlignHCenter
                            }
                            RoundBtn { label: "+"; onClicked: root.pomoAdjustWork(1) }
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8
                            Text {
                                text: "Descanso"
                                color: root.textMuted
                                font.pixelSize: 11
                                Layout.preferredWidth: 56
                            }
                            RoundBtn { label: "−"; onClicked: root.pomoAdjustBreak(-1) }
                            Text {
                                text: Math.floor(root.pomoBreakSec / 60) + "m"
                                color: root.textSecondary
                                font.pixelSize: 12
                                Layout.preferredWidth: 36
                                horizontalAlignment: Text.AlignHCenter
                            }
                            RoundBtn { label: "+"; onClicked: root.pomoAdjustBreak(1) }
                        }
                    }

                    // Botones principales
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10

                        // Reset
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 20
                            color: resetMa.containsMouse ? "#33ffffff" : "#22ffffff"
                            Text {
                                anchors.centerIn: parent
                                text: "󰜉"
                                color: root.textSecondary
                                font.pixelSize: 16
                            }
                            MouseArea {
                                id: resetMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.activeTab === "pomodoro")
                                        root.pomoReset()
                                    else
                                        root.timerReset()
                                }
                                onPressAndHold: {
                                    if (root.activeTab === "pomodoro")
                                        root.pomoResetAll()
                                }
                            }
                        }

                        // Play / Pause
                        Rectangle {
                            Layout.preferredWidth: 52
                            Layout.preferredHeight: 52
                            radius: 26
                            color: root.isRunning ? "#44ff8866" : "#4455aa88"
                            border.color: root.isRunning ? root.accentStop : root.accentGo
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: root.isRunning ? "󰏤" : "󰐊"
                                color: root.textPrimary
                                font.pixelSize: 22
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.activeTab === "pomodoro")
                                        root.pomoToggle()
                                    else
                                        root.timerToggle()
                                }
                            }
                        }

                        // Siguiente fase (solo pomodoro) / o skip
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 20
                            color: skipMa.containsMouse ? "#33ffffff" : "#22ffffff"
                            visible: root.activeTab === "pomodoro"
                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                color: root.textSecondary
                                font.pixelSize: 16
                            }
                            MouseArea {
                                id: skipMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pomoNextPhase()
                            }
                        }

                        // Placeholder simétrico cuando no es pomodoro
                        Item {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            visible: root.activeTab === "timer"
                        }
                    }
                }
            }

            // En minimal: doble click en el panel también expande
            MouseArea {
                anchors.fill: parent
                z: -1
                enabled: root.minimalMode
                onDoubleClicked: root.minimalMode = false
            }
        }
    }

    // Botón pequeño reutilizable
    component RoundBtn: Rectangle {
        property string label: ""
        signal clicked()

        Layout.preferredWidth: Math.max(28, lbl.implicitWidth + 12)
        Layout.preferredHeight: 28
        radius: 8
        color: ma.containsMouse ? "#33ffffff" : "#18ffffff"

        Text {
            id: lbl
            anchors.centerIn: parent
            text: parent.label
            color: root.textSecondary
            font.pixelSize: 12
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    // Si el timer corre con panel cerrado, mostrar siempre el modo minimal
    // (opcional: auto-abrir minimal cuando hay timer activo y panel cerrado)
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            // Si está corriendo y el usuario cerró el panel, reabrir en minimal
            if ((root.timerRunning || root.pomoRunning) && !root.panelOpen) {
                root.minimalMode = true
                root.panelOpen = true
            }
        }
    }

    IpcHandler {
        target: "timer"

        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
        function minimal(): void {
            root.minimalMode = true
            root.panelOpen = true
        }
        function expand(): void {
            root.minimalMode = false
            root.panelOpen = true
        }
        function start(): void {
            if (root.activeTab === "pomodoro")
                root.pomoStart()
            else
                root.timerStart()
            root.panelOpen = true
        }
        function pause(): void {
            root.timerPause()
            root.pomoPause()
        }
        function reset(): void {
            if (root.activeTab === "pomodoro")
                root.pomoReset()
            else
                root.timerReset()
        }
        function tab(name: string): void {
            if (name === "timer" || name === "pomodoro")
                root.activeTab = name
            root.minimalMode = false
            root.open()
        }
    }
}
