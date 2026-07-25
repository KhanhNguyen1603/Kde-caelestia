#!/usr/bin/env bash
# 02a-submodules.sh - Initialize git submodules

set -euo pipefail

# Initialize submodules
if [[ -f "$BUNDLE_DIR/.gitmodules" ]]; then
    echo "[INFO]  Initializing submodules..."
    git submodule sync --recursive >/dev/null 2>&1 || true
    git submodule update --init --recursive --force >/dev/null 2>&1 || echo "[FAIL]  Failed to initialize all submodules." >&2
fi