import Quickshell
import QtQuick
import qs.services.audio
Rectangle {
                        id: mediaPill
                        anchors.centerIn: parent
                        height: root.pillHeight
                        width: mediaRow.implicitWidth + 16
                        radius: root.pillRadius
                        color: root.bgPill
                        visible: MediaService.available
                        border.color: MediaService.playing ? "#55aaccff" : "transparent"
                        border.width: MediaService.playing ? 1 : 0

                        Row {
                            id: mediaRow
                            anchors.centerIn: parent
                            spacing: 8

                            // Prev
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰒮"
                                color: root.textSecondary
                                font.pixelSize: 13
                                font.family: root.fontFamily
                                opacity: 0.8

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MediaService.previous()
                                }
                            }

                            // Play / Pause
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: MediaService.icon
                                color: root.accent
                                font.pixelSize: 14
                                font.family: root.fontFamily

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MediaService.toggle()
                                }
                            }

                            // Next
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰒭"
                                color: root.textSecondary
                                font.pixelSize: 13
                                font.family: root.fontFamily
                                opacity: 0.8

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MediaService.next()
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: MediaService.display
                                color: root.textPrimary
                                font.pixelSize: 12
                                font.family: root.fontFamily
                                elide: Text.ElideRight
                                width: Math.min(implicitWidth, 280)
                            }
                        }

                        // Click en el resto del pill también toggle play
                        MouseArea {
                            anchors.fill: parent
                            z: -1
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MediaService.toggle()
                        }
                    }
