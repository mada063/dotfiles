import QtQuick

// ASCII weather scenes for DashboardWeather (wttr %C summary → art).
QtObject {
    id: root

    /** Intentionally empty art for “clear” (user spec). */
    readonly property string _clear: ""

    readonly property string _sunny: "\\   /\n.-.\n― (   ) ―\n`-’\n/   \\"

    readonly property string _partlyCloudy: "\\  /\n_/\"\".-.\n  \\_(   )\n  /(___)"

    readonly property string _cloudy: "  .-.\n .(   )\n(___.__)"

    readonly property string _overcast: "  .-.\n .(   )\n(___.__)\n(______)"

    readonly property string _lightRain: "  .-.\n .(   )\n(___.__)\n ' ' ' '"

    readonly property string _rain: "  .-.\n .(   )\n(___.__)\n‚ ‚ ‚ ‚ ‚"

    readonly property string _heavyRain: "  .-.\n .(   )\n(___.__)\n' ' ' '\n' ' ' '"

    readonly property string _thunder: "  .-.\n .(   )\n(___.__)\n  / /\n/ /"

    readonly property string _snow: "  .-.\n .(   )\n(___.__)\n*  *  *"

    readonly property string _heavySnow: "  .-.\n .(   )\n(___.__)\n* * * *\n* * * *"

    readonly property string _fog: " _ - _ - _\n  _ - _ - \n _ - _ - _"

    readonly property string _windy: " ~ ~ ~ ~ ~\n  ~ ~ ~ ~\n ~ ~ ~ ~ ~"

    /** Fixed gallery order for DashboardWeather click-through preview. */
    readonly property var previewArts: [
        root._clear, root._sunny, root._partlyCloudy, root._cloudy, root._overcast,
        root._lightRain, root._rain, root._heavyRain, root._thunder,
        root._snow, root._heavySnow, root._fog, root._windy
    ]
    readonly property int previewArtCount: previewArts.length

    function previewArtAt(index) {
        const n = previewArts.length;
        if (!n)
            return "";
        let i = Math.floor(Number(index) || 0) % n;
        if (i < 0)
            i += n;
        return previewArts[i];
    }

    function textForSummary(summary) {
        const s = String(summary || "").toLowerCase();
        if (!s.length)
            return root._cloudy;

        if (s.includes("blizzard") || s.includes("heavy snow") || s.includes("heavy blizzard"))
            return root._heavySnow;
        if (s.includes("snow") || s.includes("flurr") || s.includes("ice pellet") || s.includes("graupel") || s.includes("wintry"))
            return root._snow;

        if (s.includes("thunder") || (s.includes("storm") && !s.includes("snow")))
            return root._thunder;

        if (s.includes("torrential") || s.includes("downpour") || s.includes("pelting rain") || s.includes("heavy rain"))
            return root._heavyRain;
        if (s.includes("drizzle") || s.includes("light rain") || (s.includes("patchy") && s.includes("rain")))
            return root._lightRain;
        if (s.includes("rain") || s.includes("shower"))
            return root._rain;

        if (s.includes("fog") || s.includes("mist") || s.includes("haze"))
            return root._fog;
        if (s.includes("wind") || s.includes("breezy") || s.includes("blustery") || s.includes("gale"))
            return root._windy;

        if (s.includes("partly"))
            return root._partlyCloudy;
        if (s.includes("overcast"))
            return root._overcast;
        if (s.includes("cloud"))
            return root._cloudy;

        if (s.includes("sunny") || s.includes("sunshine") || s.includes("fair") || s.includes("fine"))
            return root._sunny;
        if (s.includes("clear"))
            return root._clear;

        return root._cloudy;
    }
}
