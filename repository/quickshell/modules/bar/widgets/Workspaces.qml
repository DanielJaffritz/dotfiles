import Quickshell
import QtQuick
import Quickshell.Hyprland
import qs.services.compositor
Row {
                        id: leftSection
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.spacing

                        Repeater {
                            model: {
                                // Preferir workspaces del monitor de esta barra
                                const mon = Hyprland.monitorFor(panel.modelData);
                                const all = HyprlandService.normalWorkspaces;
                                if (!mon)
                                    return all;
                                const filtered = all.filter(w => {
                                    if (!w.monitor)
                                        return true;
                                    return w.monitor.name === mon.name || w.monitor === mon;
                                });
                                return filtered.length > 0 ? filtered : all;
                            }

                            Rectangle {
                                id: wsPill
                                required property var modelData

                                property bool isFocused: {
                                    const f = HyprlandService.focused;
                                    if (!f)
                                        return false;
                                    return f.id === modelData.id;
                                }
                                property bool isUrgent: modelData.urgent === true

                                width: isFocused ? 30 : 24
                                height: root.pillHeight
                                radius: root.pillRadius
                                color: {
                                    if (isFocused)
                                        return root.bgAccent;
                                    if (isUrgent)
                                        return "#55ff6666";
                                    return root.bgPill;
                                }
                                border.color: isFocused ? "#88ffffff" : "transparent"
                                border.width: isFocused ? 1 : 0

                                Behavior on width {
                                    NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                                }
                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.id
                                    color: root.textPrimary
                                    font.pixelSize: 12
                                    font.family: root.fontFamily
                                    font.bold: wsPill.isFocused
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: HyprlandService.activateWorkspace(modelData)
                                    onWheel: (wheel) => {
                                        if (wheel.angleDelta.y > 0)
                                            HyprlandService.previous();
                                        else
                                            HyprlandService.next();
                                    }
                                }
                            }
                        }

                        // Título de ventana activa (compacto)
                        Rectangle {
                            height: root.pillHeight
                            width: Math.min(titleText.implicitWidth + 16, 220)
                            radius: root.pillRadius
                            color: root.bgPill
                            visible: HyprlandService.activeTitle !== ""
                            clip: true

                            Text {
                                id: titleText
                                anchors.centerIn: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                width: parent.width - 16
                                text: HyprlandService.activeTitle
                                color: root.textSecondary
                                font.pixelSize: 11
                                font.family: root.fontFamily
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
