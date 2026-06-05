#!/usr/bin/env bash
#
# Project-local clang-tidy runner for QGroundControl.
#
# Uses the clang-tidy bundled with the Android NDK (clang 17), so the analyzer
# version matches the compiler that builds the APK. This avoids the
# "PCH file uses a newer PCH format" errors caused by version mismatches.
#
# Usage:
#   tools/lint/clang-tidy.sh [BUILD_DIR] [extra run-clang-tidy args...]
#
# Defaults to the Android Debug build (the primary target). Pass a different
# build directory to lint another configuration, e.g.:
#   tools/lint/clang-tidy.sh build/Desktop_Qt_6_8_3-Debug
#
# By default the whole src/ and custom/ trees are analyzed. Set CLANG_TIDY_PATHS
# to a space-separated list of paths/regexes to scope it instead, e.g. to lint
# only files changed since HEAD (see the "changed" VS Code tasks).
#
# Header scoping (src/ and custom/ only) lives in .clang-tidy (HeaderFilterRegex).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Resolve the newest installed NDK 26.x toolchain.
NDK_DIR="$(ls -d "${HOME}"/Android/Sdk/ndk/26.* 2>/dev/null | sort -V | tail -1 || true)"
if [[ -z "$NDK_DIR" ]]; then
    echo "error: no Android NDK 26.x found under ${HOME}/Android/Sdk/ndk/" >&2
    exit 1
fi
NDK_CLANG_TIDY="${NDK_DIR}/toolchains/llvm/prebuilt/linux-x86_64/bin/clang-tidy"
if [[ ! -x "$NDK_CLANG_TIDY" ]]; then
    echo "error: clang-tidy not found at $NDK_CLANG_TIDY" >&2
    exit 1
fi

BUILD_DIR="${1:-build/Qt_6_8_3_for_Android_arm64_v8a-Debug}"
shift || true

if [[ ! -f "${BUILD_DIR}/compile_commands.json" ]]; then
    echo "error: ${BUILD_DIR}/compile_commands.json not found." >&2
    echo "       Configure the build first (CMAKE_EXPORT_COMPILE_COMMANDS=ON)." >&2
    exit 1
fi

# Files/regexes to analyze. Defaults to our whole source tree; CLANG_TIDY_PATHS
# overrides this (custom/ matches nothing if absent). Note: we test whether the
# variable is *set* (not whether it's non-empty), so the changed-files tasks can
# pass an empty list to mean "nothing changed, lint nothing" rather than "lint
# everything".
if [[ -n "${CLANG_TIDY_PATHS+set}" ]]; then
    # shellcheck disable=SC2206
    PATHS=(${CLANG_TIDY_PATHS})
    if [[ ${#PATHS[@]} -eq 0 ]]; then
        echo "No matching changed files to lint."
        exit 0
    fi
else
    PATHS=("${REPO_ROOT}/src/" "${REPO_ROOT}/custom/")
fi

exec run-clang-tidy \
    -clang-tidy-binary "$NDK_CLANG_TIDY" \
    -p "$BUILD_DIR" \
    "$@" \
    "${PATHS[@]}"
