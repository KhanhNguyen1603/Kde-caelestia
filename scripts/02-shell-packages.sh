#!/usr/bin/env bash
# 02-shell-packages.sh - Shell wrapper, terminal emulator, and CLI tools
set -euo pipefail
BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"
export PACKAGE_GROUP="shell"
if [[ "$BASE_DISTRO" == "arch" ]]; then
    bash "$BUNDLE_DIR/sdata/arch-dist/installDP.sh"
elif [[ "$BASE_DISTRO" == "fedora" ]]; then
    bash "$BUNDLE_DIR/sdata/fedora-dist/installDP_fedora.sh"
fi
