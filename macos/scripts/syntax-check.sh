#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
# The Phase 3 inner loop: compile every upstream Objective-C source against the
# macOS SDK with the UIKit compatibility layer on the include path, and report
# what still fails.
#
# This is -fsyntax-only, not a link. It exists to answer one question quickly --
# "how much of React Native still does not parse for macOS, and why" -- without
# standing up CocoaPods, codegen and Hermes first. A real build is Phase 3's
# exit test; this is what you run fifty times a day before you get there.
#
# Third-party headers come from the ReactNativeDependenciesHeaders xcframework
# that upstream already publishes with a macos-arm64_x86_64 slice, so folly,
# boost, glog, fmt and double-conversion are real macOS headers, not guesses.
#
# Usage: macos/scripts/syntax-check.sh [--verbose] [path-filter]

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
REPO="$(pwd)"
RN="$REPO/packages/react-native"

VERBOSE=0
FILTER=""
for arg in "$@"; do
  case "$arg" in
    --verbose) VERBOSE=1 ;;
    *) FILTER="$arg" ;;
  esac
done

RN_VERSION="$(node -p "require('$RN/package.json').version" 2>/dev/null || echo "0.87.1")"
CACHE="${TMPDIR:-/tmp}/rn-macos-syntax-check"
DEPS_ROOT="$CACHE/deps-$RN_VERSION"
DEPS="$DEPS_ROOT/packages/react-native/third-party/ReactNativeDependenciesHeaders.xcframework/macos-arm64_x86_64/Headers"
INC="$CACHE/include"

# --- hermes headers -------------------------------------------------------------

HERMES_TARBALL_DIR="$CACHE/hermes"
HERMES_INCLUDE="$HERMES_TARBALL_DIR/destroot/include"
if [ ! -d "$HERMES_INCLUDE" ]; then
  HERMES_VERSION="$(cat "$RN/sdks/.hermesv1version" 2>/dev/null | sed 's/^hermes-v//')"
  if [ -n "$HERMES_VERSION" ]; then
    echo "==> Fetching Hermes headers ($HERMES_VERSION)"
    mkdir -p "$HERMES_TARBALL_DIR"
    HURL="https://repo1.maven.org/maven2/com/facebook/hermes/hermes-ios/${HERMES_VERSION}/hermes-ios-${HERMES_VERSION}-hermes-ios-debug.tar.gz"
    if curl -fsSL "$HURL" -o "$CACHE/hermes.tgz"; then
      tar xzf "$CACHE/hermes.tgz" -C "$HERMES_TARBALL_DIR" './destroot/include' 2>/dev/null || true
    else
      echo "    could not fetch Hermes headers; a few sources will report a missing header" >&2
    fi
  fi
fi

# --- codegen output ------------------------------------------------------------
#
# FBReactNativeSpec and the generated component descriptors only exist after
# codegen has run. Without them ~90 sources cannot be judged at all, which is
# the difference between measuring React Native and measuring a third of it.

if [ ! -d "$RN/React/FBReactNativeSpec" ]; then
  echo "==> Codegen output missing. Run macos/scripts/generate-codegen.sh first." >&2
  echo "    Continuing without it; ~90 sources will report a missing header." >&2
fi

# --- third-party headers ------------------------------------------------------

if [ ! -d "$DEPS" ]; then
  echo "==> Fetching macOS third-party headers for $RN_VERSION"
  mkdir -p "$DEPS_ROOT"
  URL="https://repo1.maven.org/maven2/com/facebook/react/react-native-artifacts/${RN_VERSION}/react-native-artifacts-${RN_VERSION}-reactnative-dependencies-headers-debug.tar.gz"
  if ! curl -fsSL "$URL" -o "$CACHE/headers.tgz"; then
    echo "error: could not download $URL" >&2
    exit 2
  fi
  tar xzf "$CACHE/headers.tgz" -C "$DEPS_ROOT" \
    'packages/react-native/third-party/ReactNativeDependenciesHeaders.xcframework/macos-arm64_x86_64/*'
fi
[ -d "$DEPS" ] || { echo "error: no macOS header slice at $DEPS" >&2; exit 2; }

# --- flat header trees --------------------------------------------------------
#
# React Native imports its own headers as <React/RCTFoo.h> no matter where the
# file actually lives, so CocoaPods flattens them into one directory. Same here.

