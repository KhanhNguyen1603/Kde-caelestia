// SPDX-License-Identifier: GPL-3.0-only
#include "palettemanager.hpp"

#include <cmath>
#include <algorithm>

#include <qloggingcategory.h>

Q_LOGGING_CATEGORY(lcPalette, "caelestia.services.palettemanager", QtInfoMsg)

namespace caelestia::services {

// These are the 44 M3TPalette property names, in the same order as Colours.qml.
// They must match EXACTLY the property names on M3Palette.
static const QStringList kPaletteKeys = {
    "m3primary_paletteKeyColor",
    "m3secondary_paletteKeyColor",
    "m3tertiary_paletteKeyColor",
    "m3neutral_paletteKeyColor",
    "m3neutral_variant_paletteKeyColor",
    "m3background",
    "m3onBackground",
    "m3surface",
    "m3surfaceDim",
    "m3surfaceBright",
    "m3surfaceContainerLowest",
    "m3surfaceContainerLow",
    "m3surfaceContainer",
    "m3surfaceContainerHigh",
    "m3surfaceContainerHighest",
    "m3onSurface",
    "m3surfaceVariant",
    "m3onSurfaceVariant",
    "m3inverseSurface",
    "m3inverseOnSurface",
    "m3outline",
    "m3outlineVariant",
    "m3shadow",
    "m3scrim",
    "m3surfaceTint",
    "m3primary",
    "m3onPrimary",
    "m3primaryContainer",
    "m3onPrimaryContainer",
    "m3inversePrimary",
    "m3secondary",
    "m3onSecondary",
    "m3secondaryContainer",
    "m3onSecondaryContainer",
    "m3tertiary",
    "m3onTertiary",
    "m3tertiaryContainer",
    "m3onTertiaryContainer",
    "m3error",
    "m3onError",
    "m3errorContainer",
    "m3onErrorContainer",
    "m3success",
    "m3onSuccess",
    "m3successContainer",
    "m3onSuccessContainer",
    "m3primaryFixed",
    "m3primaryFixedDim",
    "m3onPrimaryFixed",
    "m3onPrimaryFixedVariant",
    "m3secondaryFixed",
    "m3secondaryFixedDim",
    "m3onSecondaryFixed",
    "m3onSecondaryFixedVariant",
    "m3tertiaryFixed",
    "m3tertiaryFixedDim",
    "m3onTertiaryFixed",
    "m3onTertiaryFixedVariant",
};

// Which keys use layer=0 (base transparency) vs layer=1 (alter colour)
// Matches the Colours.qml: root.layer(color, 0) for bg/surface variants, default layer=1 for others
static const QSet<QString> kLayer0Keys = {
    "m3background",
    "m3surface",
    "m3surfaceDim",
    "m3surfaceBright",
    "m3surfaceVariant",
    "m3inverseSurface",
};

PaletteManager::PaletteManager(QObject* parent)
    : QObject(parent) {}

QVariantMap PaletteManager::tPalette() const { return m_tPalette; }

double PaletteManager::getLuminance(const QColor& c) const {
    const double r = c.redF();
    const double g = c.greenF();
    const double b = c.blueF();
    if (r == 0.0 && g == 0.0 && b == 0.0) return 0.0;
    return std::sqrt(0.299 * r * r + 0.587 * g * g + 0.114 * b * b);
}

QColor PaletteManager::applyLayer(const QColor& c,
                                   bool light,
                                   bool transpEnabled,
                                   double transpBase,
                                   double transpLayers,
                                   double wallLuminance,
                                   int layer) const {
    if (!transpEnabled) return c;

    if (layer == 0) {
        // Base transparency: Qt.alpha(c, transpBase)
        QColor result = c;
        result.setAlphaF(transpBase);
        return result;
    }

    // alterColour: matches Colours.qml alterColour()
    const double luminance = getLuminance(c);
    if (luminance <= 0.0) {
        QColor result = c;
        result.setAlphaF(transpLayers);
        return result;
    }

    const double layerSign = (!light || layer == 1) ? 1.0 : (-static_cast<double>(layer) / 2.0);
    const double lightMul = light ? 0.2 : 0.3;
    const double wallFactor = light
        ? (layer == 1 ? 3.0 : 1.0)
        : 2.5;
    const double offset = layerSign * lightMul * (1.0 - transpBase) * (1.0 + wallLuminance * wallFactor);
    const double scale = (luminance + offset) / luminance;

    const double r = std::clamp(c.redF()   * scale, 0.0, 1.0);
    const double g = std::clamp(c.greenF() * scale, 0.0, 1.0);
    const double b = std::clamp(c.blueF()  * scale, 0.0, 1.0);

    return QColor::fromRgbF(r, g, b, transpLayers);
}

void PaletteManager::update(const QVariantMap& palette,
                             bool light,
                             bool transpEnabled,
                             double transpBase,
                             double transpLayers,
                             double wallLuminance) {
    QVariantMap result;

    for (const auto& key : kPaletteKeys) {
        const auto raw = palette.value(key);
        QColor color;

        // QML may give us a QColor directly or a string
        if (raw.typeId() == QMetaType::QColor) {
            color = raw.value<QColor>();
        } else {
            color = QColor(raw.toString());
        }

        if (!color.isValid()) {
            result.insert(key, raw);
            continue;
        }

        const int layer = kLayer0Keys.contains(key) ? 0 : 1;
        result.insert(key, applyLayer(color, light, transpEnabled,
                                      transpBase, transpLayers,
                                      wallLuminance, layer));
    }

    m_tPalette = result;
    emit tPaletteChanged();
}

} // namespace caelestia::services
