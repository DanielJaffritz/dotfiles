pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // Hay que trackear el nodo para que volume/muted estén disponibles
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property real volume: {
        if (!sink || !sink.audio)
            return 0;
        return sink.audio.volume;
    }

    readonly property int volumePercent: Math.round(volume * 100)

    readonly property bool muted: {
        if (!sink || !sink.audio)
            return true;
        return sink.audio.muted;
    }

    readonly property string sinkName: {
        if (!sink)
            return "Sin salida";
        return sink.nickname || sink.description || sink.name || "Audio";
    }

    readonly property real micVolume: {
        if (!source || !source.audio)
            return 0;
        return source.audio.volume;
    }

    readonly property bool micMuted: {
        if (!source || !source.audio)
            return true;
        return source.audio.muted;
    }

    readonly property string icon: {
        if (muted || volume <= 0)
            return "󰖁";
        if (volume < 0.33)
            return "󰕿";
        if (volume < 0.66)
            return "󰖀";
        return "󰕾";
    }

    readonly property string display: {
        if (muted)
            return icon + " Mute";
        return icon + " " + volumePercent + "%";
    }

    function setVolume(v) {
        if (!sink || !sink.audio)
            return;
        sink.audio.volume = Math.max(0, Math.min(1.5, v));
    }

    function changeVolume(delta) {
        setVolume(volume + delta);
    }

    function toggleMute() {
        if (!sink || !sink.audio)
            return;
        sink.audio.muted = !sink.audio.muted;
    }

    function setMuted(m) {
        if (!sink || !sink.audio)
            return;
        sink.audio.muted = m;
    }

    function toggleMicMute() {
        if (!source || !source.audio)
            return;
        source.audio.muted = !source.audio.muted;
    }
}
