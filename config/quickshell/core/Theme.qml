pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
    readonly property string generatedThemePath: configHome + "/mango-titus/quickshell/generated-theme.json"

    // Fallbacks match the previous hardcoded Kanagawa-inspired palette.
    readonly property bool dark: colors.loaded ? colors.dark : true
    readonly property string transparent: "#00000000"
    readonly property string bg: colorOr(colors.bg, dark ? "#181616" : "#f2ecdc")
    readonly property string barBackground: colorOr(colors.barBackground, dark ? "#e6181616" : "#eef2ecdc")
    readonly property string surface: colorOr(colors.surface, dark ? "#252323" : "#e7dfcc")
    readonly property string surfaceHover: colorOr(colors.surfaceHover, dark ? "#343131" : "#ddd3bd")
    readonly property string surfaceActive: colorOr(colors.surfaceActive, dark ? "#3b2928" : "#ead6cf")
    readonly property string border: colorOr(colors.border, dark ? "#403c3b" : "#c7bda7")
    readonly property string borderStrong: colorOr(colors.borderStrong, dark ? "#5a5552" : "#aaa087")
    readonly property string text: colorOr(colors.text, dark ? "#c5c9c5" : "#545464")
    readonly property string textStrong: colorOr(colors.textStrong, dark ? "#dcd7ba" : "#363646")
    readonly property string textMuted: colorOr(colors.textMuted, dark ? "#a6a69c" : "#727169")
    readonly property string placeholder: colorOr(colors.placeholder, dark ? "#727169" : "#8a8980")
    readonly property string accent: colorOr(colors.accent, dark ? "#c4746e" : "#c84053")
    readonly property string accentSecondary: colorOr(colors.accentSecondary, dark ? "#658594" : "#4d699b")
    readonly property string accentText: colorOr(colors.accentText, dark ? "#181616" : "#f2ecdc")
    readonly property string success: colorOr(colors.success, dark ? "#8a9a73" : "#6f894e")
    readonly property string warning: colorOr(colors.warning, dark ? "#c8b36a" : "#b6923f")
    readonly property string danger: colorOr(colors.danger, dark ? "#e46876" : "#c84053")
    readonly property string dangerSurface: colorOr(colors.dangerSurface, dark ? "#452b2e" : "#f0d5da")
    readonly property string shadow: colorOr(colors.shadow, "#70000000")

    readonly property string fontFamily: "MesloLGS Nerd Font Mono"
    readonly property string iconFontFamily: fontFamily
    readonly property string themeName: colors.loaded ? colors.name : ""

    readonly property int panelHeight: 36
    readonly property int panelMargin: 0
    readonly property int panelEdgeMargin: 0
    readonly property int panelGap: 4
    readonly property int popupMargin: 18
    readonly property int popupSpacing: 12
    readonly property int rowSpacing: 10
    readonly property int listSpacing: 4
    readonly property int compactSpacing: 2
    readonly property int tightSpacing: 3
    readonly property int sectionSpacing: 14
    readonly property int radius: 6
    readonly property int smallRadius: 6
    readonly property int barRadius: 0
    readonly property int pillRadius: 6
    readonly property int pillHeight: 26
    readonly property int pillHorizontalPadding: 9
    readonly property int pillBorderWidth: 1
    readonly property int animationFast: 120
    readonly property int animationNormal: 180
    readonly property int buttonHeight: 30
    readonly property int chipHeight: 28
    readonly property int workspaceButtonSize: 22
    readonly property int compactButtonHeight: 40
    readonly property int confirmButtonHeight: 48
    readonly property int notificationAccentWidth: 4
    readonly property int notificationAccentRadius: 2
    readonly property int titleFontSize: 18
    readonly property int bodyFontSize: 14
    readonly property int panelFontSize: 13
    readonly property int smallFontSize: 12
    readonly property int tinyFontSize: 10
    readonly property int inputFontSize: 16
    readonly property int iconSize: 28
    readonly property int trayItemSize: 24
    readonly property int trayIconSize: 18
    readonly property int closeButtonSize: 30

    function colorOr(value, fallback) {
        return value && value.length > 0 ? value : fallback;
    }

    FileView {
        id: themeFile

        path: root.generatedThemePath
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: colors.loaded = true
        onLoadFailed: colors.loaded = false

        adapter: JsonAdapter {
            id: colors

            property bool loaded: false
            property bool dark: true
            property string name: ""
            property string bg: ""
            property string barBackground: ""
            property string surface: ""
            property string surfaceHover: ""
            property string surfaceActive: ""
            property string border: ""
            property string borderStrong: ""
            property string text: ""
            property string textStrong: ""
            property string textMuted: ""
            property string placeholder: ""
            property string accent: ""
            property string accentSecondary: ""
            property string accentText: ""
            property string success: ""
            property string warning: ""
            property string danger: ""
            property string dangerSurface: ""
            property string shadow: ""
        }
    }
}
