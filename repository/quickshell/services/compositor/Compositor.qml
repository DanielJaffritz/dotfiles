pragma Singleton
import QtQuick
import Quickshell

Singleton {
  id: root

  readonly property bool isHyprland: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""
  readonly property bool isNiri: Quickshell.env("NIRI_SOCKET") !== ""
  readonly property bool isMango: Quickshell.env("MANGO_INSTANCE_SIGNATURE") !== ""
  readonly property string current: {
    if(isHyprland) return "hyprland"
    if(isNiri) return "niri"
    if(isMango) return "mangoWM"
    return "unknown"
  }
}
