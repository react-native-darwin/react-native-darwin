#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
# Enforces the budgets in MACOS-FORK.md section 6.
#
# The point of this fork is that it stays small and stays rebasable. Those are
# not properties you can maintain by intention; they need a number that fails
# a build. This is that number.
#
# Usage: macos/ci/check-budget.sh [upstream-ref]

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

UPSTREAM_REF="${1:-$(sed -n 's/^UPSTREAM_TAG = //p' MACOS-FORK.md | head -1)}"

MAX_UPSTREAM_FILES_TOUCHED=90
# Raised from 50. Deletions turned out to be the wrong proxy for fork size:
# almost every one is half of a -1/+1 line replacement, such as changing
# `CADisplayLink *x` to `RCTPlatformDisplayLink *x`. That is not upstream code
# being removed, and contorting to avoid it would mean writing worse edits.
# Upstream *files touched* is the metric that actually tracks rebase cost.
MAX_UPSTREAM_LINES_REMOVED=200
MAX_COMMITS=11

if ! git rev-parse --verify --quiet "$UPSTREAM_REF" >/dev/null; then
  echo "error: cannot resolve upstream ref '$UPSTREAM_REF'." >&2
  echo "       Pass it explicitly, or fix UPSTREAM_TAG in MACOS-FORK.md." >&2
  exit 2
fi

# Paths this fork owns. Changes here are free; they never conflict on rebase.
OURS=(':(exclude)macos/' ':(exclude)MACOS-FORK.md')

fail=0
note() { printf '  %s\n' "$1"; }
pass() { printf '\033[32mPASS\033[0m  %s\n' "$1"; }
bad()  { printf '\033[31mFAIL\033[0m  %s\n' "$1"; fail=1; }

echo "Budget check against $UPSTREAM_REF"
echo

# --- 1. upstream files touched -----------------------------------------------

files_touched=$(git diff --name-only "$UPSTREAM_REF"..HEAD -- . "${OURS[@]}" | wc -l | tr -d ' ')
if [ "$files_touched" -le "$MAX_UPSTREAM_FILES_TOUCHED" ]; then
  pass "upstream files touched: $files_touched / $MAX_UPSTREAM_FILES_TOUCHED"
else
  bad "upstream files touched: $files_touched / $MAX_UPSTREAM_FILES_TOUCHED"
  note "The shim is being under-used. See MACOS-FORK.md section 4.1."
  git diff --name-only "$UPSTREAM_REF"..HEAD -- . "${OURS[@]}" | sed 's/^/    /'
fi

# --- 2. upstream lines removed -----------------------------------------------

lines_removed=$(git diff --numstat "$UPSTREAM_REF"..HEAD -- . "${OURS[@]}" \
  | awk '{ if ($2 != "-") s += $2 } END { print s + 0 }')
if [ "$lines_removed" -le "$MAX_UPSTREAM_LINES_REMOVED" ]; then
  pass "upstream lines removed: $lines_removed / $MAX_UPSTREAM_LINES_REMOVED"
else
  bad "upstream lines removed: $lines_removed / $MAX_UPSTREAM_LINES_REMOVED"
  note "Guard upstream code with #if !TARGET_OS_OSX rather than deleting it."
fi

# --- 3. commit count ----------------------------------------------------------

commits=$(git rev-list --count "$UPSTREAM_REF"..HEAD)
if [ "$commits" -le "$MAX_COMMITS" ]; then
  pass "commits on top of upstream: $commits / $MAX_COMMITS"
else
  bad "commits on top of upstream: $commits / $MAX_COMMITS"
  note "Amend or squash rather than appending. See MACOS-FORK.md section 5.4."
fi

# --- 4. every upstream hunk carries a [macOS] marker --------------------------
#
# Walks the diff hunk by hunk. A hunk passes if a [macOS] marker appears on any
# added line in it, or in the three lines of context either side -- which is
# what an existing marker on an enclosing #if block looks like.

