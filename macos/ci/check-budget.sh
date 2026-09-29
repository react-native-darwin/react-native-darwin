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

# Raised from 135 for the migration off @compatibility_alias. Every public
# header that named a UIKit type now names an RCT* one instead, because a
# dependency must not claim global names: any library declaring `UIView` --
# expo-modules-core, reanimated, safe-area-context and screens all do -- could
# not compile alongside this fork. See macos/PLAN-drop-uikit-aliases.md.
#
# The fork gets bigger in order to stop being invasive. That is the right
# trade, and it is worth stating plainly rather than hiding: a 4.5x smaller
# fork is worth nothing if adopting it forces every user to patch their other
# dependencies. The anchor to hold to is react-native-macos's 526 modified
# files; this budget keeps us well under half of that.
MAX_UPSTREAM_FILES_MODIFIED=200
# Raised from 50. Deletions turned out to be the wrong proxy for fork size:
# almost every one is half of a -1/+1 line replacement, such as changing
# `CADisplayLink *x` to `RCTPlatformDisplayLink *x`. That is not upstream code
# being removed, and contorting to avoid it would mean writing worse edits.
# Upstream *files touched* is the metric that actually tracks rebase cost.
# Raised from 200 alongside the file budget above, and for the same reason:
# renaming a type in a header is a -1/+1 line replacement, so the migration
# adds roughly one deletion per renamed line.
MAX_UPSTREAM_LINES_REMOVED=450
# Raised from 13 to admit one commit for the bugs that only surface when the
# host app is actually driven: the animated module, the scroll crash and
# Modal. The cap exists to keep review burden down, not to force unrelated
# work into one commit, so new topics get their own commit and the diff
# budgets above stay the real measure of fork size.
# One commit per topic. 15 was the alias migration, which stays a single commit
# because each of its waves amended rather than appended; 16 is the macOS-only
# TextInput props. Parity work will keep adding topics, so expect this to move
# -- the diff budgets above are the real measure of fork size, and they are
# what should be defended.
MAX_COMMITS=16

if ! git rev-parse --verify --quiet "$UPSTREAM_REF" >/dev/null; then
  echo "error: cannot resolve upstream ref '$UPSTREAM_REF'." >&2
  echo "       Pass it explicitly, or fix UPSTREAM_TAG in MACOS-FORK.md." >&2
  exit 2
fi

# Paths this fork owns. Changes here are free; they never conflict on rebase.
#
# GitHub requires workflows to live at .github/workflows/, so fork-owned ones
# cannot sit under macos/ with everything else. They carry a `macos-` prefix
# instead, which is what makes them recognisable here.
OURS=(
  ':(exclude)macos/'
  ':(exclude)MACOS-FORK.md'
  ':(exclude).github/workflows/macos-*.yml'
)

fail=0
note() { printf '  %s\n' "$1"; }
pass() { printf '\033[32mPASS\033[0m  %s\n' "$1"; }
bad()  { printf '\033[31mFAIL\033[0m  %s\n' "$1"; fail=1; }

echo "Budget check against $UPSTREAM_REF"
echo

# --- 1. upstream files touched -----------------------------------------------
#
# Only files that already existed upstream are budgeted. A file this fork adds
# -- Platform.macos.js, or anything under components/view/platform/macos/ --
# has no upstream counterpart to conflict with, so it costs nothing at rebase
# time, which is the thing this number exists to bound. Added files are counted
# and printed anyway, because a fork that grows without limit is still worth
# seeing, just not worth failing a build over.

changed=$(git diff --name-status "$UPSTREAM_REF"..HEAD -- . "${OURS[@]}")
files_added=$(printf '%s\n' "$changed" | grep -c $'^A\t' || true)
modified=$(printf '%s\n' "$changed" | grep -v $'^A\t' | cut -f2-)

