import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.bar
import qs.modules.osd
import qs.modules.controlcenter
import qs.modules.launcher
import qs.modules.selector
import qs.modules.timer
import qs.modules.lock
import Quickshell.Io
import qs.services

ShellRoot {
  id: root
  Bar {}
  NotificationPopup {}
  
  Osd {}
  Loader {
    id: wallpaperLoader
    active: false
    asynchronous: false
    sourceComponent: WallpaperSelector {
      id: wallpaperSelector
    }
  }
  Loader {
    id: timerLoader
    active: false
    asynchronous: false
    sourceComponent: Timer {
      id: timer
    }
  }

  Loader {
    id: launcherLoader
    active: false
    asynchronous: false
    sourceComponent: Loncher {
      id: launcher
    }
  }
  Loader {
    id: controlcenterLoader
    active: false
    asynchronous: false
    sourceComponent: ControlCenter {
      id: controlCenter
    }
  }
  Loader {
    id: waylockLoader
    active: false
    asynchronous: false
    sourceComponent: WayLock {
      id: waylock
    }
  }
  IpcHandler {
    target: "launcher"
    function changeVisible(): void {
      if(!launcherLoader.active){
        launcherLoader.active = true
        GlobalState.isLauncherOpen = true
      }else {
        GlobalState.isLauncherOpen = !GlobalState.isLauncherOpen
      }
    }
  }
  IpcHandler {
    target: "waylock"
    function changeVisible(): void {
      if(!waylockLoader.active){
        waylockLoader.active = true
        GlobalState.isWayLockOpen = true
      } else {
        GlobalState.isWayLockOpen = !GlobalState.isWayLockOpen
      }
    }
  }
  IpcHandler {
    target: "wallpaper"
    function changeVisible(): void {
      if(!wallpaperLoader.active){
        wallpaperLoader.active = true
        GlobalState.isSelectorOpen = true
      } else {
        GlobalState.isSelectorOpen = !GlobalState.isSelectorOpen
      }
    }
  }
  IpcHandler {
    target: "controlCenter"
    function changeVisible(): void {
      if(!controlcenterLoader.active){
        controlcenterLoader.active = true
        GlobalState.isControlCenterOpen = true
      } else {
        GlobalState.isControlCenterOpen = !GlobalState.isControlCenterOpen
      }
    }
  }
  IpcHandler {
    target: "timer"
    function changeVisible():void {
      if(!timerLoader.active){
        timerLoader.active = true
        GlobalState.isTimerOpen = true
      } else {
        GlobalState.isTimerOpen = !GlobalState.isTimerOpen
      }
    }
    function changeSize():void {
      GlobalState.isTimerMinimal = !GlobalState.isTimerMinimal
    }
  }
}
