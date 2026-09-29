#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
# Compiles and runs the UIKit compatibility layer checks.
#
# The test file imports <UIKit/UIKit.h> exactly as upstream React Native does.
# If it builds, upstream source of the same shape builds.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

OUT="$(mktemp -d)/uikitcompat_test"

echo "==> Verifying the macOS SDK really has no UIKit.framework"
SDK="$(xcrun --show-sdk-path --sdk macosx)"
if [ -d "$SDK/System/Library/Frameworks/UIKit.framework" ]; then
  echo "error: UIKit.framework exists in the macOS SDK at $SDK." >&2
  echo "       The whole approach assumes these names are free. Stop and reassess." >&2
  exit 1
fi
echo "    ok: no UIKit.framework in $SDK"

echo "==> Checking HelloWorld has not drifted from the app template"
# HelloWorld is the demo *and* the thing that proves the template works. When
# they drift the demo stops exercising what we ship: it sat 101 lines behind
# once, which is how it kept its own broken module lookup long after the
# template was fixed.
for f in AppDelegate.h AppDelegate.mm main.m Info.plist; do
  if ! diff -q \
      <(sed 's/__APP_NAME__/HelloWorld/g; s/__BUNDLE_ID__/dev.reactnative.macos.helloworld/g' "macos/template/app/$f") \
      "macos/HelloWorld/HelloWorld/$f" >/dev/null; then
    echo "error: macos/HelloWorld/HelloWorld/$f differs from the template." >&2
    echo "       Regenerate it from macos/template/app/$f." >&2
    exit 1
  fi
done
echo "    ok: HelloWorld matches the template"

echo "==> Building the input probe"
# Compiled, not run: driving a window needs a live app, which this suite does
# not start. Building it keeps the tool from rotting -- it is how every macOS
# defect in this fork was actually found, and it was rewritten from memory in
# /tmp several times before it was committed.
clang -framework Foundation -framework CoreGraphics -Wall -Werror \
  -mmacosx-version-min=14.0 \
  -o "$(dirname "$OUT")/uiprobe" macos/tests/uiprobe/uiprobe.m
echo "    ok: macos/tests/uiprobe/uiprobe.m compiles"

echo "==> Checking for recursive category methods"
python3 macos/tests/check-no-self-recursion.py

echo "==> Building"
clang -fobjc-arc -fmodules -Wall -Werror \
  -mmacosx-version-min=14.0 \
  -I macos/UIKitCompat \
  -I macos/UIKitCompat/Public \
  -framework AppKit -framework Foundation -framework QuartzCore \
  -o "$OUT" \
  macos/tests/UIKitCompatTest.m macos/UIKitCompat/UIKit/*.m

echo "==> Running"
"$OUT"

# The acceptance test for the alias migration: a third-party pod that declares
# the UIKit names itself must still compile against React Native's installed
# headers. It needs a pod install to have happened, so it is skipped when there
# is none rather than failing a fresh checkout.
PODS="macos/HelloWorld/Pods/Headers/Public"
if [ -d "$PODS" ]; then
  echo "==> Checking a third-party pod that declares UIKit names itself"
  includes=""
  for dir in "$PODS"/*/; do
    includes="$includes -I $dir"
  done
  if clang -fsyntax-only -fobjc-arc -x objective-c++ -std=c++20 -Werror \
      -mmacosx-version-min=14.0 \
      -I "$PODS" $includes \
      -I macos/UIKitCompat/Public \
      macos/tests/third-party/ThirdPartyPodProbe.mm; then
    echo "    ok: it compiles -- the aliases no longer escape"
  else
    echo "error: a pod declaring its own UIKit names cannot compile against" >&2
    echo "       this fork. The shim is leaking again; see" >&2
    echo "       macos/PLAN-drop-uikit-aliases.md." >&2
    exit 1
  fi
else
  echo "==> Skipping the third-party pod check (no Pods installed)"
fi
