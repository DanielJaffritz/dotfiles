import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services.network

Scope {
    id: root

    // Entradas de popup activas: [{ id, notification, expiresAt }]
    property var popups: []
    readonly property int maxPopups: 4
    readonly property int defaultTimeoutMs: 5000
    readonly property int criticalTimeoutMs: 8000
    readonly property int lowTimeoutMs: 3500

    // Colores (mismo lenguaje)
    readonly property color bgCard: "#ee1a1a1a"
    readonly property color borderColor: "#55ffffff"
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#aaffffff"
    readonly property color textMuted: "#66ffffff"
    readonly property color accent: "#c0e0ff"
    readonly property color urgencyCritical: "#ff6666"
    readonly property color urgencyLow: "#88ffffff"

    function timeoutFor(notification) {
        if (!notification)
            return root.defaultTimeoutMs;
        // expireTimeout en segundos (spec); 0 = servidor decide
        const t = notification.expireTimeout;
        if (typeof t === "number" && t > 0)
            return Math.min(30000, Math.max(2000, t * 1000));
        // Urgency: 0 Low, 1 Normal, 2 Critical (NotificationUrgency)
        const u = notification.urgency;
        if (u === 2 || u === "Critical")
            return root.criticalTimeoutMs;
        if (u === 0 || u === "Low")
            return root.lowTimeoutMs;
        return root.defaultTimeoutMs;
    }

    function urgencyColor(notification) {
        const u = notification ? notification.urgency : 1;
        if (u === 2 || u === "Critical")
            return root.urgencyCritical;
        if (u === 0 || u === "Low")
            return root.urgencyLow;
        return root.accent;
    }

    function addPopup(notification) {
        if (!notification)
            return;
        if (NotificationsService.doNotDisturb)
            return;

        // Transient: solo popup breve, el servicio ya lo trackea si quiere
        // Reemplazar popup del mismo id
        const nid = notification.id;
        let list = root.popups.filter(p => p && p.notification && p.notification.id !== nid);

        const entry = {
            id: nid,
            notification: notification,
            expiresAt: Date.now() + timeoutFor(notification)
        };
        list = [entry, ...list];

        // Límite de popups visibles
        while (list.length > root.maxPopups) {
            list = list.slice(0, list.length - 1);
        }
        root.popups = list;
        tickTimer.restart();
    }

    function removePopup(notification) {
        if (!notification)
            return;
        root.popups = root.popups.filter(p =>
            !(p && p.notification && (p.notification === notification || p.notification.id === notification.id))
        );
    }

    function dismissPopup(notification) {
        removePopup(notification);
        // No cerrar del cajón automáticamente: solo el popup
        // Si se quiere cerrar del todo: Notifications.dismiss(notification)
    }

    function dismissAndClose(notification) {
        removePopup(notification);
        Notifications.dismiss(notification);
    }

    // Escuchar nuevas notificaciones
    Connections {
        target: NotificationsService

        function onNotificationAdded(notification) {
            root.addPopup(notification);
        }

        function onNotificationRemoved(notification) {
            root.removePopup(notification);
        }

        function onCleared() {
            root.popups = [];
        }

        function onDoNotDisturbChanged() {
            if (NotificationsService.doNotDisturb)
                root.popups = [];
        }
    }

    // Expiración por tiempo
    Timer {
        id: tickTimer
        interval: 500
        repeat: true
        running: root.popups.length > 0
        onTriggered: {
            const now = Date.now();
            const kept = [];
            for (const p of root.popups) {
                if (!p || !p.notification)
                    continue;
                if (now >= p.expiresAt) {
                    // Solo ocultar popup; la notificación puede seguir en el cajón
                    continue;
                }
                kept.push(p);
            }
            if (kept.length !== root.popups.length)
                root.popups = kept;
            if (kept.length === 0)
                tickTimer.stop();
        }
    }

    // Ventana de popups — esquina superior derecha
    PanelWindow {
        id: popupWindow
        visible: root.popups.length > 0
        color: "transparent"
        exclusiveZone: 0
        focusable: false

        anchors {
            top: true
            right: true
        }

        margins {
            top: 12
            right: 12
        }

        // Altura dinámica según contenido
        implicitWidth: 360
        implicitHeight: popupColumn.implicitHeight + 8

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-notification-popups"
        // No robar foco del teclado
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {
            item: popupColumn
        }

        ColumnLayout {
            id: popupColumn
            anchors.top: parent.top
            anchors.right: parent.right
            width: 360
            spacing: 8

            Repeater {
                model: root.popups

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    required property int index

                    readonly property var notif: modelData.notification

                    Layout.fillWidth: true
                    Layout.preferredHeight: cardCol.implicitHeight + 20
                    radius: 14
                    color: root.bgCard
                    border.width: 1
                    border.color: root.borderColor
                    clip: true

                    // Barra de urgencia a la izquierda
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        radius: 2
                        color: root.urgencyColor(card.notif)
                    }

                    // Entrada animada
                    opacity: 0
                    transform: Translate { id: slideX; x: 40 }

                    Component.onCompleted: {
                        appearAnim.start();
                    }

                    ParallelAnimation {
                        id: appearAnim
                        NumberAnimation {
                            target: card
                            property: "opacity"
                            to: 1
                            duration: 180
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: slideX
                            property: "x"
                            to: 0
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    ColumnLayout {
                        id: cardCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        anchors.leftMargin: 14
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // Icono
                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignTop
                                radius: 10
                                color: "#33ffffff"
                                clip: true

                                Image {
                                    id: notifImg
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: NotificationsService.iconSource(card.notif)
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰂚"
                                    color: root.textSecondary
                                    font.pixelSize: 18
                                    visible: notifImg.status !== Image.Ready
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: (card.notif && card.notif.appName) ? card.notif.appName : "Notificación"
                                    color: root.textMuted
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: (card.notif && card.notif.summary) ? card.notif.summary : ""
                                    color: root.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: (card.notif && card.notif.body) ? card.notif.body : ""
                                    color: root.textSecondary
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 4
                                    visible: text !== ""
                                }
                            }

                            // Cerrar
                            Text {
                                Layout.alignment: Qt.AlignTop
                                text: "󰅖"
                                color: closeMa.containsMouse ? "#ff8888" : root.textMuted
                                font.pixelSize: 14

                                MouseArea {
                                    id: closeMa
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.dismissAndClose(card.notif)
                                }
                            }
                        }

                        // Acciones
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: card.notif && card.notif.actions && card.notif.actions.length > 0

                            Repeater {
                                model: card.notif && card.notif.actions ? card.notif.actions : []

                                Rectangle {
                                    required property var modelData
                                    Layout.preferredHeight: 28
                                    Layout.preferredWidth: actionLabel.implicitWidth + 16
                                    radius: 8
                                    color: actionMa.containsMouse ? "#44ffffff" : "#22ffffff"
                                    border.color: "#33ffffff"
                                    border.width: 1

                                    Text {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: modelData.text || modelData.identifier || "Acción"
                                        color: root.textPrimary
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        id: actionMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            try {
                                                modelData.invoke();
                                            } catch (e) {}
                                            // Las no-resident se cierran al invocar
                                            if (card.notif && !card.notif.resident)
                                                root.dismissAndClose(card.notif);
                                            else
                                                root.dismissPopup(card.notif);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Click en el cuerpo: solo ocultar popup (sigue en el cajón)
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissPopup(card.notif)
                    }
                }
            }
        }
    }
}
