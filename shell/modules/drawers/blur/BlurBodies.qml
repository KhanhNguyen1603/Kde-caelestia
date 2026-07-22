import QtQuick
import Quickshell

Region {
    required property real bX
    required property real bY
    required property real bW
    required property real bH
    required property real inLeft
    required property real inRight
    required property real inTop
    required property real inBottom
    // These are big rectangles bluring most of the body
    Region { x: inLeft; y: inTop; width: Math.max(0, inRight - inLeft); height: Math.max(0, inBottom - inTop) } // Center
    Region { x: bX; y: inTop; width: Math.max(0, inLeft - bX); height: Math.max(0, inBottom - inTop) } // Left
    Region { x: inRight; y: inTop; width: Math.max(0, bX + bW - inRight); height: Math.max(0, inBottom - inTop) } // Right
    Region { x: inLeft; y: bY; width: Math.max(0, inRight - inLeft); height: Math.max(0, inTop - bY) } // Top
    Region { x: inLeft; y: inBottom; width: Math.max(0, inRight - inLeft); height: Math.max(0, bY + bH - inBottom) } // Bottom
}
