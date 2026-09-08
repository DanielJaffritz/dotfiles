pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var player: {
        const players = Mpris.players ? Mpris.players.values : [];
        if (!players || players.length === 0)
            return null;
        for (let i = 0; i < players.length; i++) {
            const p = players[i];
            if (p.isPlaying === true)
                return p;
            // fallback por playbackState si existe
            try {
                if (p.playbackState === MprisPlaybackState.Playing)
                    return p;
            } catch (e) {}
        }
        return players[0];
    }

    readonly property bool available: player !== null

    readonly property bool playing: {
        if (!player)
            return false;
        if (player.isPlaying === true)
            return true;
        try {
            return player.playbackState === MprisPlaybackState.Playing;
        } catch (e) {
            return false;
        }
    }

    readonly property string title: player ? (player.trackTitle || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string album: player ? (player.trackAlbum || "") : ""
    readonly property string artUrl: player ? (player.trackArtUrl || "") : ""

    readonly property string display: {
        if (!player)
            return "";
        if (artist && title)
            return artist + " — " + title;
        return title || artist || "Sin título";
    }

    readonly property string icon: playing ? "󰏤" : "󰐊"

    readonly property real position: player ? (player.position || 0) : 0
    readonly property real length: {
        if (!player)
            return 0;
        if (player.lengthSupported === false)
            return 0;
        return player.length || 0;
    }

    function play() {
        if (player && player.canPlay)
            player.play();
    }

    function pause() {
        if (player && player.canPause)
            player.pause();
    }

    function toggle() {
        if (!player)
            return;
        if (typeof player.togglePlaying === "function")
            player.togglePlaying();
        else if (playing)
            pause();
        else
            play();
    }

    function next() {
        if (player && player.canGoNext)
            player.next();
    }

    function previous() {
        if (player && player.canGoPrevious)
            player.previous();
    }
}
