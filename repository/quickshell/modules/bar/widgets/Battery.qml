import Quickshell
import QtQuick
import qs.services.system
import qs.components
BarPill {
                            visible: BatteryService.isPresent
                            iconText: BatteryService.icon
                            labelText: BatteryService.percent + "%"
                            accented: BatteryService.charging
                            onClicked: {}
                        }
