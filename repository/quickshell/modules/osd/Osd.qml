import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services.audio
import qs.services.system

Scope {
    id: root

    // "volume" | "brightness" | ""
    property string mode: ""
    property bool osdVisible: false
    property int hideMs: 1500
    property bool ready: false  // evita flash al arrancar

    // Valores mostrados (snapshot al mostrar)
    property real shownValue: 0      // 0–1
    property bool shownMuted: false

    readonly property string icon: {
        if (mode === "brightness") {
            if (shownValue < 0.33) return "󰃞";
            if (shownValue < 0.66) return "󰃟";
            return "󰃠";
        }
        // volume
        if (shownMuted || shownValue <= 0)
            return "󰖁";
        if (shownValue < 0.33)
            return "󰕿";
        if (shownValue < 0.66)
            return "󰖀";
        return "󰕾";
    }

    readonly property int percent: {
        if (mode === "volume")
            return AudioService.volumePercent;
        return Math.round(shownValue * 100);
    }

    function showVolume() {
        mode = "volume";
        // Barra visual limitada a 100%; el % puede mostrar >100 si el sink lo permite
        shownValue = Math.min(1, Math.max(0, AudioService.volume));
        shownMuted = AudioService.muted;
        osdVisible = true;
        hideTimer.restart();
    }

    function showBrightness() {
        if (!BrightnessService.available)
            return;
        mode = "brightness";
        shownValue = Math.min(1, Math.max(0, BrightnessService.value));
        shownMuted = false;
        osdVisible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: root.hideMs
        onTriggered: root.osdVisible = false
    }

    // Activar watchers tras un pequeño delay (evitar OSD al cargar)
    Timer {
        interval: 800
        running: true
        onTriggered: root.ready = true
    }

    // ─── Escuchar cambios de audio ───────────────────────────────────────────
    Connections {
        target: AudioService
        enabled: root.ready

        function onVolumeChanged() {
            root.showVolume();
        }
        function onMutedChanged() {
            root.showVolume();
        }
    }

    // Pipewire puede no notificar volume como signal de nuestra property binding;
    // también vigilamos el nodo directamente si está disponible.
    Connections {
        target: AudioService.sink && AudioService.sink.audio ? AudioService.sink.audio : null
        enabled: root.ready && AudioService.sink && AudioService.sink.audio

        function onVolumeChanged() {
            root.showVolume();
        }
        function onMutedChanged() {
            root.showVolume();
        }
    }

    // ─── Escuchar cambios de brillo ──────────────────────────────────────────
    Connections {
        target: BrightnessService
        enabled: root.ready

        function onValueChanged() {
            root.showBrightness();
        }
    }

    // ─── Ventana OSD ─────────────────────────────────────────────────────────
    // Sin screen fijo: el compositor suele ponerla en el monitor activo
    PanelWindow {
        id: osdWindow

        // Mantener mapeada un poco durante el fade-out
        property bool surfaceMapped: root.osdVisible || fadeOut.running

        visible: surfaceMapped
        color: "transparent"
        exclusiveZone: 0
        focusable: false

        // No interceptar clicks
        mask: Region {}

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            bottom: true
            left: true
            right: true
        }

        margins {
            bottom: 96
        }

        implicitHeight: 56
        // Ancho lo define el contenido centrado

        Timer {
            id: fadeOut
            interval: 220
            running: false
        }

        Connections {
            target: root
            function onOsdVisibleChanged() {
                if (!root.osdVisible)
                    fadeOut.restart();
            }
        }

        Item {
            anchors.fill: parent

            Rectangle {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: 280
                height: 48
                radius: 24
                color: "#cc1a1a1a"
                border.color: "#44ffffff"
                border.width: 1

                opacity: root.osdVisible ? 1 : 0
                scale: root.osdVisible ? 1 : 0.92

                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
                }
                Behavior on scale {
                    NumberAnimation { duration: 180; easing.type: Easing.OutBack }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    // Icono
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: root.icon
                        color: {
                            if (root.mode === "volume" && root.shownMuted)
                                return "#ff8888";
                            if (root.mode === "brightness")
                                return "#ffcc66";
                            return "#c0e0ff";
                        }
                        font.pixelSize: 20
                        font.family: "sans-serif"
                    }

                    // Barra de progreso
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        color: "#33ffffff"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.min(1, root.shownValue)
                            radius: parent.radius
                            color: {
                                if (root.mode === "volume" && root.shownMuted)
                                    return "#88ff6666";
                                if (root.mode === "brightness")
                                    return "#ffcc66";
                                return "#88c0e0ff";
                            }

                            Behavior on width {
                                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                            }
                        }
                    }

                    // Porcentaje
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 40
                        text: (root.mode === "volume" && root.shownMuted) ? "Mute" : (root.percent + "%")
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.family: "sans-serif"
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }

}
