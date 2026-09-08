pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // Lista de notificaciones trackeadas (más reciente primero)
    property var list: []
    property bool doNotDisturb: false
    readonly property int count: list.length

    signal notificationAdded(var notification)
    signal notificationRemoved(var notification)
    signal cleared()

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: function (notification) {
            // Ignorar vacías
            if (!notification.appName && !notification.summary && !notification.body)
                return;

            if (root.doNotDisturb) {
                // Aún trackear en DND si se quiere historial; por ahora descartamos popup
                // pero sí guardamos en el cajón
            }

            notification.tracked = true;

            // Si reemplaza una existente (mismo id), quitar la anterior
            const nid = notification.id;
            root.list = root.list.filter(n => {
                if (n && n.id === nid) {
                    try { n.dismiss(); } catch (e) {}
                    return false;
                }
                return true;
            });

            root.list = [notification, ...root.list];
            root.notificationAdded(notification);

            // Límite razonable del cajón
            while (root.list.length > 50) {
                const old = root.list[root.list.length - 1];
                root.list = root.list.slice(0, root.list.length - 1);
                try { old.dismiss(); } catch (e) {}
            }
        }
    }

    // Acceso al ObjectModel nativo (alternativa)
    readonly property var tracked: server.trackedNotifications

    function dismiss(notification) {
        if (!notification)
            return;
        try {
            notification.dismiss();
        } catch (e) {}
        root.list = root.list.filter(n => n !== notification);
        root.notificationRemoved(notification);
    }

    function dismissAll() {
        const copy = root.list.slice();
        root.list = [];
        for (const n of copy) {
            try { n.dismiss(); } catch (e) {}
        }
        root.cleared();
    }

    function toggleDnd() {
        root.doNotDisturb = !root.doNotDisturb;
    }

    // Icono usable para una notificación
    function iconSource(notification) {
        if (!notification)
            return "";
        if (notification.image && notification.image !== "")
            return notification.image;
        if (notification.appIcon && notification.appIcon !== "") {
            const p = Quickshell.iconPath(notification.appIcon, true);
            return p || "";
        }
        return "";
    }
}
