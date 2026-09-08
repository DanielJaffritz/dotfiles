import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.services.system
import qs.theme

    // ─── Ventana overlay ─────────────────────────────────────────────────────
    PanelWindow {
        id: panel
        visible: GlobalState.isSelectorOpen

        anchors {
            left: true
            right: true
            bottom: true
        }

        margins {
            bottom: 24
            left: 40
            right: 40
        }

        implicitHeight: WallpaperService.stripHeight + 24
        color: "transparent"
        exclusiveZone: 0

        // Capa overlay + foco de teclado
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        focusable: true

        // Fondo semi-transparente con bordes redondeados
        Rectangle {
            id: background
            anchors.fill: parent
            radius: 16
            color: Colors.background
            border.color: Colors.bright_background
            border.width: 1

            // Sombra suave
            layer.enabled: true
            layer.effect: null

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                // Título
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Wallpapers  ·  ← →  navigation  ·  Enter apply  ·  Esc close"
                    color: Colors.foreground
                    opacity: 0.80
                    font.pixelSize: 12
                    font.family: "sans-serif"
                }

                // Cinta horizontal
                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    spacing: WallpaperService.spacing
                    clip: true
                    model: WallpaperService.folderModel
                    highlightMoveDuration: 120
                    highlightMoveVelocity: -1
                    currentIndex: WallpaperService.focusedIndex

                    // Scroll suave con rueda
                    ScrollBar.horizontal: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        height: 4
                    }

                    delegate: Item {
                        id: delegateRoot
                        required property int index
                        required property string filePath
                        required property string fileName
                        required property url fileUrl

                        width: WallpaperService.thumbWidth
                        height: WallpaperService.thumbHeight + 30

                        property bool isFocused: index === WallpaperService.focusedIndex

                        scale: isFocused ? 1.08 : 0.92
                        opacity: isFocused ? 1.0 : 0.65

                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 120 }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            // Miniatura
                            Rectangle {
                                width: WallpaperService.thumbWidth
                                height: WallpaperService.thumbHeight
                                radius: 10
                                color: "#222"
                                border.color: delegateRoot.isFocused ? Colors.primary : Colors.secondary
                                border.width: delegateRoot.isFocused ? 2 : 1
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: delegateRoot.fileUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    sourceSize.width: WallpaperService.thumbWidth * 2
                                    sourceSize.height: WallpaperService.thumbHeight * 2
                                }

                                // Overlay sutil cuando está enfocado
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    color: "transparent"
                                    border.color: delegateRoot.isFocused ? Colors.primary : "transparent"
                                    border.width: 2
                                }
                            }

                            // Nombre del archivo (truncado)
                            Text {
                                width: WallpaperService.thumbWidth
                                text: delegateRoot.fileName
                                color: delegateRoot.isFocused ? Colors.hover_foreground : Colors.foreground
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Click del ratón
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                WallpaperService.focusedIndex = index;
                                WallpaperService.applyFocused();
                            }

                            onEntered: {
                                WallpaperService.focusedIndex = index;
                            }
                        }
                    }

                    // Asegurar que el índice enfocado se vea
                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, ListView.Center);
                    }
                }
            }
        }

        // Captura de teclado
        Item {
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Left:
                case Qt.Key_H:
                    WallpaperService.moveFocus(-1);
                    event.accepted = true;
                    break;
                case Qt.Key_Right:
                case Qt.Key_L:
                    WallpaperService.moveFocus(1);
                    event.accepted = true;
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                case Qt.Key_Space:
                    WallpaperService.applyFocused();
                    event.accepted = true;
                    break;
                case Qt.Key_Escape:
                case Qt.Key_Q:
                    GlobalState.isSelectorOpen = false;
                    event.accepted = true;
                    break;
                case Qt.Key_Home:
                    WallpaperService.focusedIndex = 0;
                    listView.positionViewAtIndex(0, ListView.Center);
                    event.accepted = true;
                    break;
                case Qt.Key_End:
                    WallpaperService.focusedIndex = Math.max(0, folderModel.count - 1);
                    listView.positionViewAtIndex(root.focusedIndex, ListView.Center);
                    event.accepted = true;
                    break;
                }
            }
        }
    }
