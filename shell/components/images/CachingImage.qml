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
        const targetW = width > 0 ? width * dpr : 512;
        const targetH = height > 0 ? height * dpr : 512;
        return Qt.size(targetW, targetH);
    }
}
