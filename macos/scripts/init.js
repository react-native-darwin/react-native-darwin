#!/usr/bin/env node
/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * Adds a `macos/` target to an existing React Native app.
 *
 * The equivalent of microsoft/react-native-macos-init, and deliberately the
 * same shape:
 * it writes files and tells you what to run, rather than running the build
 * itself. Everything it writes is readable and meant to be edited afterwards --
 * the Podfile especially, which starts without `use_native_modules!` because
 * most community modules do not build for macOS yet.
 *
 * Paths are computed from this file's own location, so it works whichever name
 * the package is installed under -- `react-native`, `react-native-darwin`, an
 * npm alias, or a path dependency in this repo.
 *
 * @format
 */

'use strict';

const fs = require('fs');
const path = require('path');

const TEMPLATE = path.resolve(__dirname, '..', 'template');
/** The installed package root: <pkg>/macos/scripts/init.js -> <pkg>. */
const PACKAGE_ROOT = path.resolve(__dirname, '..', '..');

function fail(message) {
  console.error(`error: ${message}`);
  process.exit(1);
}

function usage() {
  console.log(`
usage: react-native-darwin-init [--name <AppName>] [--bundle-id <id>] [--force]

  --name        Xcode target and JS module name. Defaults to the "name" in
                package.json, with non-alphanumerics removed.
  --bundle-id   CFBundleIdentifier. Defaults to com.<name-lowercased>.
  --force       Overwrite an existing macos/ directory.
`);
  process.exit(0);
}

function parseArgs(argv) {
  const args = {force: false};
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case '--name':
        args.name = argv[++i];
        break;
      case '--bundle-id':
        args.bundleId = argv[++i];
        break;
      case '--force':
        args.force = true;
        break;
      case '-h':
      case '--help':
        usage();
        break;
      default:
        fail(`unknown argument: ${argv[i]}`);
    }
  }
  return args;
}

/**
 * A path from `fromDir` to `target`, always written with forward slashes and a
 * leading `./` or `../` so it reads as relative in a Podfile or a require.
 */
function relative(fromDir, target) {
  const rel = path.relative(fromDir, target).split(path.sep).join('/');
  return rel.startsWith('.') ? rel : `./${rel}`;
}

function substitute(text, values) {
  return Object.keys(values).reduce(
    (acc, key) => acc.split(key).join(values[key]),
    text,
  );
}

function write(file, contents) {
  fs.mkdirSync(path.dirname(file), {recursive: true});
  fs.writeFileSync(file, contents);
  console.log(`  ${path.relative(process.cwd(), file)}`);
}

function copyTemplate(src, dst, values) {
  write(dst, substitute(fs.readFileSync(src, 'utf8'), values));
}

/**
 * Finds this package inside the app's node_modules, and the name the app refers
 * to it by.
 *
 * Matching on realpath rather than on a name: the package is meant to be
 * installed under an npm alias -- `react-native: npm:react-native-darwin@...`
 * -- so its directory name is whatever the app chose, and that is exactly the
 * string a require or a Podfile path needs.
 *
 * Falls back to this checkout when there is no install to find, which is the
 * case when running from the repository itself.
 */
