#!/usr/bin/env bash
set -uo pipefail

# Move to the root of the repository
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT" || exit 1

tmp_file="$(mktemp)"

# Find files with CRLF (ignoring .git directory)
find . -path "./.git" -prune -o -type f -print0 | xargs -0 grep -Il $'\r' > "$tmp_file" || true

if [ -s "$tmp_file" ]; then
    echo "::error::CRLF line endings detected in the following files:"
    cat "$tmp_file" | while read -r file; do
        echo "::error::  $file"
    done
    echo "::error::Because of the global .gitattributes rule, this usually means your Git client is misconfigured, or you bypassed Git."
    echo "::error::Please fix these files to use LF (Unix) line endings (e.g. by running 'dos2unix <file>') and push again."
    rm -f "$tmp_file"
    exit 1
else
    echo "No CRLF files found. Line endings look good!"
fi

rm -f "$tmp_file"
