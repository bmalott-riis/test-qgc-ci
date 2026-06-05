#!/usr/bin/env bash
#
# Prints the absolute paths of C/C++ source files under src/ and custom/ that
# have uncommitted changes (staged, unstaged, or untracked) relative to HEAD.
# Used by the "changed" clang-tidy VS Code tasks to scope analysis.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

{
    # Tracked changes (staged + unstaged) vs HEAD.
    git diff --name-only --diff-filter=ACMR HEAD -- src custom
    # Untracked, non-ignored files.
    git ls-files --others --exclude-standard -- src custom
} | { grep -E '\.(cc|cpp|cxx|h|hpp)$' || true; } | sort -u | sed "s|^|${REPO_ROOT}/|"
