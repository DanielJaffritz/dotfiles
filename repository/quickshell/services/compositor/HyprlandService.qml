pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    // Modelo nativo de Quickshell (ObjectModel)
    readonly property var list: Hyprland.workspaces

    readonly property var focused: Hyprland.focusedWorkspace

    readonly property int focusedId: focused ? focused.id : 1

    readonly property string focusedName: focused ? (focused.name || String(focused.id)) : "1"

    readonly property var focusedMonitor: Hyprland.focusedMonitor

    readonly property var activeToplevel: Hyprland.activeToplevel

    readonly property string activeTitle: {
        if (!activeToplevel)
            return "";
        return activeToplevel.title || "";
    }

    readonly property string activeClass: {
        if (!activeToplevel)
            return "";
        return activeToplevel.class || activeToplevel.initialClass || "";
    }

    // Workspaces normales (id > 0), ordenados
    readonly property var normalWorkspaces: {
        const all = list.values || [];
        return all.filter(w => w.id > 0).sort((a, b) => a.id - b.id);
    }

    function activate(id) {
        Hyprland.dispatch("workspace " + id);
    }

    function activateWorkspace(ws) {
        if (ws && typeof ws.activate === "function")
            ws.activate();
        else if (ws && ws.id !== undefined)
            activate(ws.id);
    }

    function next() {
        Hyprland.dispatch("workspace e+1");
    }

    function previous() {
        Hyprland.dispatch("workspace e-1");
    }

    function dispatch(cmd) {
        Hyprland.dispatch(cmd);
    }
}
