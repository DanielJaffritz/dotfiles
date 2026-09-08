import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

Scope {
    id: root

    property bool panelOpen: GlobalState.isWayLockOpen

    readonly property color bgOverlay: "#99101010"
    readonly property color btnBg: "#33ffffff"
    readonly property color btnHover: "#55ffffff"
    readonly property color btnBorder: "#55ffffff"
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#ccffffff"
    readonly property color danger: "#ff6b6b"
    readonly property color warn: "#ffcc66"
    readonly property color accent: "#c0e0ff"
    readonly property color ok: "#66dd99"

    signal closeRequested()

    function open() { panelOpen = true }
    function close() {
        panelOpen = false
        closeRequested()
    }
    function toggle() {
        if (panelOpen)
            close()
        else
            open()
    }

    function runAction(action) {
        // Cerrar el menú primero
        root.close()
        Qt.callLater(() => {
            switch (action) {
            case "shutdown":
                actionProc.command = ["systemctl", "poweroff"]
                break
            case "reboot":
                actionProc.command = ["systemctl", "reboot"]
                break
            case "logout":
                actionProc.command = ["hyprctl", "dispatch", "hl.dsp.exit()"]
                break
            case "lock":
                actionProc.command = ["hyprlock"]
                break
            default:
                return
            }
            actionProc.running = true
        })
    }

    Process {
        id: actionProc
        running: false
    }

    PanelWindow {
        id: panel
        visible: root.panelOpen
        color: "transparent"
        exclusiveZone: 0
        focusable: true

        // Pantalla completa
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-powermenu"
        WlrLayershell.keyboardFocus: root.panelOpen
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        // Fondo a pantalla completa + contenido centrado
        Item {
            anchors.fill: parent
            focus: root.panelOpen

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                } else if (event.key === Qt.Key_1) {
                    root.runAction("lock")
                    event.accepted = true
                } else if (event.key === Qt.Key_2) {
                    root.runAction("logout")
                    event.accepted = true
                } else if (event.key === Qt.Key_3) {
                    root.runAction("reboot")
                    event.accepted = true
                } else if (event.key === Qt.Key_4) {
                    root.runAction("shutdown")
                    event.accepted = true
                }
            }

            // Capa de oscurecimiento (Hyprland aplica blur al namespace de la layer)
            Rectangle {
                id: backdrop
                anchors.fill: parent
                color: root.bgOverlay
                opacity: root.panelOpen ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
                }

                // Click en el fondo cierra
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            // Fila de botones centrada
            RowLayout {
                id: buttonRow
                anchors.centerIn: parent
                spacing: 28
                opacity: root.panelOpen ? 1 : 0
                scale: root.panelOpen ? 1 : 0.92

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 220; easing.type: Easing.OutBack }
                }

                PowerButton {
                    icon: "󰌾"
                    label: "Bloquear"
                    hint: "1"
                    accentColor: root.accent
                    onActivated: root.runAction("lock")
                }
                PowerButton {
                    icon: "󰗽"
                    label: "Cerrar sesión"
                    hint: "2"
                    accentColor: root.warn
                    onActivated: root.runAction("logout")
                }
                PowerButton {
                    icon: "󰜉"
                    label: "Reiniciar"
                    hint: "3"
                    accentColor: root.warn
                    onActivated: root.runAction("reboot")
                }
                PowerButton {
                    icon: "󰐥"
                    label: "Apagar"
                    hint: "4"
                    accentColor: root.danger
                    onActivated: root.runAction("shutdown")
                }
            }
        }
    }

    // Botón grande reutilizable
    component PowerButton: Item {
        id: btn
        property string icon: ""
        property string label: ""
        property string hint: ""
        property color accentColor: root.accent
        signal activated()

        Layout.preferredWidth: 140
        Layout.preferredHeight: 160

        Rectangle {
            id: circle
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: 100
            height: 100
            radius: 50
            color: ma.containsMouse ? Qt.rgba(btn.accentColor.r, btn.accentColor.g, btn.accentColor.b, 0.35)
                                    : root.btnBg
            border.color: ma.containsMouse ? btn.accentColor : root.btnBorder
            border.width: ma.containsMouse ? 2 : 1

            Behavior on color {
                ColorAnimation { duration: 120 }
            }
            Behavior on border.color {
                ColorAnimation { duration: 120 }
            }

            // Escala al hover
            scale: ma.pressed ? 0.94 : (ma.containsMouse ? 1.06 : 1)
            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            Text {
                anchors.centerIn: parent
                text: btn.icon
                color: ma.containsMouse ? btn.accentColor : root.textPrimary
                font.pixelSize: 40
                Behavior on color {
                    ColorAnimation { duration: 120 }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: circle.bottom
            anchors.topMargin: 14
            text: btn.label
            color: root.textPrimary
            font.pixelSize: 14
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: circle.bottom
            anchors.topMargin: 34
            text: btn.hint
            color: root.textSecondary
            font.pixelSize: 11
            opacity: 0.7
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // Evitar que el click cierre el menú por el backdrop
            onClicked: {
                mouse.accepted = true
                btn.activated()
            }
        }
    }

    IpcHandler {
        target: "powermenu"

        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }
}