echo "==> Building header tree"
rm -rf "$INC"
mkdir -p "$INC/React"
( cd "$RN" && find React Libraries -name '*.h' ! -path '*__tests__*' -print0 ) \
  | while IFS= read -r -d '' h; do ln -sf "$RN/$h" "$INC/React/"; done

link_module() {
  local name="$1"; shift
  mkdir -p "$INC/$name"
  for d in "$@"; do
    [ -d "$RN/$d" ] || continue
    find "$RN/$d" -maxdepth 1 -name '*.h' -exec ln -sf {} "$INC/$name/" \; 2>/dev/null
  done
}

link_module FBReactNativeSpec React/FBReactNativeSpec React/FBReactNativeSpec/FBReactNativeSpec
link_module RCTTypeSafety Libraries/TypeSafety
link_module RCTRequired Libraries/Required
link_module FBLazyVector Libraries/FBLazyVector/FBLazyVector
link_module RCTDeprecation ReactApple/Libraries/RCTFoundation/RCTDeprecation/Exported
link_module cxxreact ReactCommon/cxxreact
link_module jsireact ReactCommon/jsiexecutor/jsireact
link_module reacthermes ReactCommon/hermes/executor
link_module ReactCommon \
  ReactCommon/react/nativemodule/core/ReactCommon \
  ReactCommon/react/runtime \
  ReactCommon/react/runtime/platform/ios/ReactCommon \
  ReactCommon/react/nativemodule/core/platform/ios/ReactCommon \
  ReactCommon/runtimeexecutor/ReactCommon \
  ReactCommon/callinvoker/ReactCommon

# --- include path -------------------------------------------------------------

INCLUDES=(
  -I "$INC"
  # Quoted includes such as #import "RCTAssert.h" resolve relative to the
  # including file first, then the search path. CocoaPods flattens all public
  # headers into one directory, so the flat tree has to be searchable directly
  # as well as under React/.
  -I "$INC/React"
  -I "$REPO/macos/UIKitCompat"
  -I "$RN"
  -I "$RN/ReactCommon"
  -I "$RN/ReactCommon/jsi"
  -I "$RN/ReactCommon/yoga"
  -I "$RN/ReactCommon/react/renderer/components/view/platform/cxx"
  -I "$RN/ReactCommon/react/renderer/graphics/platform/ios"
  -I "$RN/ReactCommon/react/renderer/imagemanager/platform/ios"
  -I "$RN/ReactCommon/react/renderer/textlayoutmanager/platform/ios"
  -I "$RN/ReactCommon/react/runtime/platform/ios"
  -I "$RN/ReactCommon/runtimeexecutor"
  -I "$RN/ReactCommon/callinvoker"
  -I "$RN/ReactCommon/react/renderer/components/textinput/platform/ios"
  -I "$RN/ReactCommon/react/renderer/components/legacyviewmanagerinterop"
  -I "$RN/React/Fabric"
  -I "$RN/React/Fabric/Mounting/ComponentViews"
  -I "$RN/ReactCommon/jsitooling"
  -I "$RN/ReactCommon/react/utils/platform/ios"
  -I "$RN/ReactCommon/runtimeexecutor/platform/ios"
  -I "$RN/ReactCommon/react/renderer/components/legacyviewmanagerinterop/platform/ios"
  -I "$RN/ReactCommon/react/renderer/components/switch/iosswitch"
  -I "$RN/ReactCommon/react/renderer/components/text/platform/cxx"
  -I "$RN/ReactCommon/react/renderer/components/scrollview/platform/ios"
  -I "$RN/ReactCommon/react/renderer/components/scrollview/platform/cxx"
  -I "$RN/ReactApple"
  # Hermes public headers, from the same prebuilt tarball the pod consumes.
  -I "$HERMES_INCLUDE"
  # Codegen output, produced by macos/scripts/generate-codegen.sh.
  -I "$RN/React/FBReactNativeSpec"
  -I "$DEPS"
)

