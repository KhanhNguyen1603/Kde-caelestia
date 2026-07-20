import QtQuick
import Quickshell
import Caelestia.Images

Image {
    id: root

    property string path

    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    source: IUtils.urlForPath(path, fillMode)
    sourceSize: {
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        const w = width > 0 ? width * dpr : 64;
        const h = height > 0 ? height * dpr : 64;
        return Qt.size(w, h);
    }
}
