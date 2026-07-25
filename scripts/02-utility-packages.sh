#!/usr/bin/env bash
# 02-utility-packages.sh - Desktop utilities (screenshot, brightness, image tools, etc.)
set -euo pipefail
BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"
export PACKAGE_GROUP="utils"
if [[ "$BASE_DISTRO" == "arch" ]]; then
    bash "$BUNDLE_DIR/sdata/arch-dist/installDP.sh"
elif [[ "$BASE_DISTRO" == "fedora" ]]; then
    bash "$BUNDLE_DIR/sdata/fedora-dist/installDP_fedora.sh"
fi
