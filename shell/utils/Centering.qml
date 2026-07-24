pragma Singleton

import Quickshell

Singleton {
    id: root

    // anchors.centerIn positions an item at (containerSize - contentSize) / 2
    // relative to its parent, which is frequently a fractional value (e.g. an
    // odd-sized item in an even-sized container). Since text and shapes using
    // NativeRendering are snapped to whole pixels when drawn, a fractional
    // center is rounded unpredictably and the content ends up looking
    // off-center or blurry.
    //
    // This computes the exact delta needed to nudge the natural center onto
    // the nearest whole pixel, so callers can bind it to
    // anchors.horizontalCenterOffset/verticalCenterOffset instead of relying
    // on hand-tuned magic numbers that only happen to look right for one
    // specific size.
    function pixelAlign(containerSize: real, contentSize: real): real {
        const center = (containerSize - contentSize) / 2;
        return Math.round(center) - center;
    }
}
