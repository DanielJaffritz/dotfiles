pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

Singleton {
    id: root
    property string wallpaperDir: "/home/sheril/Pictures/wallpapers"
    property var imageExtensions: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp", "*.gif"]

    // Tamaño de las miniaturas
    property int thumbWidth: 220
    property int thumbHeight: 130
    property int stripHeight: 180
    property int spacing: 12

    // Transición de awww
    property string transitionType: "grow"
    property string transitionPos: "center"
    property real transitionDuration: 1.0

    property int focusedIndex: 0

    // ─── Modelo de imágenes ──────────────────────────────────────────────────
    property var folderModel: FolderListModel {
        folder: "file://" + root.wallpaperDir
        nameFilters: root.imageExtensions
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        sortReversed: false
    }

    // ─── Proceso para setear el wallpaper ────────────────────────────────────
    Process {
        id: setWallpaperProc
        command: []
        running: false
    }
    Process {
      id: setWallustProc
      command: []
      running: false
    }

    function setWallpaper(path) {
        if (!path || path === "")
            return;

        // Quita el prefijo file:// si existe
        let cleanPath = path.toString().replace(/^file:\/\//, "");

        setWallpaperProc.command = [
            "awww", "img", cleanPath,
            "--transition-type", root.transitionType,
            "--transition-pos", root.transitionPos,
            "--transition-duration", root.transitionDuration.toString()
        ];
        setWallpaperProc.running = true;
    }

    function applyFocused() {
        if (folderModel.count === 0)
            return;
        let path = folderModel.get(root.focusedIndex, "filePath");
        setWallpaper(path);
    }

    function moveFocus(delta) {
        if (folderModel.count === 0)
            return;
        let next = root.focusedIndex + delta;
        if (next < 0)
            next = 0;
        if (next >= folderModel.count)
            next = folderModel.count - 1;
        root.focusedIndex = next;
        listView.positionViewAtIndex(root.focusedIndex, ListView.Center);
    }
}
