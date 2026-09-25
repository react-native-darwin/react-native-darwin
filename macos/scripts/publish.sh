#!/usr/bin/env bash
#
# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
# Publish this fork to npm without renaming anything in the repository.
#
# The fork changes exactly one package -- packages/react-native. Every one of
# its dependencies is an upstream @react-native/* package at an exact version,
# and none of them is forked. So publishing means rewriting one `name` field.
#
# Renaming in the repository instead would be worse in both directions: the
# diff against the upstream tag would grow for no functional reason, and every
# rebase onto a new tag would conflict on it. This script does the rename at
# publish time and puts the tree back afterwards.
#
# Two things have to happen beyond the rename:
#
#   1. macos/UIKitCompat and macos/metro-config.js are vendored into the
#      package. They live at the repo root, and npm cannot pack a path outside
#      the package directory.
#      React-UIKitCompat.podspec and scripts/cocoapods/helpers.rb both accept
#      either layout, so nothing needs patching once it is copied.
#
#   2. "macos" is added to the `files` allowlist, or the vendored copy is
#      packed into nothing.
#
# The published package is consumed under the *upstream* name:
#
#   "dependencies": { "react-native": "npm:react-native-darwin@0.87.1" }
#
# npm installs the tarball at node_modules/react-native. That matters because
# @react-native/metro-config hardcodes require.resolve("react-native/setup-env")
# and assetRegistryPath "react-native/asset-registry", and
# @react-native/assets-registry imports from 'react-native'. Those are upstream
# packages this fork does not own, so the install path is what has to match, not
# the published name.

set -euo pipefail

PKG_NAME="react-native-darwin"
DIST_TAG="latest"
PKG_VERSION=""      # defaults to the version in package.json
MODE="pack"

usage() {
  cat >&2 <<'USAGE'
usage: macos/scripts/publish.sh [--name <pkg>] [--version <v>] [--tag <dist-tag>] [--publish]

  --name <pkg>      npm package name to publish under (default: react-native-darwin)
  --version <v>     version to publish as. Defaults to the version in
                    package.json, which tracks the upstream tag. Override it for
                    prereleases -- e.g. 0.87.1-rc.1 -- rather than editing the
                    upstream file, which the fork keeps at upstream's value.
  --tag <dist-tag>  npm dist-tag (default: latest). A prerelease belongs on
                    `next`, not `latest`: npm tags whatever you publish as
                    `latest` unless told otherwise, prerelease or not.
  --publish         actually publish. Without it the script builds the tarball,
                    verifies it, and stops -- publishing is irreversible.

The repository is never left modified: package.json is restored and the
vendored macos/ copy is removed, on success or failure.
USAGE
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --name)    PKG_NAME="${2:-}"; [ -n "$PKG_NAME" ] || usage; shift 2 ;;
    --version) PKG_VERSION="${2:-}"; [ -n "$PKG_VERSION" ] || usage; shift 2 ;;
    --tag)     DIST_TAG="${2:-}"; [ -n "$DIST_TAG" ] || usage; shift 2 ;;
    --publish) MODE="publish"; shift ;;
    -h|--help) usage ;;
    *)         echo "unknown argument: $1" >&2; usage ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pkg_dir="$repo_root/packages/react-native"
pkg_json="$pkg_dir/package.json"
compat_src="$repo_root/macos/UIKitCompat"
compat_dst="$pkg_dir/macos/UIKitCompat"
metro_src="$repo_root/macos/metro-config.js"

[ -f "$pkg_json" ]     || { echo "error: $pkg_json not found" >&2; exit 1; }
[ -d "$compat_src" ]   || { echo "error: $compat_src not found" >&2; exit 1; }
[ -f "$metro_src" ]    || { echo "error: $metro_src not found" >&2; exit 1; }

# Refuse to run on a dirty package.json. The restore below overwrites it, and
# overwriting an edit the user has not committed would lose work silently.
if ! git -C "$repo_root" diff --quiet -- "$pkg_json"; then
  echo "error: packages/react-native/package.json has uncommitted changes." >&2
  echo "       Commit or stash them first; this script rewrites that file." >&2
  exit 1
fi

# The upstream prepack script overwrites packages/react-native/README.md from
# the repo root, so that has to be restored as well.
pkg_readme="$pkg_dir/README.md"

# `mktemp -d -t <name>` is not portable: BSD mktemp treats the argument as a
# prefix and appends randomness, GNU coreutils treats it as a template and
# rejects it unless it ends in at least three X's. The publishing job runs on
# Linux and the developer runs macOS, so both have to work -- use the explicit
# template form, which is the same on both.
backup_dir="$(mktemp -d "${TMPDIR:-/tmp}/rn-macos-publish.XXXXXX")"
cp "$pkg_json" "$backup_dir/package.json"
[ -f "$pkg_readme" ] && cp "$pkg_readme" "$backup_dir/README.md"

