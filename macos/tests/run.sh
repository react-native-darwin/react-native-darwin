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

echo "==> Checking for recursive category methods"
python3 macos/tests/check-no-self-recursion.py

echo "==> Building"
clang -fobjc-arc -fmodules -Wall -Werror \
  -mmacosx-version-min=14.0 \
  -I macos/UIKitCompat \
  -framework AppKit -framework Foundation -framework QuartzCore \
  -o "$OUT" \
  macos/tests/UIKitCompatTest.m macos/UIKitCompat/UIKit/*.m

echo "==> Running"
"$OUT"
