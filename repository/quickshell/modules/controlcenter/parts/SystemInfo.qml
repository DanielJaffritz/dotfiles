import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
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


                        id: sistemaTab

                        // Helper de barra de progreso reutilizable
                        component UsageBar: Rectangle {
                            property real value: 0
                            property color fillColor: root.accent

                            height: 6
                            radius: 3
                            color: "#33ffffff"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * Math.min(1, Math.max(0, parent.value))
                                radius: 3
                                color: {
                                    if (parent.value >= 0.9)
                                        return "#ff6666";
                                    if (parent.value >= 0.75)
                                        return root.accentWarm;
                                    return parent.fillColor;
                                }
                                Behavior on width {
                                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        Flickable {
                            anchors.fill: parent
                            contentWidth: width
                            contentHeight: sistemaCol.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: sistemaCol
                                width: parent.width
                                spacing: 10

                                // ── Resumen: OS / host / uptime ──
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: summaryCol.implicitHeight + 24
                                    radius: 14
                                    color: root.bgCard
                                    border.color: root.borderColor
                                    border.width: 1

                                    ColumnLayout {
                                        id: summaryCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 12
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8
                                            Text {
                                                text: "󰣇"
                                                color: root.accent
                                                font.pixelSize: 20
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: System.osName || "Linux"
                                                    color: root.textPrimary
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: (System.hostname || "host") + " · " + (System.kernel || "") + " · " + (System.architecture || "")
                                                    color: root.textMuted
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 16

                                            RowLayout {
                                                spacing: 6
                                                Text { text: "󰔟"; color: root.textSecondary; font.pixelSize: 14 }
                                                Text {
                                                    text: "Uptime " + (System.uptimeText || "—")
                                                    color: root.textSecondary
                                                    font.pixelSize: 12
                                                }
                                            }

                                            RowLayout {
                                                spacing: 6
                                                Text { text: "󰻠"; color: root.textSecondary; font.pixelSize: 14 }
                                                Text {
                                                    text: System.processCount + " procesos"
                                                    color: root.textSecondary
                                                    font.pixelSize: 12
                                                }
                                            }

                                            RowLayout {
                                                spacing: 6
                                                Text { text: "󰓅"; color: root.textSecondary; font.pixelSize: 14 }
                                                Text {
                                                    text: System.load1.toFixed(2) + " / " + System.load5.toFixed(2) + " / " + System.load15.toFixed(2)
                                                    color: root.textSecondary
                                                    font.pixelSize: 12
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── CPU + RAM (fila) ──
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    // CPU
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: cpuCol.implicitHeight + 24
                                        radius: 14
                                        color: root.bgCard
                                        border.color: root.borderColor
                                        border.width: 1

                                        ColumnLayout {
                                            id: cpuCol
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 12
                                            spacing: 8

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text {
                                                    text: "CPU"
                                                    color: root.textPrimary
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                }
                                                Item { Layout.fillWidth: true }
                                                Text {
                                                    text: System.cpuPercent + "%"
                                                    color: System.cpuPercent >= 90 ? "#ff6666" : root.accent
                                                    font.pixelSize: 16
                                                    font.bold: true
                                                }
                                            }

                                            UsageBar {
                                                Layout.fillWidth: true
                                                value: System.cpuUsage
                                                fillColor: root.accent
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: {
                                                    let t = System.cpuCores > 0 ? (System.cpuCores + " núcleos") : "";
                                                    if (System.cpuFreqMhz > 0)
                                                        t += (t ? " · " : "") + Math.round(System.cpuFreqMhz) + " MHz";
                                                    return t || "—";
                                                }
                                                color: root.textMuted
                                                font.pixelSize: 11
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: System.cpuModel || ""
                                                color: root.textSecondary
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                                maximumLineCount: 2
                                                wrapMode: Text.Wrap
                                                visible: text !== ""
                                            }
                                        }
                                    }

                                    // RAM
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: ramCol.implicitHeight + 24
                                        radius: 14
                                        color: root.bgCard
                                        border.color: root.borderColor
                                        border.width: 1

                                        ColumnLayout {
                                            id: ramCol
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 12
                                            spacing: 8

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text {
                                                    text: "RAM"
                                                    color: root.textPrimary
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                }
                                                Item { Layout.fillWidth: true }
                                                Text {
                                                    text: System.memPercentInt + "%"
                                                    color: System.memPercentInt >= 90 ? "#ff6666" : root.accent
                                                    font.pixelSize: 16
                                                    font.bold: true
                                                }
                                            }

                                            UsageBar {
                                                Layout.fillWidth: true
                                                value: System.memPercent
                                                fillColor: root.accent
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: System.formatBytes(System.memUsed) + " / " + System.formatBytes(System.memTotal)
                                                color: root.textSecondary
                                                font.pixelSize: 11
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: System.swapTotal > 0
                                                      ? ("Swap " + System.formatBytes(System.swapUsed) + " / " + System.formatBytes(System.swapTotal))
                                                      : "Sin swap"
                                                color: root.textMuted
                                                font.pixelSize: 10
                                            }
                                        }
                                    }
                                }

                                // ── Disco ──
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: diskCol.implicitHeight + 24
                                    radius: 14
                                    color: root.bgCard
                                    border.color: root.borderColor
                                    border.width: 1

                                    ColumnLayout {
                                        id: diskCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 12
                                        spacing: 8

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: "Almacenamiento"
                                                color: root.textPrimary
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                            Text {
                                                text: System.diskFs || "/"
                                                color: root.textMuted
                                                font.pixelSize: 11
                                            }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: System.diskPercentInt + "%"
                                                color: System.diskPercentInt >= 90 ? "#ff6666" : root.accentWarm
                                                font.pixelSize: 16
                                                font.bold: true
                                            }
                                        }

                                        UsageBar {
                                            Layout.fillWidth: true
                                            value: System.diskPercent
                                            fillColor: root.accentWarm
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: System.formatBytes(System.diskUsed) + " usados"
                                                color: root.textSecondary
                                                font.pixelSize: 11
                                            }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: System.formatBytes(System.diskFree) + " libres · " + System.formatBytes(System.diskTotal) + " total"
                                                color: root.textMuted
                                                font.pixelSize: 11
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: System.diskDevice || ""
                                            color: root.textMuted
                                            font.pixelSize: 10
                                            elide: Text.ElideMiddle
                                            visible: text !== ""
                                        }
                                    }
                                }

                                // ── Batería (si aplica) ──
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: batCol.implicitHeight + 24
                                    radius: 14
                                    color: root.bgCard
                                    border.color: root.borderColor
                                    border.width: 1
                                    visible: BatteryService.isPresent

                                    ColumnLayout {
                                        id: batCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 12
                                        spacing: 8

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: "Batería"
                                                color: root.textPrimary
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: BatteryService.charging ? "󰂄" : (BatteryService.percent <= 15 ? "󰁺" : "󰁹")
                                                color: BatteryService.percent <= 15 && !BatteryService.charging ? "#ff6666" : root.accent
                                                font.pixelSize: 16
                                            }
                                            Text {
                                                text: BatteryService.percent + "%"
                                                color: BatteryService.percent <= 15 && !BatteryService.charging ? "#ff6666" : root.accent
                                                font.pixelSize: 16
                                                font.bold: true
                                            }
                                        }

                                        UsageBar {
                                            Layout.fillWidth: true
                                            value: BatteryService.percentage
                                            fillColor: BatteryService.charging ? "#66ff99" : root.accent
                                        }

                                        Text {
                                            text: BatteryService.charging ? "Cargando" : (BatteryService.onBattery ? "En batería" : "Conectado a la corriente")
                                            color: root.textSecondary
                                            font.pixelSize: 11
                                        }
                                    }
                                }

                                // ── Red rápida ──
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: netCol.implicitHeight + 24
                                    radius: 14
                                    color: root.bgCard
                                    border.color: root.borderColor
                                    border.width: 1

                                    ColumnLayout {
                                        id: netCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 12
                                        spacing: 6

                                        Text {
                                            text: "Red"
                                            color: root.textPrimary
                                            font.pixelSize: 13
                                            font.bold: true
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 12

                                            Text {
                                                text: NetworkService.icon
                                                color: root.textSecondary
                                                font.pixelSize: 18
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: NetworkService.connectionType === "ethernet" ? "Ethernet"
                                                          : (NetworkService.ssid || (NetworkService.wifiEnabled ? "Wi‑Fi" : "Sin red"))
                                                    color: root.textPrimary
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    text: NetworkService.ipAddress ? ("IP " + NetworkService.ipAddress) : (NetworkService.connected ? "Conectado" : "Desconectado")
                                                    color: root.textMuted
                                                    font.pixelSize: 11
                                                }
                                            }
                                            Text {
                                                text: NetworkService.signal > 0 ? (NetworkService.signal + "%") : ""
                                                color: root.textSecondary
                                                font.pixelSize: 12
                                                visible: NetworkService.connectionType === "wifi" && NetworkService.connected
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
