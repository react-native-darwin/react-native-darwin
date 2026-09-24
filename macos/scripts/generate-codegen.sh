#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
# Generates React Native's codegen output so the syntax checker can see the
# whole tree.
#
# FBReactNativeSpec and the generated Fabric component descriptors do not exist
# in the repository -- `pod install` produces them. Without them roughly 90
# sources fail on a missing header and cannot be judged at all, which is the
# difference between measuring React Native and measuring a third of it.
#
# A full monorepo `yarn install` is not needed. The codegen package has seven
# runtime dependencies, and Meta publishes it prebuilt, so this installs the
# published build into a scratch prefix and points the in-repo package at it.
#
# Output goes to packages/react-native/React/FBReactNativeSpec, which upstream
# already gitignores.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
REPO="$(pwd)"
RN="$REPO/packages/react-native"

RN_VERSION="$(node -p "require('$RN/package.json').version")"
DEPS="${TMPDIR:-/tmp}/rn-macos-codegen-deps"

if [ ! -d "$DEPS/node_modules/@react-native/codegen/lib" ]; then
  echo "==> Installing codegen dependencies for $RN_VERSION"
  mkdir -p "$DEPS"
  printf '{"name":"rn-macos-codegen-deps","private":true}\n' > "$DEPS/package.json"
  ( cd "$DEPS" && npm install --no-audit --no-fund --loglevel=error \
      "@react-native/codegen@$RN_VERSION" \
      @babel/core @babel/parser hermes-parser invariant nullthrows tinyglobby glob chalk \
      'yargs@^17' )
  # yargs 18 dropped the CommonJS singleton that React Native's codegen CLI
  # calls (`yargs.option(...)`), so the major version is pinned.
fi

# buildCodegenIfNeeded() is satisfied by the presence of lib/, so point the
# in-repo package at the published build rather than compiling it here.
ln -sfn "$DEPS/node_modules/@react-native/codegen/lib" "$REPO/packages/react-native-codegen/lib"
ln -sfn "$DEPS/node_modules" "$REPO/packages/react-native-codegen/node_modules"

mkdir -p "$REPO/node_modules"
for dep in "$DEPS"/node_modules/*; do
  ln -sfn "$dep" "$REPO/node_modules/$(basename "$dep")"
done

echo "==> Generating FBReactNativeSpec"
NODE_PATH="$DEPS/node_modules" node -e "
  const path = require('path');
  const RN = '$RN';
  const {generateFBReactNativeSpecIOS} = require(
    path.join(RN, 'scripts/codegen/generate-artifacts-executor/generateFBReactNativeSpecIOS'));
  generateFBReactNativeSpecIOS(RN);
"

echo "==> Generated $(find "$RN/React/FBReactNativeSpec" -name '*.h' | wc -l | tr -d ' ') headers"
