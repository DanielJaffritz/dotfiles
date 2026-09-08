import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.bar.widgets

Scope {
    id: root

    property bool barVisible: true
    property int barHeight: 36
    property int pillHeight: 26
    property int pillRadius: 13
    property int spacing: 6
    property string fontFamily: "sans-serif"

    // Colores (mismo estilo que wallpaper / launcher)
    readonly property color bgBar: "#cc1a1a1a"
    readonly property color bgPill: "#33ffffff"
    readonly property color bgPillHover: "#44ffffff"
    readonly property color bgAccent: "#55ffffff"
    readonly property color borderColor: "#44ffffff"
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#aaffffff"
    readonly property color textMuted: "#66ffffff"
    readonly property color accent: "#c0e0ff"

    IpcHandler {
        target: "bar"
        function toggle(): void { root.barVisible = !root.barVisible; }
        function show(): void { root.barVisible = true; }
        function hide(): void { root.barVisible = false; }
    }

    // Una barra por monitor
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            visible: root.barVisible

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: root.barHeight
            color: "transparent"
            exclusiveZone: root.barHeight

            WlrLayershell.layer: WlrLayer.Top

            Rectangle {
                anchors.fill: parent
                color: root.bgBar
                border.color: root.borderColor
                border.width: 0

                // Línea inferior sutil
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: root.borderColor
                }

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10

                    // ─── IZQUIERDA: Workspaces ───────────────────────────────
                    Workspaces {} 

                    // ─── CENTRO: Media ───────────────────────────────────────
                    MediaWidget {} 

                    // ─── DERECHA: System indicators ──────────────────────────
                    Row {
                        id: rightSection
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.spacing

                        // Network
                        Network {} 

                        // Bluetooth
                        Bluetooth {}

                        // Brightness
                        Brightness {}  

                        // Audio
                        Audio {} 

                        // Battery
                        Battery {} 

                        // Clock
                        Clock {} 
                    }
                }
            }
        }
    }
}
