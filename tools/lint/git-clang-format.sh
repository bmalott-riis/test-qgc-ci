#!/usr/bin/env bash
#
# Pre-commit wrapper for `git clang-format`. Reformats ONLY the lines changed in
# the current commit (staged hunks), not whole files. This lets us enforce
# .clang-format on new/modified code without mass-reformatting the existing
# non-conforming codebase.
#
# Uses the clang-format bundled with the Android NDK (clang 17) so formatting is
# identical to the toolchain that builds the APK.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Resolve the newest installed NDK 26.x clang-format; fall back to PATH.
NDK_DIR="$(ls -d "${HOME}"/Android/Sdk/ndk/26.* 2>/dev/null | sort -V | tail -1 || true)"
CF_BIN="${NDK_DIR}/toolchains/llvm/prebuilt/linux-x86_64/bin/clang-format"
if [[ ! -x "$CF_BIN" ]]; then
    CF_BIN="clang-format"
fi

# Format only the changed hunks of the passed files, modifying the working tree.
# pre-commit stashes unstaged changes first, so the working tree equals the
# staged content here; diffing against HEAD therefore targets exactly the staged
# hunks. pre-commit then detects the modifications and fails so the user
# re-stages the formatted result.
git clang-format --binary "$CF_BIN" --style=file -- "$@"