function locateInstall(appRoot, packageRoot) {
  let real;
  try {
    real = fs.realpathSync(packageRoot);
  } catch {
    return {dir: packageRoot, specifier: path.basename(packageRoot)};
  }

  for (let dir = appRoot; ; dir = path.dirname(dir)) {
    const modules = path.join(dir, 'node_modules');
    if (fs.existsSync(modules)) {
      for (const entry of fs.readdirSync(modules)) {
        const names = entry.startsWith('@')
          ? fs
              .readdirSync(path.join(modules, entry))
              .map(inner => `${entry}/${inner}`)
          : [entry];
        for (const name of names) {
          const candidate = path.join(modules, name);
          try {
            if (fs.realpathSync(candidate) === real) {
              return {dir: candidate, specifier: name};
            }
          } catch {
            // Broken link; keep looking.
          }
        }
      }
    }
    if (path.dirname(dir) === dir) {
      break;
    }
  }
  return {dir: packageRoot, specifier: path.basename(packageRoot)};
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const appRoot = process.cwd();

  const packageJsonPath = path.join(appRoot, 'package.json');
  if (!fs.existsSync(packageJsonPath)) {
    fail(`no package.json in ${appRoot}. Run this from your app's root.`);
  }
  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));

  const appName =
    args.name ?? String(packageJson.name ?? 'App').replace(/[^A-Za-z0-9]/g, '');
  if (!/^[A-Za-z][A-Za-z0-9]*$/.test(appName)) {
    fail(
      `"${appName}" is not usable as an Xcode target name. Pass --name explicitly.`,
    );
  }
  const bundleId = args.bundleId ?? `com.${appName.toLowerCase()}`;

  const macosDir = path.join(appRoot, 'macos');
  if (fs.existsSync(macosDir) && !args.force) {
    fail(`${macosDir} already exists. Pass --force to overwrite it.`);
  }

  // Where this package sits *as the app sees it*, which is not where this file
  // sits: Node resolves symlinks in __dirname, so a pnpm store or an npm alias
  // both report a path outside node_modules. Written into a Podfile that path
  // is wrong for anyone else, so find the install by matching real paths.
  const install = locateInstall(appRoot, PACKAGE_ROOT);
  const packageName = install.specifier;

  const values = {
    __APP_NAME__: appName,
    __BUNDLE_ID__: bundleId,
    __RN_PATH__: relative(macosDir, install.dir),
    __RN_PODS__: relative(
      macosDir,
      path.join(install.dir, 'scripts', 'react_native_pods'),
    ),
    __UIKIT_COMPAT__: relative(
      macosDir,
      path.join(install.dir, 'macos', 'UIKitCompat'),
    ),
    __RN_PKG__: packageName,
  };

  console.log(`Adding a macOS target "${appName}" (${bundleId})\n`);

  copyTemplate(path.join(TEMPLATE, 'Podfile'), path.join(macosDir, 'Podfile'), values);
  copyTemplate(
    path.join(TEMPLATE, 'generate-project.rb'),
    path.join(macosDir, 'generate-project.rb'),
    values,
  );

  const appTemplate = path.join(TEMPLATE, 'app');
  for (const entry of fs.readdirSync(appTemplate)) {
    const target = substitute(entry, values);
    // PrivacyInfo sits beside the project, everything else inside the target.
    const dst =
      entry === 'PrivacyInfo.xcprivacy'
        ? path.join(macosDir, target)
        : path.join(macosDir, appName, target);
    copyTemplate(path.join(appTemplate, entry), dst, values);
  }

  // Only write a Metro config if there is not one already: replacing an app's
  // own config would throw away whatever else it configures.
  const metroConfig = path.join(appRoot, 'metro.config.js');
  if (fs.existsSync(metroConfig)) {
    console.log(
      `\nmetro.config.js already exists and was left alone. Add the macOS
resolver to it yourself -- without it a macOS bundle resolves to the iOS
react-native, which has no macOS support in its JS at all:

  const {getMacOSConfig} = require('${packageName}/macos/metro-config');
  module.exports = mergeConfig(config, getMacOSConfig(config));`,
    );
  } else {
    copyTemplate(path.join(TEMPLATE, 'metro.config.js'), metroConfig, values);
  }

  console.log(`
Next:

  gem install xcodeproj cocoapods
  ruby macos/generate-project.rb
  (cd macos && RCT_USE_RN_DEP=1 RCT_USE_PREBUILT_RNCORE=0 pod install)
  npx react-native start
  xcodebuild -workspace macos/${appName}.xcworkspace -scheme ${appName} \\
    -configuration Debug -destination 'platform=macOS' build

The two pod install variables matter: without them CocoaPods resolves the
prebuilt React Core, which is published for iOS only, and the install fails on
a platform mismatch.
`);
}

main();
