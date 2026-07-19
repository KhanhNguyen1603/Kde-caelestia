import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property int highlightedLocationIdx: -1
    property var pendingLocation
    readonly property bool compactWeatherPicker: root.cappedWidth < 620

    function selectLocationCandidate(item: var): void {
        if (!item)
            return;

        pendingLocation = item;
        highlightedLocationIdx = -1;
        Weather.locationSearchResults = [];
    }

    function applyPendingLocation(): void {
        if (!pendingLocation)
            return;

        if (Weather.applyLocationResult(pendingLocation)) {
            highlightedLocationIdx = -1;
            Weather.locationSearchResults = [];
            Weather.locationSearchError = "";
            Weather.locationSearchQuery = "";
            locationField.text = "";
        }
    }

    Component.onCompleted: Weather.reload()

    // Temperature units (index 0 = Celsius, 1 = Fahrenheit — matches Weather.formatTemp)
    readonly property list<MenuItem> tempItems: [
        MenuItem {
            text: "°C"
        },
        MenuItem {
            text: "°F"
        }
    ]

    // Clock format (index 0 = 24-hour, 1 = 12-hour — matches Time.useTwelveHourClock)
    readonly property list<MenuItem> clockItems: [
        MenuItem {
            text: qsTr("24-hour")
        },
        MenuItem {
            text: qsTr("12-hour")
        }
    ]

    title: qsTr("Language & region")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Language
        SectionHeader {
            first: true
            text: qsTr("Language")
        }

        // Read-only: the shell follows the system locale (no in-shell translations yet)
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: localeLayout.implicitHeight + localeLayout.anchors.margins * 2

            RowLayout {
                id: localeLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("System language")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Follows your system locale (%1)").arg(Qt.locale().name)
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                StyledText {
                    text: Qt.locale().nativeLanguageName || Qt.locale().name
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }
        }

        // Weather
        SectionHeader {
            text: qsTr("Weather")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: weatherContent.implicitHeight + Tokens.padding.largeIncreased * 2

            ColumnLayout {
                id: weatherContent

                anchors.fill: parent
                anchors.margins: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "location_on"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.large
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: Weather.city || qsTr("Using auto-detected location")
                            font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: GlobalConfig.services.weatherLocation
                                ? qsTr("Saved weather coordinates: %1").arg(GlobalConfig.services.weatherLocation)
                                : qsTr("No fixed location saved")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    CircularIndicator {
                        implicitSize: 18
                        visible: Weather.locationSearchLoading
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    radius: Tokens.rounding.full
                    color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                    border.color: Colours.palette.m3outlineVariant
                    implicitHeight: searchRow.implicitHeight + Tokens.padding.small * 2

                    RowLayout {
                        id: searchRow

                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.medium
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: "search"
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledTextField {
                            id: locationField

                            Layout.fillWidth: true
                            placeholderText: qsTr("Search city or region")
                            text: Weather.locationSearchQuery

                            onTextChanged: {
                                root.highlightedLocationIdx = -1;
                                Weather.queueLocationSearch(text);
                            }

                            Keys.onDownPressed: {
                                if (Weather.locationSearchResults.length === 0)
                                    return;

                                root.highlightedLocationIdx = Math.min(root.highlightedLocationIdx + 1, Weather.locationSearchResults.length - 1);
                            }

                            Keys.onUpPressed: {
                                if (Weather.locationSearchResults.length === 0)
                                    return;

                                if (root.highlightedLocationIdx < 0)
                                    root.highlightedLocationIdx = Weather.locationSearchResults.length - 1;
                                else
                                    root.highlightedLocationIdx = Math.max(root.highlightedLocationIdx - 1, 0);
                            }

                            Keys.onReturnPressed: {
                                if (Weather.locationSearchResults.length === 0)
                                    return;

                                const idx = root.highlightedLocationIdx >= 0 ? root.highlightedLocationIdx : 0;
                                root.selectLocationCandidate(Weather.locationSearchResults[idx]);
                            }
                        }

                        IconButton {
                            icon: "close"
                            type: IconButton.Text
                            disabled: locationField.text.length === 0

                            onClicked: {
                                locationField.text = "";
                                root.pendingLocation = null;
                                Weather.locationSearchResults = [];
                                Weather.locationSearchError = "";
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    radius: Tokens.rounding.large
                    color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)
                    visible: Weather.locationSearchError || (!Weather.locationSearchLoading && locationField.text.length >= 2)
                    implicitHeight: resultsColumn.implicitHeight + Tokens.padding.small * 2

                    ColumnLayout {
                        id: resultsColumn

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            Layout.fillWidth: true
                            visible: Weather.locationSearchError.length > 0
                            text: Weather.locationSearchError
                            wrapMode: Text.WordWrap
                            color: Colours.palette.m3error
                            font: Tokens.font.label.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: !Weather.locationSearchError && locationField.text.length >= 2 && Weather.locationSearchResults.length === 0
                            text: qsTr("No matching locations")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                        }

                        Repeater {
                            model: Weather.locationSearchResults

                            StyledRect {
                                id: resultRow

                                required property int index
                                required property var modelData

                                readonly property bool highlighted: root.highlightedLocationIdx === resultRow.index

                                Layout.fillWidth: true
                                radius: Tokens.rounding.medium
                                color: highlighted ? Colours.layer(Colours.palette.m3secondaryContainer, 2) : "transparent"
                                implicitHeight: resultText.implicitHeight + Tokens.padding.small * 2

                                StateLayer {
                                    anchors.fill: parent
                                    radius: resultRow.radius
                                    onClicked: root.selectLocationCandidate(resultRow.modelData)
                                }

                                Column {
                                    id: resultText

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: Tokens.padding.small
                                    anchors.rightMargin: Tokens.padding.small
                                    spacing: 0

                                    StyledText {
                                        text: resultRow.modelData.label || resultRow.modelData.name
                                        font: Tokens.font.body.small
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        text: resultRow.modelData.timezone || ""
                                        color: Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.label.small
                                        visible: text.length > 0
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: actionFlow.implicitHeight

                    Flow {
                        id: actionFlow

                        width: parent.width
                        spacing: Tokens.spacing.small

                        TextButton {
                            type: TextButton.Filled
                            text: qsTr("Apply location")
                            disabled: !root.pendingLocation
                            onClicked: root.applyPendingLocation()
                        }

                        TextButton {
                            type: TextButton.Tonal
                            text: qsTr("Use auto-detect")
                            onClicked: {
                                root.pendingLocation = null;
                                root.highlightedLocationIdx = -1;
                                Weather.locationSearchQuery = "";
                                Weather.locationSearchResults = [];
                                Weather.locationSearchError = "";
                                locationField.text = "";
                                Weather.resetToAutoLocation();
                            }
                        }

                        StyledText {
                            width: root.compactWeatherPicker ? Math.max(120, actionFlow.width - Tokens.padding.extraLarge * 2) : 260
                            text: root.pendingLocation ? (root.pendingLocation.label || root.pendingLocation.name) : qsTr("No location selected")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            visible: root.compactWeatherPicker
        }

        // Units
        SectionHeader {
            text: qsTr("Units")
        }

        SelectRow {
            first: true
            label: qsTr("Temperature")
            subtext: qsTr("Units for weather temperatures")
            menuItems: root.tempItems
            active: root.tempItems[GlobalConfig.services.useFahrenheit ? 1 : 0]
            onSelected: item => GlobalConfig.services.useFahrenheit = root.tempItems.indexOf(item) === 1
        }

        SelectRow {
            last: true
            label: qsTr("System temperatures")
            subtext: qsTr("Units for CPU and GPU temperatures")
            menuItems: root.tempItems
            active: root.tempItems[GlobalConfig.services.useFahrenheitPerformance ? 1 : 0]
            onSelected: item => GlobalConfig.services.useFahrenheitPerformance = root.tempItems.indexOf(item) === 1
        }

        // Time & date
        SectionHeader {
            text: qsTr("Time & date")
        }

        SelectRow {
            first: true
            last: true
            label: qsTr("Clock format")
            subtext: qsTr("How times are shown across the shell")
            menuItems: root.clockItems
            active: root.clockItems[GlobalConfig.services.useTwelveHourClock ? 1 : 0]
            onSelected: item => GlobalConfig.services.useTwelveHourClock = root.clockItems.indexOf(item) === 1
        }
    }
}
