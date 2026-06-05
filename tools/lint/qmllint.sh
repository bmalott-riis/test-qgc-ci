#!/usr/bin/env bash
#
# Wrapper for qmllint that resolves the Qt 6 installation automatically.
# Tries the newest Qt 6 gcc_64 install under ~/Qt, then falls back to PATH.
# This avoids hardcoding a username in .pre-commit-config.yaml.

set -euo pipefail

# Find the newest Qt 6 desktop install, e.g. ~/Qt/6.8.3/gcc_64/bin/qmllint
QT_BIN="$(ls -d "${HOME}"/Qt/6.*/gcc_64/bin/qmllint 2>/dev/null | sort -V | tail -1 || true)"

if [[ -x "$QT_BIN" ]]; then
    exec "$QT_BIN" "$@"
elif command -v qmllint >/dev/null 2>&1; then
    exec qmllint "$@"
else
    echo "error: qmllint not found. Install Qt 6 or add it to PATH." >&2
    exit 1
fi
