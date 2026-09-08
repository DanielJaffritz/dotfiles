import Quickshell
import QtQuick
import qs.services.audio
import qs.components
 BarPill {
                            iconText: AudioService.icon
                            labelText: AudioService.muted ? "Mute" : (AudioService.volumePercent + "%")
                            accented: !AudioService.muted
                            onClicked: AudioService.toggleMute()
                            onWheelUp: AudioService.changeVolume(0.05)
                            onWheelDown: AudioService.changeVolume(-0.05)
                        }
