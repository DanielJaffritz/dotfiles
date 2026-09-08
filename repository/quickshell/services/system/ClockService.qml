pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string timeString: "00:00"
    property string timeWithSeconds: "00:00:00"
    property string dateString: ""
    property string dayName: ""
    property string fullDateTime: ""

    // Formato personalizable
    property string timeFormat: "HH:mm"
    property string dateFormat: "ddd d MMM"

    function refresh() {
        const now = new Date();
        timeString = Qt.formatTime(now, timeFormat);
        timeWithSeconds = Qt.formatTime(now, "HH:mm:ss");
        dateString = Qt.formatDate(now, dateFormat);
        dayName = Qt.formatDate(now, "dddd");
        fullDateTime = timeString + "  " + dateString;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
