import Quickshell
import QtQuick
Rectangle {
        id: pill

        property string iconText: ""
        property string labelText: ""
        property string secondaryLabel: ""
        property int maxLabelWidth: 80
        property bool accented: false

        signal clicked()
        signal wheelUp()
        signal wheelDown()

        height: root.pillHeight
        width: pillRow.implicitWidth + 14
        radius: root.pillRadius
        color: pillMouse.containsMouse ? root.bgPillHover : root.bgPill
        border.color: pill.accented ? "#44aaccff" : "transparent"
        border.width: pill.accented ? 1 : 0

        Behavior on color {
            ColorAnimation { duration: 80 }
        }

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.iconText
                color: pill.accented ? root.accent : root.textSecondary
                font.pixelSize: 13
                font.family: root.fontFamily
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.labelText
                color: root.textPrimary
                font.pixelSize: 12
                font.family: root.fontFamily
                elide: Text.ElideRight
                width: Math.min(implicitWidth, pill.maxLabelWidth)
                visible: text !== ""
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.secondaryLabel
                color: root.textMuted
                font.pixelSize: 11
                font.family: root.fontFamily
                visible: text !== ""
            }
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
            onWheel: (wheel) => {
                if (wheel.angleDelta.y > 0)
                    pill.wheelUp();
                else
                    pill.wheelDown();
            }
        }
    }