cleanup() {
  cp "$backup_dir/package.json" "$pkg_json"
  [ -f "$backup_dir/README.md" ] && cp "$backup_dir/README.md" "$pkg_readme"
  rm -rf "$backup_dir"
  rm -rf "$pkg_dir/macos"

  # The upstream prepack does more than build: it removes tracked files at the
  # repo root -- scripts/build/ among them -- and never puts them back. Packing
  # should not be able to damage the checkout, so any tracked file that is now
  # missing is restored. Only deletions, so nothing edited is touched.
  local deleted
  deleted="$(cd "$repo_root" && git ls-files --deleted)"
  if [ -n "$deleted" ]; then
    echo "==> restoring tracked files removed by prepack:"
    printf '%s\n' "$deleted" | sed 's/^/      /'
    (cd "$repo_root" && printf '%s\n' "$deleted" | xargs -I{} git checkout -- {})
  fi
}
trap cleanup EXIT

version="${PKG_VERSION:-$(node -p "require('$pkg_json').version")}"

echo "==> publishing $PKG_NAME@$version (dist-tag: $DIST_TAG, mode: $MODE)"

# --- 1. vendor the compatibility layer ---------------------------------------

echo "==> vendoring macos/ into the package"
mkdir -p "$pkg_dir/macos"
cp -R "$compat_src" "$compat_dst"
cp "$metro_src" "$pkg_dir/macos/metro-config.js"
# The scaffolder and the files it writes. init.js locates the package from its
# own path, so it must ship at macos/scripts/init.js -- the same place it sits
# in the repo, one level under the package root.
mkdir -p "$pkg_dir/macos/scripts"
cp "$repo_root/macos/scripts/init.js" "$pkg_dir/macos/scripts/init.js"
cp -R "$repo_root/macos/template" "$pkg_dir/macos/template"

# --- 2. rewrite the package metadata -----------------------------------------

echo "==> rewriting name, files and repository"
PKG_NAME="$PKG_NAME" PKG_VERSION="$PKG_VERSION" node - "$pkg_json" <<'NODE'
const fs = require('fs');
const path = process.argv[2];
const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));

pkg.name = process.env.PKG_NAME;
if (process.env.PKG_VERSION) {
  pkg.version = process.env.PKG_VERSION;
}

// `files` is an allowlist. The vendored directory is invisible without it.
if (!pkg.files.includes('macos')) {
  pkg.files.push('macos');
  pkg.files.sort();
}

// `exports` is a gate, not just documentation: a subpath absent from it is
// unreachable even though it is in the tarball. The compat layer is reached by
// CocoaPods through the filesystem, so only the JS helper needs an entry.
pkg.exports['./macos/metro-config'] = './macos/metro-config.js';
pkg.exports['./macos/*'] = './macos/*';

// The scaffolder, as `npx react-native-darwin-init` from an app that has this
// package installed. Merged rather than assigned: upstream already ships bins.
pkg.bin = {...(pkg.bin ?? {}), 'react-native-darwin-init': './macos/scripts/init.js'};

pkg.repository = {
  type: 'git',
  url: 'git+https://github.com/react-native-darwin/react-native-darwin.git',
  directory: 'packages/react-native',
};

// `bin` stays keyed on `react-native`. The package is installed under that
// name via an npm alias, so the CLI keeps the name every RN script expects.

fs.writeFileSync(path, JSON.stringify(pkg, null, 2) + '\n');
NODE

# --- 3. build the tarball -----------------------------------------------------
#
# `npm pack` runs the upstream prepack script, which generates FBReactNativeSpec
# and copies the README. Pack first even when publishing, so the contents can be
# checked before anything leaves the machine.

# The prepack script generates FBReactNativeSpec, and its codegen needs the
# package's own dependencies on disk. A fresh clone does not have them, and
# neither obvious way of getting them is right:
#
#   - `yarn install` at the repo root is this monorepo's real bootstrap, but it
#     hoists into the root node_modules and pulls the whole dev tree.
#   - `npm install` inside the package makes npm walk up, find the workspace
#     root, and fail on an unrelated devDependency peer conflict.
#
# So: install exactly the package's declared dependencies into a scratch
# directory that has no workspace above it, and put that on NODE_PATH. prepack
# resolves from there and nothing in the repository is touched.
if ! node -e 'require.resolve("tinyglobby", {paths: [process.argv[1]]})' "$pkg_dir" >/dev/null 2>&1; then
  echo "==> staging package dependencies for prepack"
  deps_dir="$backup_dir/deps"
  mkdir -p "$deps_dir"
  node - "$pkg_json" "$deps_dir/package.json" <<'NODE'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