# A third category, alongside modified and added: the platform gate.
#
# Core asks `Platform.OS === 'ios'` in about forty places, and macOS now
# answers no to all of them -- so it takes the Android branch, or none. Every
# fix is the same single predicate, in a file the fork otherwise never touches.
# Counting those as ordinary modifications says the shim is being under-used,
# which is precisely backwards: there is no shim answer to a JS platform check.
#
# Detected rather than declared: a file qualifies only if EVERY line its diff
# adds or removes is part of one of those predicates -- the test itself, a
# comment, or a continuation of the same expression (`? null`, `: NativeFoo,`,
# a lone brace). One substantive line and it counts as a normal modification
# again.
files_gated=0
files_touched=0
for f in $modified; do
  body=$(git diff -U0 "$UPSTREAM_REF"..HEAD -- "$f" \
    | grep -E '^[-+]' | grep -Ev '^(\+\+\+|---)' \
    | sed -E 's/^[-+][[:space:]]*//' \
    | grep -Ev '^(//|\*|/\*|$)')
  # Continuations of the widened expression, which carry no logic of their own.
  leftover=$(printf '%s\n' "$body" \
    | grep -v 'Platform\.OS' \
    | grep -Ev '^[?:][[:space:]]*[A-Za-z_$][A-Za-z0-9_.$]*,?$' \
    | grep -Ev '^[?:][[:space:]]*(null|undefined),?$' \
    | grep -Ev '^[){}][[:space:]]*\{?$' \
    | grep -Ev '^&&$')
  if [ -n "$body" ] && [ -z "$leftover" ]; then
    files_gated=$((files_gated + 1))
  else
    files_touched=$((files_touched + 1))
  fi
done

if [ "$files_touched" -le "$MAX_UPSTREAM_FILES_MODIFIED" ]; then
  pass "upstream files modified: $files_touched / $MAX_UPSTREAM_FILES_MODIFIED  (+$files_added added, $files_gated platform gates)"
else
  bad "upstream files modified: $files_touched / $MAX_UPSTREAM_FILES_MODIFIED  (+$files_added added, $files_gated platform gates)"
  note "The shim is being under-used. See MACOS-FORK.md section 4.1."
  printf '%s\n' "$modified" | sed 's/^/    /'
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
# Walks the diff hunk by hunk. A hunk passes if a [macOS] marker appears in it
# or in the three lines of context either side -- which is what an existing
# marker on an enclosing #if block looks like.
#
# A hunk also passes if its only change is the platform vocabulary: `UIView *`
# to `RCTPlatformView *` and the rest of the map below, plus the import that
# declares them. Those renames are the alias migration, they run to hundreds of
# hunks across the installed headers, and a marker on each would be noise that
# teaches a reader nothing. Anything else in the hunk still needs its marker,
# so the rule keeps its point: no unexplained change to upstream code.