COMMON=(
  -fsyntax-only -fobjc-arc -fmodules -target arm64-apple-macos11.0
  # Force-include the compatibility prelude, exactly as the pod will. It puts
  # the UIKit layer in scope in every translation unit and defines
  # RCTPlatformView on every platform. See the header for why.
  -include "$REPO/macos/UIKitCompat/RCTPlatformViewCompat.h"
  -DTARGET_OS_OSX=1 -DFOLLY_NO_CONFIG=0 -DFOLLY_HAVE_CLOCK_GETTIME=1
  # folly enables its coroutine headers purely from compiler support, but the
  # published header bundle omits folly/coro entirely. Harness concern only.
  -DFOLLY_HAS_COROUTINES=0 -DFOLLY_CFG_NO_COROUTINES=1
  -Wno-everything
)

# --- run ----------------------------------------------------------------------

SOURCES="$CACHE/sources.txt"
( cd "$RN" && find React Libraries ReactApple \( -name '*.m' -o -name '*.mm' \) \
    ! -path '*__tests__*' ! -path '*Tests*' | sort ) > "$SOURCES.all"

# Drop what the macOS build excludes, from the same list the podspec reads.
EXCLUDES="$REPO/macos/UIKitCompat/macos-excludes.txt"
cp "$SOURCES.all" "$SOURCES"
if [ -f "$EXCLUDES" ]; then
  while IFS= read -r prefix; do
    case "$prefix" in ''|'#'*) continue ;; esac
    grep -v "^$prefix" "$SOURCES" > "$SOURCES.keep" && mv "$SOURCES.keep" "$SOURCES"
  done < "$EXCLUDES"
  echo "==> Excluded $(($(wc -l < "$SOURCES.all") - $(wc -l < "$SOURCES"))) sources the macOS build does not ship"
fi
if [ -n "$FILTER" ]; then
  grep -- "$FILTER" "$SOURCES" > "$SOURCES.tmp" && mv "$SOURCES.tmp" "$SOURCES"
fi

TOTAL=$(wc -l < "$SOURCES" | tr -d ' ')
echo "==> Syntax-checking $TOTAL sources against the macOS SDK"

LOG="$CACHE/errors.txt"
: > "$LOG"
ok=0; bad=0; n=0

while IFS= read -r src; do
  n=$((n + 1))
  if [ -t 1 ]; then printf '\r    %d/%d  ok=%d fail=%d ' "$n" "$TOTAL" "$ok" "$bad"; fi
  case "$src" in
    *.mm) lang=(-x objective-c++ -std=gnu++20) ;;
    *)    lang=(-x objective-c -std=gnu11) ;;
  esac
  if out=$( cd "$RN" && clang "${COMMON[@]}" "${lang[@]}" "${INCLUDES[@]}" "$src" 2>&1 ); then
    ok=$((ok + 1))
  else
    bad=$((bad + 1))
    { echo "=== $src"; echo "$out"; } >> "$LOG"
    [ "$VERBOSE" -eq 1 ] && { echo; echo "--- $src"; echo "$out" | grep 'error:' | head -5; }
  fi
done < "$SOURCES"
if [ -t 1 ]; then printf '\r%*s\r' 60 ''; fi

echo "    parsed cleanly: $ok / $TOTAL"
echo "    failed:         $bad / $TOTAL"
echo
echo "==> Why the failures happen"

# A missing codegen header is this harness's limitation, not a macOS problem:
# FBReactNativeSpec and friends only exist after `pod install` runs codegen.
codegen=$(grep -c "fatal error: '\(FBReactNativeSpec\|React_Codegen\|ReactCodegen\|rncore\|RCTModulesConformingToProtocolsProvider\)" "$LOG" 2>/dev/null || echo 0)
uikitgap=$(grep -cE "error: (unknown type name|use of undeclared identifier|no known instance method|property '[^']*' not found|no visible @interface).*'?UI[A-Z]" "$LOG" 2>/dev/null || echo 0)
missinghdr=$(grep -c "fatal error: '" "$LOG" 2>/dev/null || echo 0)

echo "    missing codegen header (harness limitation):  $codegen"
echo "    missing header, other (harness limitation):   $((missinghdr - codegen))"
echo "    unresolved UIKit symbol (shim gap):           $uikitgap"
echo
echo "==> Top unresolved UIKit symbols"
grep -ohE "'UI[A-Za-z0-9_]+'" "$LOG" 2>/dev/null | sort | uniq -c | sort -rn | head -25 | sed 's/^/    /'

echo
echo "Full log: $LOG"
