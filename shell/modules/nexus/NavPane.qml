import "navpane"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus

ColumnLayout {
    id: root

    required property NexusState nState

    spacing: Tokens.spacing.large

    SearchBar {
        Layout.fillWidth: true
        nState: root.nState
        onSearchCommitted: {
            if (root.nState.searchOpen) {
                searchResults.executeSelected();
            }
        }
        onUpPressed: {
            if (root.nState.searchOpen) {
                searchResults.moveUp();
            }
        }
        onDownPressed: {
            if (root.nState.searchOpen) {
                searchResults.moveDown();
            }
        }
    }

    NavLocations {
        visible: !root.nState.searchOpen

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: -topMargin
        Layout.bottomMargin: -bottomMargin
        nState: root.nState
    }

    SearchResults {
        id: searchResults
        visible: root.nState.searchOpen

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: -topMargin
        Layout.bottomMargin: -bottomMargin
        nState: root.nState
    }
}
