import Quickshell
import QtQuick
import qs.services.network
import qs.components
BarPill {
                            iconText: BluetoothService.icon
                            labelText: {
                                if (!BluetoothService.powered)
                                    return "Off";
                                if (BluetoothService.connectedCount > 0)
                                    return BluetoothService.connectedName || (BluetoothService.connectedCount + "");
                                return "On";
                            }
                            maxLabelWidth: 90
                            onClicked: BluetoothService.toggle()
                        }
