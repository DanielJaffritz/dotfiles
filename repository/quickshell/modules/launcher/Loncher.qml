import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.theme

Scope {
    id: root

    signal closeRequested()

    property bool panelOpen: GlobalState.isLauncherOpen
    property int focusedIndex: 0
    property string searchQuery: ""

    property int rowHeight: 52
    property int panelMaxHeight: 420
    property int panelWidth: 420

    // Lista filtrada y ordenada alfabéticamente
    readonly property var appList: {
        let apps = DesktopEntries.applications.values.slice();
        apps.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: "base" }));
        if (searchQuery.trim() !== "") {
            const q = searchQuery.trim().toLowerCase();
            apps = apps.filter(a =>
                (a.name || "").toLowerCase().includes(q) ||
                (a.comment || "").toLowerCase().includes(q) ||
                (a.id || "").toLowerCase().includes(q)
            );
        }
        return apps;
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            focusedIndex = 0;
            searchQuery = "";
            Qt.callLater(() => {
                if (searchField)
                    searchField.forceActiveFocus();
            });
        }
    }

    onAppListChanged: {
        if (focusedIndex >= appList.length)
            focusedIndex = Math.max(0, appList.length - 1);
    }

    function moveFocus(delta) {
        if (appList.length === 0)
            return;
        let next = focusedIndex + delta;
        if (next < 0)
            next = 0;
        if (next >= appList.length)
            next = appList.length - 1;
        focusedIndex = next;
        listView.positionViewAtIndex(focusedIndex, ListView.Contain);
    }

    function launchFocused() {
        if (appList.length === 0 || focusedIndex < 0 || focusedIndex >= appList.length)
            return;
        const entry = appList[focusedIndex];
        if (entry)
            entry.execute();
        GlobalState.isLauncherOpen = false;
    }

    function close() {
        GlobalState.isLauncherOpen = false;
    }

    PanelWindow {
        id: panel
        visible: root.panelOpen

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

        implicitHeight: Math.min(root.panelMaxHeight, contentCol.implicitHeight + 24)
        implicitWidth: root.panelWidth
        // Centrar horizontalmente: anchors left+right con márgenes grandes
        // pero limitamos el ancho visual con el Rectangle interno

        color: "transparent"
        exclusiveZone: 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        focusable: true

        // Contenedor centrado
        Item {
            anchors.fill: parent

            Rectangle {
                id: background
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: Math.min(root.panelWidth, parent.width)
                height: Math.min(root.panelMaxHeight, contentCol.implicitHeight + 24)
                radius: 16
                color: Colors.background
                border.color: Colors.bright_background
                border.width: 1

                ColumnLayout {
                    id: contentCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Apps  ·  ↑ ↓ navigation  ·  Enter open  ·  Esc close"
                        color: Colors.foreground
                        opacity: 0.80
                        font.pixelSize: 12
                        font.family: "sans-serif"
                    }

                    // Campo de búsqueda
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 8
                        color: Colors.bright_background
                        border.color: searchField.activeFocus ? "#88ffffff" : "#22ffffff"
                        border.width: 1

                        TextInput {
                            id: searchField
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#ffffff"
                            font.pixelSize: 14
                            clip: true
                            selectByMouse: true

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "search app..."
                                color: Colors.tertiary
                                font.pixelSize: 14
                                visible: !searchField.text && !searchField.activeFocus
                            }

                            onTextChanged: {
                                root.searchQuery = text;
                                root.focusedIndex = 0;
                            }

                            Keys.onPressed: event => {
                                switch (event.key) {
                                case Qt.Key_Down:
                                case Qt.Key_J:
                                    root.moveFocus(1);
                                    event.accepted = true;
                                    break;
                                case Qt.Key_Up:
                                case Qt.Key_K:
                                    root.moveFocus(-1);
                                    event.accepted = true;
                                    break;
                                case Qt.Key_Return:
                                case Qt.Key_Enter:
                                    root.launchFocused();
                                    event.accepted = true;
                                    break;
                                case Qt.Key_Escape:
                                    if (searchField.text.length > 0) {
                                        searchField.text = "";
                                        root.searchQuery = "";
                                    } else {
                                      GlobalState.isLauncherOpen = false;
                                    }
                                    event.accepted = true;
                                    break;
                                case Qt.Key_Tab:
                                    root.moveFocus(1);
                                    event.accepted = true;
                                    break;
                                case Qt.Key_Backtab:
                                    root.moveFocus(-1);
                                    event.accepted = true;
                                    break;
                                }
                            }
                        }
                    }

                    // Lista vertical de aplicaciones
                    ListView {
                        id: listView
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(
                            root.appList.length * root.rowHeight,
                            root.panelMaxHeight - 100
                        )
                        clip: true
                        model: root.appList
                        currentIndex: root.focusedIndex
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 4
                        }

                        delegate: Item {
                            id: del
                            required property int index
                            required property var modelData

                            width: listView.width
                            height: root.rowHeight

                            property bool isFocused: index === root.focusedIndex

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 10
                                color: del.isFocused ? Colors.dark_foreground : (mouse.containsMouse ? Colors.bright_background : "transparent")
                                border.color: del.isFocused ? Colors.primary : "transparent"
                                border.width: del.isFocused ? 1 : 0

                                Behavior on color {
                                    ColorAnimation { duration: 80 }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 12

                                    // Icono
                                    Item {
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        Layout.alignment: Qt.AlignVCenter

                                        Image {
                                            anchors.centerIn: parent
                                            width: 32
                                            height: 32
                                            source: {
                                                const path = Quickshell.iconPath(del.modelData.icon, true);
                                                return path && path !== "" ? path : "";
                                            }
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            smooth: true
                                            visible: status === Image.Ready
                                        }

                                        // Fallback si no hay icono
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 32
                                            height: 32
                                            radius: 8
                                            color: "#33ffffff"
                                            visible: parent.children[0].status !== Image.Ready

                                            Text {
                                                anchors.centerIn: parent
                                                text: (del.modelData.name || "?")[0].toUpperCase()
                                                color: "#ffffff"
                                                font.pixelSize: 14
                                                font.bold: true
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: del.modelData.name || "No name"
                                            color: del.isFocused ? Colors.hover_foreground : Colors.foreground 
                                            font.pixelSize: 14
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: del.modelData.comment || ""
                                            color: Colors.foreground
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                            visible: text !== ""
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    root.focusedIndex = index;
                                    root.launchFocused();
                                }
                                onEntered: root.focusedIndex = index
                            }
                        }

                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    }

                    // Contador
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.appList.length + " aplicacation" + (root.appList.length === 1 ? "" : "s")
                        color: "#66ffffff"
                        font.pixelSize: 11
                        visible: root.appList.length > 0
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No apps found"
                        color: Colors.red
                        font.pixelSize: 13
                        visible: root.appList.length === 0
                    }
                }
            }
        }

        // Captura global de teclas (por si el foco no está en el search)
        Item {
            anchors.fill: parent
            focus: root.panelOpen && !searchField.activeFocus

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Down:
                case Qt.Key_J:
                    root.moveFocus(1);
                    event.accepted = true;
                    break;
                case Qt.Key_Up:
                case Qt.Key_K:
                    root.moveFocus(-1);
                    event.accepted = true;
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.launchFocused();
                    event.accepted = true;
                    break;
                case Qt.Key_Escape:
                case Qt.Key_Q:
                    GlobalState.isLauncherOpen = false;
                    event.accepted = true;
                    break;
                case Qt.Key_Home:
                    root.focusedIndex = 0;
                    listView.positionViewAtIndex(0, ListView.Beginning);
                    event.accepted = true;
                    break;
                case Qt.Key_End:
                    root.focusedIndex = Math.max(0, root.appList.length - 1);
                    listView.positionViewAtIndex(root.focusedIndex, ListView.End);
                    event.accepted = true;
                    break;
                default:
                    // Cualquier carácter imprimible → enfocar búsqueda
                    if (event.text && event.text.length === 1 && event.text >= " ") {
                        searchField.forceActiveFocus();
                        searchField.text += event.text;
                        event.accepted = true;
                    }
                    break;
                }
            }
        }
    }
}
