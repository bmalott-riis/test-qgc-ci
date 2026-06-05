#!/usr/bin/env bash
#
# Wrapper for `git clang-format`. Reformats ONLY the changed lines (not whole
# files), so we can enforce .clang-format on new/modified code without
# mass-reformatting the existing non-conforming codebase.
#
# Works in two contexts:
#   * Local pre-commit  -> diffs the staged content against HEAD (staged hunks).
#   * Pull-request CI    -> diffs against the PR base branch (GITHUB_BASE_REF),
#                           so it checks exactly the lines the PR touches.
#
# clang-format version is pinned to 17 where possible to match the Android NDK
# (clang 17) that builds the APK, keeping local and CI formatting identical.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

NDK_DIR="$(ls -d "${HOME}"/Android/Sdk/ndk/26.* 2>/dev/null | sort -V | tail -1 || true)"
NDK_BIN_DIR="${NDK_DIR:+${NDK_DIR}/toolchains/llvm/prebuilt/linux-x86_64/bin}"

# Return the first candidate that exists on PATH (or as an absolute executable).
resolve() {
    local candidate
    for candidate in "$@"; do
        [[ -n "$candidate" ]] || continue
        if command -v "$candidate" >/dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

# Resolve clang-format, preferring v17 to match the NDK toolchain.
CF_BIN="$(resolve \
    "${NDK_BIN_DIR:+${NDK_BIN_DIR}/clang-format}" \
    clang-format-17 clang-format-18 clang-format-16 clang-format)" || {
    echo "error: no clang-format binary found on PATH or in the NDK." >&2
    exit 1
}

# Resolve the git-clang-format driver script.
GCF_BIN="$(resolve \
    "${NDK_BIN_DIR:+${NDK_BIN_DIR}/git-clang-format}" \
    git-clang-format git-clang-format-17 git-clang-format-18 git-clang-format-16)" || {
    echo "error: no git-clang-format script found on PATH or in the NDK." >&2
    exit 1
}

# Choose the commit to diff against. In PR CI, use the base branch tip so only
# PR-introduced lines are checked; locally, omit it so git-clang-format uses the
# default (HEAD), i.e. the staged hunks pre-commit prepared.
DIFF_BASE=()
if [[ -n "${GITHUB_BASE_REF:-}" ]]; then
    git fetch --quiet --depth=1 origin "$GITHUB_BASE_REF" 2>/dev/null || true
    DIFF_BASE=("origin/${GITHUB_BASE_REF}")
fi

"$GCF_BIN" "${DIFF_BASE[@]}" --binary "$CF_BIN" --style=file -- "$@"
