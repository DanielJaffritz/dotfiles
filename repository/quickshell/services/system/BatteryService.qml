pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var device: UPower.displayDevice

    // 0.0 – 1.0
    readonly property real percentage: {
        const d = device;
        if (!d || !d.ready)
            return 0;
        // UPower en QS expone percentage en 0–1
        const p = d.percentage;
        if (p === undefined || p === null)
            return 0;
        return Math.max(0, Math.min(1, p > 1 ? p / 100 : p));
    }

    readonly property int percent: Math.round(percentage * 100)

    readonly property bool isPresent: {
        const d = device;
        if (!d || !d.ready)
            return false;
        // Si hay percentage válido o isLaptopBattery
        if (d.isLaptopBattery === true)
            return true;
        // Fallback: si el dispositivo reporta energía
        return d.percentage !== undefined && d.percentage !== null;
    }

    readonly property bool onBattery: UPower.onBattery

    readonly property bool charging: {
        const d = device;
        if (!d || !d.ready)
            return false;
        // state numérico típico de UPower:
        // 1 Charging, 2 Discharging, 3 Empty, 4 FullyCharged,
        // 5 PendingCharge, 6 PendingDischarge
        const s = d.state;
        if (s === undefined || s === null)
            return !UPower.onBattery && percent > 0;
        if (typeof s === "number")
            return s === 1 || s === 4 || s === 5;
        // Si es enum de QS
        try {
            return s === UPowerDeviceState.Charging
                || s === UPowerDeviceState.FullyCharged
                || s === UPowerDeviceState.PendingCharge;
        } catch (e) {
            return false;
        }
    }

    readonly property bool fullyCharged: {
        const d = device;
        if (!d || !d.ready)
            return false;
        const s = d.state;
        if (typeof s === "number")
            return s === 4;
        try {
            return s === UPowerDeviceState.FullyCharged;
        } catch (e) {
            return percent >= 100 && !onBattery;
        }
    }

    readonly property string stateText: {
        if (!isPresent)
            return "N/A";
        if (fullyCharged)
            return "Completa";
        if (charging)
            return "Cargando";
        if (onBattery)
            return "Descargando";
        return "Conectada";
    }

    readonly property string icon: {
        if (!isPresent)
            return "󰚥";
        if (charging && fullyCharged)
            return "󰂅";
        if (charging)
            return "󰂄";
        if (percent >= 90) return "󰁹";
        if (percent >= 80) return "󰂂";
        if (percent >= 70) return "󰂁";
        if (percent >= 60) return "󰂀";
        if (percent >= 50) return "󰁿";
        if (percent >= 40) return "󰁾";
        if (percent >= 30) return "󰁽";
        if (percent >= 20) return "󰁼";
        if (percent >= 10) return "󰁻";
        return "󰁺";
    }

    readonly property string display: {
        if (!isPresent)
            return "";
        return icon + " " + percent + "%";
    }

    readonly property real timeToEmpty: {
        const d = device;
        if (!d || !d.ready)
            return 0;
        return d.timeToEmpty || 0;
    }

    readonly property real timeToFull: {
        const d = device;
        if (!d || !d.ready)
            return 0;
        return d.timeToFull || 0;
    }
}
