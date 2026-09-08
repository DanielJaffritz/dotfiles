import Quickshell
import QtQuick
import qs.services.network
import qs.components
BarPill {
                            iconText: NetworkService.icon
                            labelText: {
                                if (NetworkService.connectionType === "ethernet")
                                    return "ETH";
                                if (!NetworkService.wifiEnabled)
                                    return "Off";
                                if (!NetworkService.connected)
                                    return "—";
                                return NetworkService.ssid || "Wi‑Fi";
                            }
                            maxLabelWidth: 100
                            onClicked: NetworkService.toggleWifi()
                        }
