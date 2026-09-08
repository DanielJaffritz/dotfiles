import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services.audio
import qs.services.network
Item {
  id:root
    readonly property color bgPanel: "#ee141414"
    readonly property color bgCard: "#22ffffff"
    readonly property color bgCardHover: "#33ffffff"
    readonly property color borderColor: "#44ffffff"
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#aaffffff"
    readonly property color textMuted: "#66ffffff"
    readonly property color accent: "#c0e0ff"
    readonly property color accentWarm: "#ffcc66"


    property string avatarPath: Qt.resolvedUrl("/usr/share/sddm/themes/pixie/assets/avatar.jpg")

    property string userName: Quickshell.env("USER") || "Torvalds"
    property string hostName: "linux"


                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            // Fila superior: Usuario (pequeño) + Media + Calendario
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                // ── User card (la más pequeña) ──
                                Rectangle {
                                    Layout.preferredWidth: 120
                                    Layout.fillHeight: true
                                    radius: 14
                                    color: root.bgCard
                                    border.color: root.borderColor
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 8

                                        // Avatar
                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.preferredWidth: 56
                                            Layout.preferredHeight: 56
                                            radius: 28
                                            color: "#33ffffff"
                                            clip: true

                                            Image {
                                                id: avatarImg
                                                anchors.fill: parent
                                                source: root.avatarPath
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                visible: status === Image.Ready
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: (root.userName[0] || "?").toUpperCase()
                                                color: root.textPrimary
                                                font.pixelSize: 22
                                                font.bold: true
                                                visible: avatarImg.status !== Image.Ready
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: root.userName
                                            color: root.textPrimary
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: root.hostName
                                            color: root.textMuted
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        Item { Layout.fillHeight: true }
                                    }
                                }

                                // ── Media panel ──
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 14
                                    color: root.bgCard
                                    border.color: root.borderColor
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 8

                                        Text {
                                            text: "Reproduciendo"
                                            color: root.textMuted
                                            font.pixelSize: 11
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            // Art
                                            Rectangle {
                                                Layout.preferredWidth: 48
                                                Layout.preferredHeight: 48
                                                radius: 8
                                                color: "#33ffffff"
                                                clip: true

                                                Image {
                                                    anchors.fill: parent
                                                    source: MediaService.artUrl
                                                    fillMode: Image.PreserveAspectCrop
                                                    asynchronous: true
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: MediaService.available ? "󰎆" : "󰝛"
                                                    color: root.textSecondary
                                                    font.pixelSize: 20
                                                    visible: !MediaService.artUrl || MediaService.artUrl === ""
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: MediaService.available ? (MediaService.title || "Sin título") : "Nada en reproducción"
                                                    color: root.textPrimary
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: Media.artist || ""
                                                    color: root.textSecondary
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                    visible: text !== ""
                                                }
                                            }
                                        }

                                        // Progress
                                        Rectangle {
                                            id: mediaProgress
                                            property real progress: MediaService.length > 0 ? (MediaService.position / MediaService.length) : 0

                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 4
                                            radius: 2
                                            color: "#33ffffff"
                                            visible: MediaService.available

                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                width: parent.width * Math.min(1, Math.max(0, mediaProgress.progress))
                                                radius: 2
                                                color: root.accent
                                            }
                                        }

                                        // Controls
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignHCenter
                                            spacing: 16
                                            visible: Media.available

                                            Text {
                                                text: "󰒮"
                                                color: root.textSecondary
                                                font.pixelSize: 18
                                                MouseArea {
                                                    anchors.fill: parent
                                                    anchors.margins: -6
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: MediaService.previous()
                                                }
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 36
                                                Layout.preferredHeight: 36
                                                radius: 18
                                                color: "#44ffffff"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: MediaService.playing ? "󰏤" : "󰐊"
                                                    color: root.textPrimary
                                                    font.pixelSize: 16
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: MediaService.toggle()
                                                }
                                            }

                                            Text {
                                                text: "󰒭"
                                                color: root.textSecondary
                                                font.pixelSize: 18
                                                MouseArea {
                                                    anchors.fill: parent
                                                    anchors.margins: -6
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: MediaService.next()
                                                }
                                            }
                                        }

                                        Item {
                                            Layout.fillHeight: true
                                            visible: !MediaService.available
                                        }
                                    }
                                }

                                // ── Calendario sencillo ──
                                Rectangle {
                                    Layout.preferredWidth: 150
                                    Layout.fillHeight: true
                                    radius: 14
                                    color: root.bgCard
                                    border.color: root.borderColor
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: {
                                                const d = new Date();
                                                return Qt.formatDate(d, "dddd");
                                            }
                                            color: root.textMuted
                                            font.pixelSize: 12
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: {
                                                const d = new Date();
                                                return Qt.formatDate(d, "d");
                                            }
                                            color: root.accent
                                            font.pixelSize: 42
                                            font.bold: true
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: {
                                                const d = new Date();
                                                return Qt.formatDate(d, "MMMM yyyy");
                                            }
                                            color: root.textPrimary
                                            font.pixelSize: 13
                                        }
                                    }
                                }
                            }

                            // ── Notificaciones (mayor espacio) ──
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
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
                                            text: "Notificaciones"
                                            color: root.textPrimary
                                            font.pixelSize: 14
                                            font.bold: true
                                        }

                                        Text {
                                            text: NotificationsService.count > 0 ? ("(" + NotificationsService.count + ")") : ""
                                            color: root.textMuted
                                            font.pixelSize: 12
                                        }

                                        Item { Layout.fillWidth: true }

                                        // DND
                                        Rectangle {
                                            Layout.preferredHeight: 26
                                            Layout.preferredWidth: dndText.implicitWidth + 16
                                            radius: 8
                                            color: NotificationsService.doNotDisturb ? "#55ff8866" : "#22ffffff"

                                            Text {
                                                id: dndText
                                                anchors.centerIn: parent
                                                text: NotificationsService.doNotDisturb ? "DND" : "DND"
                                                color: NotificationsService.doNotDisturb ? root.textPrimary : root.textMuted
                                                font.pixelSize: 11
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: NotificationsService.toggleDnd()
                                            }
                                        }

                                        // Vaciar
                                        Rectangle {
                                            Layout.preferredHeight: 26
                                            Layout.preferredWidth: clearText.implicitWidth + 16
                                            radius: 8
                                            color: clearMouse.containsMouse ? "#44ff6666" : "#22ffffff"
                                            visible: NotificationsService.count > 0

                                            Text {
                                                id: clearText
                                                anchors.centerIn: parent
                                                text: "Vaciar"
                                                color: root.textSecondary
                                                font.pixelSize: 11
                                            }

                                            MouseArea {
                                                id: clearMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: NotificationsService.dismissAll()
                                            }
                                        }
                                    }

                                    ListView {
                                        id: notifList
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        spacing: 6
                                        model: NotificationsService.list

                                        ScrollBar.vertical: ScrollBar {
                                            policy: ScrollBar.AsNeeded
                                            width: 4
                                        }

                                        delegate: Rectangle {
                                            id: notifCard
                                            required property int index
                                            required property var modelData

                                            width: notifList.width
                                            height: notifCol.implicitHeight + 16
                                            radius: 10
                                            color: "#18ffffff"
                                            border.color: "#22ffffff"
                                            border.width: 1

                                            RowLayout {
                                                id: notifCol
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.top: parent.top
                                                anchors.margins: 8
                                                spacing: 10

                                                // Icono
                                                Rectangle {
                                                    Layout.preferredWidth: 36
                                                    Layout.preferredHeight: 36
                                                    Layout.alignment: Qt.AlignTop
                                                    radius: 8
                                                    color: "#33ffffff"
                                                    clip: true

                                                    Image {
                                                        anchors.fill: parent
                                                        anchors.margins: 2
                                                        source: NotificationsService.iconSource(modelData)
                                                        fillMode: Image.PreserveAspectFit
                                                        asynchronous: true
                                                        visible: status === Image.Ready
                                                    }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "󰂚"
                                                        color: root.textSecondary
                                                        font.pixelSize: 16
                                                        visible: parent.children[0].status !== Image.Ready
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: modelData.appName || "Aplicación"
                                                        color: root.textMuted
                                                        font.pixelSize: 10
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: modelData.summary || ""
                                                        color: root.textPrimary
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                        elide: Text.ElideRight
                                                        wrapMode: Text.Wrap
                                                        maximumLineCount: 2
                                                    }

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: modelData.body || ""
                                                        color: root.textSecondary
                                                        font.pixelSize: 11
                                                        elide: Text.ElideRight
                                                        wrapMode: Text.Wrap
                                                        maximumLineCount: 3
                                                        visible: text !== ""
                                                    }
                                                }

                                                // Dismiss
                                                Text {
                                                    Layout.alignment: Qt.AlignTop
                                                    text: "󰅖"
                                                    color: root.textMuted
                                                    font.pixelSize: 14

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        anchors.margins: -6
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: NotificationsService.dismiss(modelData)
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Sin notificaciones"
                                            color: root.textMuted
                                            font.pixelSize: 13
                                            visible: NotificationsService.count === 0
                                        }
                                    }
                                }
                            }
                        }
                    }
