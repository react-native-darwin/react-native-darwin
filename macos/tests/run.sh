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

echo "==> Checking for recursive category methods"
python3 macos/tests/check-no-self-recursion.py

echo "==> Building"
clang -fobjc-arc -fmodules -Wall -Werror \
  -mmacosx-version-min=11.0 \
  -I macos/UIKitCompat \
  -framework AppKit -framework Foundation -framework QuartzCore \
  -o "$OUT" \
  macos/tests/UIKitCompatTest.m macos/UIKitCompat/UIKit/*.m

echo "==> Running"
"$OUT"
