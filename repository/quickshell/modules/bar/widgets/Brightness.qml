import Quickshell
import QtQuick
import qs.services.system
import qs.components

BarPill {
                            visible: BrightnessService.available
                            iconText: BrightnessService.icon
                            labelText: BrightnessService.percent + "%"
                            onClicked: {}
                            onWheelUp: BrightnessService.increase()
                            onWheelDown: BrightnessService.decrease()
                        }
