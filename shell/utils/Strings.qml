pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property var _regexCache: ({})

    readonly property bool useAmericanEnglish: {
        const localeName = (Qt.locale().name || "").replace("-", "_");
        return localeName.startsWith("en_US");
    }

    function localizeEnglishSpelling(text: string): string {
        if (!text || text.length === 0)
            return text;

        const rules = useAmericanEnglish
            ? [
                ["Colours", "Colors"],
                ["Colour", "Color"],
                ["colours", "colors"],
                ["colour", "color"],
                ["Recolour", "Recolor"],
                ["recolour", "recolor"],
                ["Favourites", "Favorites"],
                ["Favourite", "Favorite"],
                ["favourites", "favorites"],
                ["favourite", "favorite"],
                ["Behaviour", "Behavior"],
                ["behaviour", "behavior"]
            ]
            : [
                ["Colors", "Colours"],
                ["Color", "Colour"],
                ["colors", "colours"],
                ["color", "colour"],
                ["Recolor", "Recolour"],
                ["recolor", "recolour"],
                ["Favorites", "Favourites"],
                ["Favorite", "Favourite"],
                ["favorites", "favourites"],
                ["favorite", "favourite"],
                ["Behavior", "Behaviour"],
                ["behavior", "behaviour"]
            ];

        const escapeRegExp = (s: string): string => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
        let normalized = text;
        for (const [from, to] of rules)
            normalized = normalized.replace(new RegExp(`\\b${escapeRegExp(from)}\\b`, "g"), to);
        return normalized;
    }

    function testRegexList(filterList: list<string>, target: string): bool {
        const regexChecker = /^\^.*\$$/;
        for (const filter of filterList) {
            if (regexChecker.test(filter)) {
                let re = _regexCache[filter];
                if (!re) {
                    re = new RegExp(filter);
                    _regexCache[filter] = re;
                }
                if (re.test(target))
                    return true;
            } else {
                if (filter === target)
                    return true;
            }
        }
        return false;
    }
}
