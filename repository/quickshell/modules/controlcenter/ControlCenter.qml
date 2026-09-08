import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.controlcenter.parts
import qs.services.network
import qs.services.audio
import qs.services.system
import qs.services

Scope {
    id: root

    property bool panelOpen: GlobalState.isControlCenterOpen
    property string activeTab: "inicio"  // inicio | controles | sistema

       // Colores (mismo lenguaje visual)
    readonly property color bgPanel: "#ee141414"
    readonly property color bgCard: "#22ffffff"
    readonly property color bgCardHover: "#33ffffff"
    readonly property color borderColor: "#44ffffff"
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#aaffffff"
    readonly property color textMuted: "#66ffffff"
    readonly property color accent: "#c0e0ff"
    readonly property color accentWarm: "#ffcc66"

    signal closeRequested()

    // Hostname
    Process {
        id: hostProc
        command: ["hostname"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const h = text.trim();
                if (h !== "")
                    root.hostName = h;
            }
        }
    }

    function open() {
        panelOpen = true;
    }
    onActiveTabChanged: {
        if (activeTab === "controles") {
            NetworkService.refresh();
            BluetoothService.refresh();
            NightMode.refresh();
            if (controlesTab && controlesTab.expandedTile === "wifi")
                NetworkService.scan();
            if (controlesTab && controlesTab.expandedTile === "bluetooth")
                BluetoothService.startScan();
        } else if (activeTab === "sistema") {
            System.refresh();
        }
    }


    function close() {
        panelOpen = false;
        closeRequested();
    }

    function toggle() {
        if (panelOpen)
            close();
        else
            open();
    }

    // Actualizar posición de media cada segundo mientras el panel está abierto
    Timer {
        interval: 1000
        running: root.panelOpen && MediaService.available && MediaService.playing
        repeat: true
        onTriggered: {
            // Forzar reevaluación leyendo position
            mediaProgress.progress = MediaService.length > 0 ? (MediaService.position / MediaService.length) : 0;
        }
    }

    PanelWindow {
        id: panel
        visible: root.panelOpen

        anchors {
            top: true
            left: true
            right: true
        }

        margins {
            top: 8
            left: 16
            right: 16
        }

        implicitHeight: Math.min(520, Screen.height * 0.55)
        color: "transparent"
        exclusiveZone: 0
        focusable: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        // Click fuera para cerrar (área transparente no cubre toda la pantalla fácilmente;
        // Esc cierra)
        Item {
            anchors.fill: parent
            focus: root.panelOpen

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close();
                    event.accepted = true;
                }
            }
        }

        Rectangle {
            id: container
            anchors.fill: parent
            radius: 16
            color: root.bgPanel
            border.color: root.borderColor
            border.width: 1
            clip: true

            // Entrada desde arriba
            transform: Translate {
                id: slideY
                y: root.panelOpen ? 0 : -40
            }
            opacity: root.panelOpen ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
            }
            Behavior on y {
                // no aplica a transform directamente; animamos slideY
            }

            NumberAnimation {
                id: slideAnim
                target: slideY
                property: "y"
                duration: 200
                easing.type: Easing.OutCubic
            }

            Connections {
                target: root
                function onPanelOpenChanged() {
                    slideAnim.to = root.panelOpen ? 0 : -40;
                    slideAnim.start();
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // ─── Barra de pestañas ───────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "inicio", label: "Start" },
                            { id: "controles", label: "Control" },
                            { id: "sistema", label: "System" }
                        ]

                        Rectangle {
                            required property var modelData
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: tabText.implicitWidth + 24
                            radius: 10
                            color: root.activeTab === modelData.id ? "#44ffffff" : "transparent"
                            border.color: root.activeTab === modelData.id ? "#66ffffff" : "transparent"
                            border.width: 1

                            Text {
                                id: tabText
                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.activeTab === modelData.id ? root.textPrimary : root.textSecondary
                                font.pixelSize: 13
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

                    // Cerrar
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 10
                        color: closeMouse.containsMouse ? "#44ff6666" : "#22ffffff"

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: root.textPrimary
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: closeMouse
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
                }

                // ─── Contenido de pestañas ───────────────────────────────────
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: {
                        if (root.activeTab === "inicio") return 0;
                        if (root.activeTab === "controles") return 1;
                        return 2;
                    }

                    // ========== PESTAÑA INICIO ==========
                    Start {} 

                    // ========== PESTAÑA CONTROLES (placeholder) ==========
                    Controls {} 

                    // ========== PESTAÑA SISTEMA (placeholder) ==========
                   SystemInfo {} 
                }
            }
        }
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function tab(name: string): void {
            if (name === "inicio" || name === "controles" || name === "sistema")
                root.activeTab = name;
            root.open();
        }
    }
}
