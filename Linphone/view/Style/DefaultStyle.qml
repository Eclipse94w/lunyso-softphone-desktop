pragma Singleton
import QtQuick
import Linphone
import SettingsCpp

QtObject {

	property var currentTheme: Themes.themes.hasOwnProperty(SettingsCpp.themeMainColor)
							  ? Themes.themes[SettingsCpp.themeMainColor]
							  : Themes.themes["lunyso"]
    property var main1_100: currentTheme.main100
    property var main1_200: currentTheme.main200
    property var main1_300: currentTheme.main300
    property var main1_500_main: currentTheme.main500
    property var main1_600: currentTheme.main600
    property var main1_700: currentTheme.main700

    property var main2_0: "#F5F7FA"
    property var main2_100: "#E8EDF3"
    property var main2_200: "#CDD6E3"
    property var main2_300: "#A8B8CC"
    property var main2_400: "#7A93AB"
    property var main2_500_main: "#44546A"
    property var main2_600: "#374455"
    property var main2_700: "#2A3545"
    property var main2_800: "#1E2A3A"
    property var main2_900: "#141E2B"

    property var grey_0: "#FFFFFF"
    property var grey_100: "#F9F9F9"
    property var grey_200: "#EDEDED"
    property var grey_300: "#C9C9C9"
    property var grey_400: "#949494"
    property var grey_500: "#4E4E4E"
    property var grey_600: "#2E3030"
    property var grey_850: "#D9D9D9"
    property var grey_900: "#070707"
    property var grey_1000: "#000000"

    property var warning_600: "#DBB820"
    property var warning_700: "#AF9308"
    property var danger_500_main: "#DD5F5F"
    property var warning_500_main: "#FFDC2E"
    property var danger_700: "#9E3548"
    property var danger_900: "#723333"
    property var success_500_main: "#4FAE80"
    property var success_700: "#377d71"
    property var success_900: "#1E4C53"
    property var info_500_main: "#4AA8FF"
    property var info_800_main: "#02528D"

    property var vue_meter_light_green: "#6FF88D"
    property var vue_meter_dark_green: "#00D916"

    property real defaultHeight: 1007.0
    property real defaultWidth: 1512.0
    property real maxDp: 0.98
    property real dp: Math.min((Screen.width/Screen.height)/(defaultWidth/defaultHeight), maxDp)

    onDpChanged: {
        console.log("Screen ratio changed", dp)
        AppCpp.setScreenRatio(dp)
    }

    // Warning: Qt 6.8.1 (current version) and previous versions, Qt only support COLRv0 fonts. Don't try to use v1.
    property string emojiFont: "Noto Color Emoji"
    property string flagFont: "Noto Color Emoji"
    property string defaultFont: "Noto Sans"

    property var numericPadPressedButtonColor: "#D6E9FF"

    property var groupCallButtonColor: "#D6E9FF"

    property var placeholders: '#CACACA'	// No name in design
    
}
