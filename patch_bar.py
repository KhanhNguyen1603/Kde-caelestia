import re

with open("shell/modules/bar/Bar.qml", "r") as f:
    content = f.read()

# Remove width and height bindings from GridLayouts
content = re.sub(r'(\s+)width:\s*isHorizontal\s*\?\s*\(root\.[a-z]+Flex\s*\?\s*Math\.min\(implicitWidth,\s*maxAvailableWidth\)\s*:\s*implicitWidth\)\s*:\s*implicitWidth', r'', content)
content = re.sub(r'(\s+)height:\s*!isHorizontal\s*\?\s*\(root\.[a-z]+Flex\s*\?\s*Math\.min\(implicitHeight,\s*maxAvailableHeight\)\s*:\s*implicitHeight\)\s*:\s*implicitHeight', r'', content)

# Add zone tracking to WrappedLoader
new_wrapped_loader = """        property real zoneMaxAvailableWidth: {
            let p = parent;
            while (p) {
                if (p === leftLayout) return leftLayout.maxAvailableWidth;
                if (p === middleLayout) return middleLayout.maxAvailableWidth;
                if (p === rightLayout) return rightLayout.maxAvailableWidth;
                p = p.parent;
            }
            return -1;
        }
        property real zoneMaxAvailableHeight: {
            let p = parent;
            while (p) {
                if (p === leftLayout) return leftLayout.maxAvailableHeight;
                if (p === middleLayout) return middleLayout.maxAvailableHeight;
                if (p === rightLayout) return rightLayout.maxAvailableHeight;
                p = p.parent;
            }
            return -1;
        }

        property bool isFlexible: id === "spacer" || id === "dock"
        Layout.fillWidth: root.isHorizontal ? isFlexible : false
        Layout.fillHeight: !root.isHorizontal ? isFlexible : false

        Layout.preferredWidth: root.isHorizontal ? (isFlexible ? -1 : implicitWidth) : implicitWidth
        Layout.preferredHeight: !root.isHorizontal ? (isFlexible ? -1 : implicitHeight) : implicitHeight
        Layout.maximumWidth: root.isHorizontal ? (isFlexible && zoneMaxAvailableWidth !== -1 ? Math.max(root.minFlexWidth, zoneMaxAvailableWidth) : implicitWidth) : implicitWidth
        Layout.maximumHeight: !root.isHorizontal ? (isFlexible && zoneMaxAvailableHeight !== -1 ? Math.max(root.minFlexHeight, zoneMaxAvailableHeight) : implicitHeight) : implicitHeight
        Layout.minimumWidth: root.isHorizontal ? (id === "dock" ? root.minFlexWidth : (isFlexible ? 0 : implicitWidth)) : implicitWidth
        Layout.minimumHeight: !root.isHorizontal ? (id === "dock" ? root.minFlexHeight : (isFlexible ? 0 : implicitHeight)) : implicitHeight"""

content = re.sub(r'(\s+)property bool isFlexible:.*Layout\.minimumHeight:.*implicitHeight', new_wrapped_loader, content, flags=re.DOTALL)

with open("shell/modules/bar/Bar.qml", "w") as f:
    f.write(content)

