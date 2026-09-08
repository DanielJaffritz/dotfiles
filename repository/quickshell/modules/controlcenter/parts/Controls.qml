import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services.audio
import qs.services.network
import qs.services.system
Item {
readonly property color bgPanel: "#ee141414"
    readonly property color bgCard: "#22ffffff"
    readonly property color bgCardHover: "#33ffffff"
    readonly property color borderColor: "#44ffffff"
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#aaffffff"
    readonly property color textMuted: "#66ffffff"
    readonly property color accent: "#c0e0ff"
    readonly property color accentWarm: "#ffcc66"


                      id: controlesTab

                        property string expandedTile: ""  // "" | "wifi" | "bluetooth"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            // ── Sliders: Audio + Brillo ──
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: slidersCol.implicitHeight + 20
                                radius: 14
                                color: root.bgCard
                                border.color: root.borderColor
                                border.width: 1

                                ColumnLayout {
                                    id: slidersCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    spacing: 14

                                    // Audio
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Text {
                                            text: AudioService.icon
                                            color: AudioService.muted ? "#ff8888" : root.accent
                                            font.pixelSize: 18
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: AudioService.toggleMute()
                                            }
                                        }

                                        Slider {
                                            id: volSlider
                                            Layout.fillWidth: true
                                            from: 0
                                            to: 1
                                            value: Math.min(1, AudioService.volume)
                                            onMoved: AudioService.setVolume(value)

                                            background: Rectangle {
                                                x: volSlider.leftPadding
                                                y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                                                width: volSlider.availableWidth
                                                height: 6
                                                radius: 3
                                                color: "#33ffffff"
                                                Rectangle {
                                                    width: volSlider.visualPosition * parent.width
                                                    height: parent.height
                                                    radius: 3
                                                    color: AudioService.muted ? "#88ff6666" : root.accent
                                                }
                                            }
                                        }

                                        Text {
                                            text: AudioService.muted ? "Mute" : (AudioService.volumePercent + "%")
                                            color: root.textSecondary
                                            font.pixelSize: 12
                                            Layout.preferredWidth: 42
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }

                                    // Brillo
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10
                                        visible: BrightnessService.available

                                        Text {
                                            text: BrightnessService.icon
                                            color: root.accentWarm
                                            font.pixelSize: 18
                                        }

                                        Slider {
                                            id: brightSlider
                                            Layout.fillWidth: true
                                            from: 0.01
                                            to: 1
                                            value: Math.max(0.01, BrightnessService.value)
                                            onMoved: BrightnessService.set(value)

                                            background: Rectangle {
                                                x: brightSlider.leftPadding
                                                y: brightSlider.topPadding + brightSlider.availableHeight / 2 - height / 2
                                                width: brightSlider.availableWidth
                                                height: 6
                                                radius: 3
                                                color: "#33ffffff"
                                                Rectangle {
                                                    width: brightSlider.visualPosition * parent.width
                                                    height: parent.height
                                                    radius: 3
                                                    color: root.accentWarm
                                                }
                                            }
                                        }

                                        Text {
                                            text: BrightnessService.percent + "%"
                                            color: root.textSecondary
                                            font.pixelSize: 12
                                            Layout.preferredWidth: 42
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }

                            // ── Tiles 2x2 ──
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 8
                                columnSpacing: 8

                                // Wi‑Fi
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 72
                                    radius: 14
                                    color: NetworkService.wifiEnabled && !NetworkService.airplaneMode ? "#3355aaff" : root.bgCard
                                    border.color: NetworkService.wifiEnabled && !NetworkService.airplaneMode ? "#66aaccff" : root.borderColor
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        Text {
                                            text: NetworkService.icon
                                            color: root.textPrimary
                                            font.pixelSize: 22
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text {
                                                text: "Wi‑Fi"
                                                color: root.textPrimary
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: NetworkService.airplaneMode ? "Modo avión" :
                                                      (!NetworkService.wifiEnabled ? "Apagado" :
                                                      (NetworkService.connected ? (NetworkService.ssid || "Conectado") : "Activado"))
                                                color: root.textSecondary
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }

                                        // Expandir
                                        Text {
                                            text: controlesTab.expandedTile === "wifi" ? "󰅃" : "󰅀"
                                            color: root.textMuted
                                            font.pixelSize: 16
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -8
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (controlesTab.expandedTile === "wifi")
                                                        controlesTab.expandedTile = "";
                                                    else {
                                                        controlesTab.expandedTile = "wifi";
                                                        NetworkService.scan();
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.rightMargin: 40
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.RightButton) {
                                                controlesTab.expandedTile = controlesTab.expandedTile === "wifi" ? "" : "wifi";
                                                if (controlesTab.expandedTile === "wifi")
                                                    NetworkService.scan();
                                            } else {
                                                NetworkService.toggleWifi();
                                            }
                                        }
                                        onPressAndHold: {
                                            controlesTab.expandedTile = controlesTab.expandedTile === "wifi" ? "" : "wifi";
                                            if (controlesTab.expandedTile === "wifi")
                                                NetworkService.scan();
                                        }
                                    }
                                }

                                // Bluetooth
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 72
                                    radius: 14
                                    color: BluetoothService.powered && !NetworkService.airplaneMode ? "#3355aaff" : root.bgCard
                                    border.color: BluetoothService.powered && !NetworkService.airplaneMode ? "#66aaccff" : root.borderColor
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        Text {
                                            text: BluetoothService.icon
                                            color: root.textPrimary
                                            font.pixelSize: 22
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text {
                                                text: "Bluetooth"
                                                color: root.textPrimary
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: NetworkService.airplaneMode ? "Modo avión" :
                                                      (!BluetoothService.powered ? "Apagado" :
                                                      (BluetoothService.connectedCount > 0 ? (BluetoothService.connectedName || (BluetoothService.connectedCount + " conectado(s)")) : "Activado"))
                                                color: root.textSecondary
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Text {
                                            text: controlesTab.expandedTile === "bluetooth" ? "󰅃" : "󰅀"
                                            color: root.textMuted
                                            font.pixelSize: 16
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -8
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (controlesTab.expandedTile === "bluetooth")
                                                        controlesTab.expandedTile = "";
                                                    else {
                                                        controlesTab.expandedTile = "bluetooth";
                                                        BluetoothService.startScan();
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.rightMargin: 40
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.RightButton) {
                                                controlesTab.expandedTile = controlesTab.expandedTile === "bluetooth" ? "" : "bluetooth";
                                                if (controlesTab.expandedTile === "bluetooth")
                                                    BluetoothService.startScan();
                                            } else {
                                                BluetoothService.toggle();
                                            }
                                        }
                                        onPressAndHold: {
                                            controlesTab.expandedTile = controlesTab.expandedTile === "bluetooth" ? "" : "bluetooth";
                                            if (controlesTab.expandedTile === "bluetooth")
                                                BluetoothService.startScan();
                                        }
                                    }
                                }

                                // Modo avión
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 72
                                    radius: 14
                                    color: NetworkService.airplaneMode ? "#55aa7733" : root.bgCard
                                    border.color: NetworkService.airplaneMode ? "#88ffaa66" : root.borderColor
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        Text {
                                            text: "󰀝"
                                            color: root.textPrimary
                                            font.pixelSize: 22
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text {
                                                text: "Modo avión"
                                                color: root.textPrimary
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                            Text {
                                                text: NetworkService.airplaneMode ? "Activado" : "Desactivado"
                                                color: root.textSecondary
                                                font.pixelSize: 11
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NetworkService.toggleAirplane()
                                    }
                                }

                                // Modo noche (gammastep)
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 72
                                    radius: 14
                                    color: NightMode.enabled ? "#55443322" : root.bgCard
                                    border.color: NightMode.enabled ? "#88ffcc66" : root.borderColor
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        Text {
                                            text: NightMode.icon
                                            color: NightMode.enabled ? root.accentWarm : root.textPrimary
                                            font.pixelSize: 22
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text {
                                                text: "Modo noche"
                                                color: root.textPrimary
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                            Text {
                                                text: NightMode.enabled ? ("Activado · " + NightMode.temperature + "K") : "Desactivado"
                                                color: root.textSecondary
                                                font.pixelSize: 11
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NightMode.toggle()
                                    }
                                }
                            }

                            // ── Panel expandido Wi‑Fi ──
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: controlesTab.expandedTile === "wifi"
                                radius: 14
                                color: root.bgCard
                                border.color: root.borderColor
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "Redes Wi‑Fi"
                                            color: root.textPrimary
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                        Text {
                                            text: NetworkService.savedNetworks.length > 0
                                                  ? (NetworkService.savedNetworks.length + " guardada" + (NetworkService.savedNetworks.length === 1 ? "" : "s"))
                                                  : ""
                                            color: root.textMuted
                                            font.pixelSize: 11
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: NetworkService.scanning ? "Buscando…" : "󰑐"
                                            color: root.textSecondary
                                            font.pixelSize: 13
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -6
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: NetworkService.scan()
                                            }
                                        }
                                    }

                                    // Redes visibles (escaneo)
                                    ListView {
                                        id: wifiScanList
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        Layout.preferredHeight: 1
                                        clip: true
                                        spacing: 4
                                        model: NetworkService.networks

                                        delegate: Rectangle {
                                            required property var modelData
                                            width: ListView.view.width
                                            height: 44
                                            radius: 8
                                            color: modelData.inUse ? "#3355aaff" : (netMouse.containsMouse ? "#22ffffff" : "transparent")

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 8
                                                spacing: 8

                                                Text {
                                                    text: modelData.bars >= 4 ? "󰤨" : modelData.bars >= 3 ? "󰤥" : modelData.bars >= 2 ? "󰤢" : "󰤟"
                                                    color: root.textSecondary
                                                    font.pixelSize: 14
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 1
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: modelData.ssid
                                                        color: root.textPrimary
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight
                                                    }
                                                    Text {
                                                        text: modelData.saved ? "Guardada" : (modelData.security && modelData.security !== "--" ? modelData.security : "Abierta")
                                                        color: modelData.saved ? root.accent : root.textMuted
                                                        font.pixelSize: 10
                                                    }
                                                }

                                                Text {
                                                    text: modelData.security && modelData.security !== "--" ? "󰌾" : ""
                                                    color: root.textMuted
                                                    font.pixelSize: 12
                                                }

                                                Text {
                                                    text: NetworkService.busySsid === modelData.ssid ? "…" :
                                                          (modelData.inUse ? "Conectado" : "Conectar")
                                                    color: modelData.inUse ? root.accent : root.textSecondary
                                                    font.pixelSize: 11
                                                }

                                                // Olvidar (solo si está guardada)
                                                Text {
                                                    text: "󰧧"
                                                    color: forgetMouse.containsMouse ? "#ff8888" : root.textMuted
                                                    font.pixelSize: 14
                                                    visible: modelData.saved
                                                    MouseArea {
                                                        id: forgetMouse
                                                        anchors.fill: parent
                                                        anchors.margins: -6
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: NetworkService.forget(modelData.connectionName || modelData.ssid)
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                id: netMouse
                                                anchors.fill: parent
                                                anchors.rightMargin: modelData.saved ? 36 : 0
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                onClicked: (mouse) => {
                                                    if (mouse.button === Qt.RightButton && modelData.saved) {
                                                        NetworkService.forget(modelData.connectionName || modelData.ssid);
                                                        return;
                                                    }
                                                    if (modelData.inUse)
                                                        NetworkService.disconnect();
                                                    else
                                                        NetworkService.connectTo(modelData.ssid);
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: NetworkService.networks.length === 0
                                            text: NetworkService.scanning ? "Escaneando redes…" :
                                                  (!NetworkService.wifiEnabled ? "Wi‑Fi apagado" : "Sin redes · pulsa 󰑐")
                                            color: root.textMuted
                                            font.pixelSize: 12
                                        }
                                    }

                                    // Separador + redes guardadas fuera de alcance
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 1
                                        color: root.borderColor
                                        visible: NetworkService.savedOutOfRange.length > 0
                                    }

                                    Text {
                                        text: "Guardadas (fuera de alcance)"
                                        color: root.textMuted
                                        font.pixelSize: 11
                                        visible: NetworkService.savedOutOfRange.length > 0
                                    }

                                    ListView {
                                        id: savedOutOfRangeList
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: Math.min(NetworkService.savedOutOfRange.length * 40, 120)
                                        clip: true
                                        spacing: 4
                                        visible: NetworkService.savedOutOfRange.length > 0
                                        model: NetworkService.savedOutOfRange

                                        delegate: Rectangle {
                                            required property var modelData
                                            width: ListView.view.width
                                            height: 36
                                            radius: 8
                                            color: savedMouse.containsMouse ? "#22ffffff" : "transparent"

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 8
                                                spacing: 8

                                                Text {
                                                    text: "󰌪"
                                                    color: root.textMuted
                                                    font.pixelSize: 14
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.ssid || modelData.name
                                                    color: root.textSecondary
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    text: NetworkService.busySsid === modelData.name || NetworkService.busySsid === modelData.ssid
                                                          ? "…" : "Conectar"
                                                    color: root.textSecondary
                                                    font.pixelSize: 11
                                                }
                                                Text {
                                                    text: "󰧧"
                                                    color: forgetSavedMouse.containsMouse ? "#ff8888" : root.textMuted
                                                    font.pixelSize: 14
                                                    MouseArea {
                                                        id: forgetSavedMouse
                                                        anchors.fill: parent
                                                        anchors.margins: -6
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: NetworkService.forgetUuid(modelData.uuid)
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                id: savedMouse
                                                anchors.fill: parent
                                                anchors.rightMargin: 36
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: NetworkService.connectSaved(modelData.name)
                                            }
                                        }
                                    }
                                }
                            }

                            // ── Panel expandido Bluetooth ──
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: controlesTab.expandedTile === "bluetooth"
                                radius: 14
                                color: root.bgCard
                                border.color: root.borderColor
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "Dispositivos Bluetooth"
                                            color: root.textPrimary
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: BluetoothService.discovering ? "Buscando…" : "󰑐"
                                            color: root.textSecondary
                                            font.pixelSize: 13
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -6
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: BluetoothService.startScan()
                                            }
                                        }
                                    }

                                    ListView {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        spacing: 4
                                        model: BluetoothService.allDevices

                                        delegate: Rectangle {
                                            required property var modelData
                                            width: ListView.view.width
                                            height: 40
                                            radius: 8
                                            color: modelData.connected ? "#3355aaff" : (btMouse.containsMouse ? "#22ffffff" : "transparent")

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 8

                                                Text {
                                                    text: modelData.connected ? "󰂱" : "󰂯"
                                                    color: root.textSecondary
                                                    font.pixelSize: 14
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.name || modelData.mac
                                                    color: root.textPrimary
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    text: BluetoothService.busyMac === modelData.mac ? "…" :
                                                          (modelData.connected ? "Desconectar" : "Conectar")
                                                    color: modelData.connected ? "#ffaaaa" : root.accent
                                                    font.pixelSize: 11
                                                }
                                            }

                                            MouseArea {
                                                id: btMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.connected)
                                                        BluetoothService.disconnectDevice(modelData.mac);
                                                    else
                                                        BluetoothService.connectDevice(modelData.mac);
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: BluetoothService.allDevices.length === 0
                                            text: BluetoothService.discovering ? "Escaneando…" :
                                                  (!BluetoothService.powered ? "Bluetooth apagado" : "Sin dispositivos · pulsa 󰑐")
                                            color: root.textMuted
                                            font.pixelSize: 12
                                        }
                                    }
                                }
                            }

                            // Espaciador si no hay panel expandido
                            Item {
                                Layout.fillHeight: true
                                visible: controlesTab.expandedTile === ""
                            }
                        }
                    }
