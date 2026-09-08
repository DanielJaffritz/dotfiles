import Quickshell
import QtQuick
import qs.services.system
import qs.components
 BarPill {
                            iconText: "󰥔"
                            labelText: ClockService.timeString
                            secondaryLabel: ClockService.dateString
                            onClicked: {}
                        }