unmarked=$(git diff --unified=3 "$UPSTREAM_REF"..HEAD -- . "${OURS[@]}" | python3 -c '
import re, sys

# The vocabulary is derived, not listed: every neutral name is the UIKit one
# with the prefix swapped, so this needs no maintenance as the map grows.
PAT = re.compile(r"\bRCT(?:Platform|UI)(\w+)\b")

def to_uikit(m):
    return "UI" + m.group(1)
IMPORT = "#import <RCTPlatformTypes/RCTPlatformTypes.h>"

def normalise(lines):
    out = []
    for ln in lines:
        body = ln[1:]
        if body.strip() in (IMPORT, "#ifdef __OBJC__", "#endif"):
            continue
        out.append(PAT.sub(to_uikit, body))
    return out

def report(state):
    if not state["changed"]:
        return
    if state["marked"]:
        return
    if normalise(state["minus"]) == normalise(state["plus"]):
        return
    print(state["file"] + ":" + state["line"])

state = {"file": "", "line": "", "changed": False, "marked": False,
         "minus": [], "plus": [], "inhunk": False}

def reset():
    state.update(changed=False, marked=False, minus=[], plus=[])

for raw in sys.stdin:
    ln = raw.rstrip("\n")
    if ln.startswith("diff --git"):
        if state["inhunk"]:
            report(state)
        state["inhunk"] = False
        reset()
        state["file"] = re.sub(r"^a/", "", ln.split()[2])
        continue
    if ln.startswith("@@"):
        if state["inhunk"]:
            report(state)
        reset()
        state["inhunk"] = True
        state["line"] = ln.split()[1].lstrip("-").split(",")[0]
        continue
    if not state["inhunk"]:
        continue
    if "[macOS" in ln or "macOS]" in ln:
        state["marked"] = True
    if ln.startswith("+") and not ln.startswith("+++"):
        state["changed"] = True
        state["plus"].append(ln)
    elif ln.startswith("-") and not ln.startswith("---"):
        state["changed"] = True
        state["minus"].append(ln)

if state["inhunk"]:
    report(state)
')

if [ -z "$unmarked" ]; then
  pass "every upstream hunk carries a [macOS] marker"
else
  bad "upstream hunks with no [macOS] marker:"
  echo "$unmarked" | sed 's/^/    /'
  note "See MACOS-FORK.md section 3 for the exact syntax."
fi

# --- 4b. the shim registers no UIKit class name with the ObjC runtime ---------
#
# The shim exists to provide UIKit *compile-time* names. Making them real
# runtime classes is a different thing entirely, and it bites: Apple's own
# frameworks decide a process is Catalyst by asking NSClassFromString for a
# UIKit class. macOS's one-time-code AutoFill does it for whichever text field
# holds focus, and a yes sends it into UIKitMacHelper, which dlopens a
# UIKit.framework that does not exist on this platform and takes the process
# down -- from nothing more than clicking into a TextInput.
#
# So every class is declared under an RCTUIKitCompat name and handed to callers
# through @compatibility_alias, which is a compile-time rename and registers
# nothing. This check keeps it that way.

runtime_uikit=$(grep -rhnE '^@(interface|implementation)[[:space:]]+UI[A-Za-z]+' macos/UIKitCompat/UIKit/ 2>/dev/null || true)
if [ -z "$runtime_uikit" ]; then
  pass "shim declares no UIKit-named ObjC class"
else
  bad "shim declares a UIKit-named ObjC class"
  note "Declare it as RCTUIKitCompat<Name> and add @compatibility_alias."
  printf '%s\n' "$runtime_uikit" | sed 's/^/    /'
fi

# --- 5. renamed UIKit types are confined to declaration sites ------------------
#
# RCTUIView is allowed, because macOS genuinely cannot make UIScrollView a
# subclass of a UIView class -- see MACOS-FORK.md section 4.5. But it is only
# allowed where a concrete class is unavoidable: as a superclass, or as the
# receiver of +alloc/+new.
#
# The moment it appears as a pointer type, every `UIView *` in the tree starts
# wanting to be rewritten, and that is the 538-file path this fork exists to
# avoid. Everything else stays a renamed-type violation.
#
# RCTPlatformView is *not* policed as a pointer type: it is an alias for NSView,
# exactly as in react-native-macos, so `RCTPlatformView *` is the same type as
# `UIView *`. React/Base/RCTUIKit.h is exempt entirely -- it exists to hand
# those names to third-party code.

RENAME_SCOPE=("${OURS[@]}" ':(exclude)packages/react-native/React/Base/RCTUIKit.h')

# `RCTUIView<RCTComponentViewProtocol> *` is allowed: react-native-macos uses
# exactly that type for the component-view registry and descriptor, and
# third-party Fabric modules are compiled against it. A bare `RCTUIView *` is
# still a violation.
as_pointer=$(git diff "$UPSTREAM_REF"..HEAD -- . "${RENAME_SCOPE[@]}" \
  | grep -E '^\+' | grep -E '\bRCTUIView[[:space:]]*\*' \
  | grep -vE '\bRCTUIView<RCTComponentViewProtocol>[[:space:]]*\*' || true)

# RCTUIColor, RCTPlatformColor and RCTPlatformImage are no longer violations in
# a *header*: an installed header must not name a UIKit type, or the aliases
# leak into every dependent and collide with anything else declaring them. The
# vocabulary is the fix, not the problem. See macos/PLAN-drop-uikit-aliases.md.
#
# Implementation files still may not introduce them: `.m` and `.mm` keep the
# shim and keep writing UIKit names, which is what keeps the fork small.
other_renames=$(git diff "$UPSTREAM_REF"..HEAD -- . "${RENAME_SCOPE[@]}" ':(exclude)*.h' \
  | grep -E '^\+' | grep -E '\bRCT(UIColor|PlatformColor|PlatformImage|UIScrollView)\b' || true)

if [ -z "$as_pointer" ] && [ -z "$other_renames" ]; then
  pass "renamed UIKit types confined to declaration sites"
else
  if [ -n "$as_pointer" ]; then
    bad "RCTUIView used as a pointer type in upstream code:"
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

# .github/workflows/macos-*.yml is excluded: a marker there is the only thing
# that says the file is the fork's and not upstream's, since it cannot live
# under macos/.
ours_marked=$(git grep -l -E '\[macOS|macOS\]' -- macos/ 2>/dev/null \
  | grep -v '^macos/ci/check-budget.sh$' \
  | grep -v '^macos/UIKitCompat/README.md$' || true)

if [ -z "$ours_marked" ]; then
  pass "no [macOS] markers inside macos/"
else
  bad "[macOS] markers found inside macos/, where everything is already ours:"
  echo "$ours_marked" | sed 's/^/    /'
fi

# --- 8. no header a third party can see declares a UIKit name -----------------
#
# The invariant the whole alias migration buys, and the one that decides
# whether adopting this fork breaks somebody else's library. Only the private
# shim -- macos/UIKitCompat/UIKit/, which no other pod gets on its search path
# -- may declare `UIView` and the rest. See macos/PLAN-drop-uikit-aliases.md.

leaking=$(git ls-files -- '*.h' \
  ':(exclude)macos/UIKitCompat/UIKit/*' \
  ':(exclude)macos/tests/*' \
  | python3 -c '
import re, sys

DECL = re.compile(
    r"@compatibility_alias\s+(UI[A-Z]\w*)"
    # A real class declaration names a superclass; `@interface UIView (X)`
    # is a category on it, which declares nothing.
    r"|@interface\s+(UI[A-Z]\w*)\s*:"
    r"|@protocol\s+(UI[A-Z]\w*)\s*[<{]"
    r"|typedef[^;{]*\b(UI[A-Z]\w*)\s*;"
    r"|NS_(?:ENUM|OPTIONS)\s*\([^,]+,\s*(UI[A-Z]\w*)\s*\)")

for path in sys.stdin.read().split():
    try:
        text = open(path, errors="replace").read()
    except OSError:
        continue
    # A UIKit name is fine on the iOS side of a platform split: there it is
    # UIKit that owns it, and UIKit is real.
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//[^\n]*", "", text)
    names = sorted({g for m in DECL.finditer(text) for g in m.groups() if g})
    if names:
        print(path + ": " + ", ".join(names))
')

if [ -z "$leaking" ]; then
  pass "no header outside the private shim declares a UIKit name"
else
  bad "headers declaring a UIKit name outside the private shim:"
  echo "$leaking" | sed 's/^/    /'
  note "Use the RCTPlatform* vocabulary from RCTPlatformTypes.h instead."
fi

echo
if [ "$fail" -eq 0 ]; then
  printf '\033[32mBudget OK\033[0m\n'
else
  printf '\033[31mBudget exceeded\033[0m\n'
fi

echo
echo "Report this in the PR description:"
echo "  Upstream files modified: $files_touched / $MAX_UPSTREAM_FILES_MODIFIED
  Files added by the fork: $files_added
  Platform-gate one-liners: $files_gated"
echo "  Upstream lines removed:  $lines_removed / $MAX_UPSTREAM_LINES_REMOVED"
echo "  Commits:                 $commits / $MAX_COMMITS"

exit $fail