fs.writeFileSync(
  process.argv[3],
  JSON.stringify(
    {name: 'prepack-deps', version: '1.0.0', private: true, dependencies: pkg.dependencies},
    null,
    2,
  ),
);
NODE
  (cd "$deps_dir" && npm install --no-audit --no-fund --silent)
  export NODE_PATH="$deps_dir/node_modules${NODE_PATH:+:$NODE_PATH}"
fi

echo "==> npm pack"
# `npm pack --silent` still lets the prepack script write to stdout, so the
# filename is the last line, not the whole capture.
tarball="$(cd "$pkg_dir" && npm pack --silent | grep -E '\.tgz$' | tail -n 1)"
[ -n "$tarball" ] || { echo "error: npm pack produced no tarball" >&2; exit 1; }
tarball_path="$pkg_dir/$tarball"

# --- 4. verify the tarball ----------------------------------------------------

echo "==> verifying tarball contents"
listing="$(tar -tzf "$tarball_path")"

# A here-string, not a pipe: `grep -q` exits at the first match, which under
# `set -o pipefail` turns the writer's SIGPIPE into a failed check.
check() {
  if grep -qxF "package/$1" <<<"$listing"; then
    printf '  ok      %s\n' "$1"
  else
    printf '  MISSING %s\n' "$1" >&2
    return 1
  fi
}

missing=0
check "macos/metro-config.js"                  || missing=1
check "macos/scripts/init.js"                  || missing=1
check "macos/template/Podfile"                 || missing=1
check "macos/template/app/AppDelegate.mm"      || missing=1
check "macos/UIKitCompat/macos-excludes.txt"   || missing=1
check "macos/UIKitCompat/RCTPlatformViewCompat.h" || missing=1
check "macos/UIKitCompat/React-UIKitCompat.podspec" || missing=1
check "macos/UIKitCompat/UIKit/UIKit.h"        || missing=1
check "macos/UIKitCompat/UIKit/UIView.m"       || missing=1
check "scripts/cocoapods/helpers.rb"           || missing=1
check "React-Core.podspec"                     || missing=1

if [ "$missing" -ne 0 ]; then
  echo "error: tarball is incomplete; not publishing." >&2
  rm -f "$tarball_path"
  exit 1
fi

# helpers.rb resolves the exclusion list relative to its own directory. Prove
# the package-relative branch works inside the tarball, not just in the repo --
# that is the single thing most likely to be wrong about a published build.
staging="$(mktemp -d "${TMPDIR:-/tmp}/rn-macos-verify.XXXXXX")"
tar -xzf "$tarball_path" -C "$staging"
if ruby -e '
  require File.join(ARGV[0], "package", "scripts", "cocoapods", "helpers.rb")
  files = Helpers::Constants.macos_excluded_files
  abort "macos_excluded_files resolved to nothing" if files.nil? || files.empty?
  puts "  ok      helpers.rb resolves the exclusion list (#{files.length} patterns)"
' "$staging"; then
  :
else
  echo "error: helpers.rb cannot find macos-excludes.txt inside the tarball." >&2
  rm -rf "$staging"; rm -f "$tarball_path"
  exit 1
fi
rm -rf "$staging"

size="$(du -h "$tarball_path" | cut -f1)"
echo "==> $tarball ($size)"

# --- 5. publish ---------------------------------------------------------------

if [ "$MODE" != "publish" ]; then
  echo
  echo "Dry run. Tarball left at:"
  echo "  $tarball_path"
  echo
  echo "Re-run with --publish to push it to npm."
  exit 0
fi

echo "==> npm publish --tag $DIST_TAG"
(cd "$pkg_dir" && npm publish "$tarball" --tag "$DIST_TAG")
rm -f "$tarball_path"

cat <<EOF

Published $PKG_NAME@$version

Consume it under the upstream name, so every hardcoded
"react-native/..." path in the toolchain keeps resolving:

  "dependencies": {
    "react-native": "npm:$PKG_NAME@$version"
  }

Podfile:

  require_relative '../node_modules/react-native/scripts/react_native_pods'
  platform :osx, min_macos_version_supported
  use_react_native!(:path => '../node_modules/react-native')
  pod 'React-UIKitCompat', :path => '../node_modules/react-native/macos/UIKitCompat'

metro.config.js:

  const {getDefaultConfig, mergeConfig} = require('@react-native/metro-config');
  const {getMacOSConfig} = require('react-native/macos/metro-config');

  module.exports = mergeConfig(getDefaultConfig(__dirname), getMacOSConfig());

See macos/HelloWorld/Podfile for the post_install hook, which is required: it
force-includes RCTPlatformViewCompat.h and strips the UIKit and
MobileCoreServices link flags.
EOF