unmarked=$(git diff --unified=3 "$UPSTREAM_REF"..HEAD -- . "${OURS[@]}" | awk '
  function flush() {
    # Report against the file the hunk belonged to, not the one being started.
    if (inhunk && changed && !marked) print file ":" hunkline
    inhunk = 0; changed = 0; marked = 0
  }
  /^diff --git/ { flush(); file = $3; sub(/^a\//, "", file); next }
  /^@@/ {
    flush()
    inhunk = 1
    hunkline = $0
    sub(/^@@ -/, "", hunkline); sub(/ .*/, "", hunkline); sub(/,.*/, "", hunkline)
    next
  }
  !inhunk { next }
  /\[macOS/ || /macOS\]/ { marked = 1 }
  /^[+-]/ && !/^(\+\+\+|---)/ { changed = 1 }
  END { flush() }
')

if [ -z "$unmarked" ]; then
  pass "every upstream hunk carries a [macOS] marker"
else
  bad "upstream hunks with no [macOS] marker:"
  echo "$unmarked" | sed 's/^/    /'
  note "See MACOS-FORK.md section 3 for the exact syntax."
fi

# --- 5. renamed UIKit types are confined to declaration sites ------------------
#
# RCTPlatformView is allowed, because macOS genuinely cannot make UIScrollView
# a subclass of a UIView class -- see MACOS-FORK.md section 4.5. But it is only
# allowed where a concrete class is unavoidable: as a superclass, or as the
# receiver of +alloc/+new.
#
# The moment it appears as a pointer type, every `UIView *` in the tree starts
# wanting to be rewritten, and that is the 538-file path this fork exists to
# avoid. Everything else stays a renamed-type violation.

as_pointer=$(git diff "$UPSTREAM_REF"..HEAD -- . "${OURS[@]}" \
  | grep -E '^\+' | grep -E '\bRCTPlatformView[[:space:]]*\*' || true)

other_renames=$(git diff "$UPSTREAM_REF"..HEAD -- . "${OURS[@]}" \
  | grep -E '^\+' | grep -E '\bRCT(UIView|UIColor|PlatformColor|PlatformImage|UIScrollView)\b' || true)

if [ -z "$as_pointer" ] && [ -z "$other_renames" ]; then
  pass "renamed UIKit types confined to declaration sites"
else
  if [ -n "$as_pointer" ]; then
    bad "RCTPlatformView used as a pointer type in upstream code:"
    echo "$as_pointer" | sed 's/^/    /' | head -10
    note "Use UIView * -- it is an alias for NSView and accepts any view."
  fi
  if [ -n "$other_renames" ]; then
    bad "upstream code introduces a renamed UIKit type:"
    echo "$other_renames" | sed 's/^/    /' | head -10
    note "Extend the shim instead. See MACOS-FORK.md section 4.2."
  fi
fi

# --- 6. no [macOS] markers inside our own directory ---------------------------

ours_marked=$(git grep -l -E '\[macOS|macOS\]' -- macos/ 2>/dev/null \
  | grep -v '^macos/ci/check-budget.sh$' \
  | grep -v '^macos/UIKitCompat/README.md$' || true)

if [ -z "$ours_marked" ]; then
  pass "no [macOS] markers inside macos/"
else
  bad "[macOS] markers found inside macos/, where everything is already ours:"
  echo "$ours_marked" | sed 's/^/    /'
fi

echo
if [ "$fail" -eq 0 ]; then
  printf '\033[32mBudget OK\033[0m\n'
else
  printf '\033[31mBudget exceeded\033[0m\n'
fi

echo
echo "Report this in the PR description:"
echo "  Upstream files touched:  $files_touched / $MAX_UPSTREAM_FILES_TOUCHED"
echo "  Upstream lines removed:  $lines_removed / $MAX_UPSTREAM_LINES_REMOVED"
echo "  Commits:                 $commits / $MAX_COMMITS"

exit $fail
