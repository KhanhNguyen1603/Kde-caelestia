#!/usr/bin/env bash
# 02-core-packages.sh - Core system packages, build tools, and libraries
set -euo pipefail
BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"
export PACKAGE_GROUP="core"
if [[ "${BASE_DISTRO:-}" == "arch" ]]; then
    bash "$BUNDLE_DIR/sdata/arch-dist/installDP.sh"
elif [[ "${BASE_DISTRO:-}" == "fedora" ]]; then
    bash "$BUNDLE_DIR/sdata/fedora-dist/installDP_fedora.sh"
else
    echo "[ERR] BASE_DISTRO must be 'arch' or 'fedora' (got '${BASE_DISTRO:-unset}')" >&2
    exit 1
fi
