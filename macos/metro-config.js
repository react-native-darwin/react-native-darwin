/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * Metro resolution for the `macos` platform.
 *
 * Metro resolves one platform per request. Under `platform: 'macos'` the
 * candidate list for `./Foo` is `Foo.macos.js`, `Foo.native.js`, `Foo.js` --
 * `Foo.ios.js` is never considered. That breaks React Native two ways:
 *
 *   - Modules that exist only as `Foo.ios.js` / `Foo.android.js` are not found
 *     at all. `ReactDevToolsSettingsManager` is one of about twenty.
 *   - `Platform.js` re-exports `./Platform` and expects the platform-suffixed
 *     sibling to win. With no `Platform.macos.js` it resolves to itself, Metro
 *     reports a require cycle, and `Platform.OS` is undefined -- which surfaces
 *     much later as `Cannot read property 'OS' of undefined`.
 *
 * This resolves `macos` as an extension chain instead: `.macos.js`, then
 * `.ios.js`, then the unsuffixed file. iOS is the right fallback, because macOS
 * shares its Apple-platform module surface.
 *
 * react-native-macos solves the same problem by adding ~22 `.macos.js` files to
 * the upstream tree. Doing it in the resolver keeps them out of the fork.
 *
 * Usage:
 *
 *   const {mergeConfig} = require('@react-native/metro-config');
 *   const {getMacOSConfig} = require('react-native/macos/metro-config');
 *
 *   module.exports = mergeConfig(getDefaultConfig(__dirname), getMacOSConfig());
 *
 * @format
 */

'use strict';

const path = require('path');

/**
 * This package, as a directory rather than a name.
 *
 * The app installs it under an alias -- `react-native-macos:
 * npm:react-native-darwin@...` -- so its name is whatever the app chose. A
 * path is the one thing that is true either way, and Metro resolves absolute
 * paths directly, which also sidesteps the `exports` gate on deep imports.
 */
const PACKAGE_ROOT = path.resolve(__dirname, '..');

/**
 * The name this package is installed under, which is the specifier its own
 * `exports` are reachable by. The directory name rather than the `name` field,
 * because the app installs it under an alias.
 */
const PACKAGE_SPECIFIER = path.basename(PACKAGE_ROOT);

/**
 * Rewrites an import of upstream React Native onto this package.
 *
 * The point of the dual install: an app keeps `react-native` for iOS and
 * Android and adds this one for macOS, so the same `import {View} from
 * 'react-native'` has to mean different packages on different platforms.
 * Without the rewrite a macOS bundle pulls in the iOS package -- which has no
 * `Platform.macos.js`, no macOS view configs, and no idea the platform exists.
 *
 * Two forms, and both are needed. A subpath may be a package *export* rather
 * than a file -- `react-native/asset-registry` is one, and every bundled image
 * imports it -- so the specifier form is tried first, where `exports` still
 * applies. Deep imports of real files are not in `exports` and only resolve as
 * paths, so that is the fallback.
 *
 * Only for `platform === 'macos'`; iOS and Android bundles are untouched.
 */
function redirectionsFor(moduleName) {
  if (moduleName === 'react-native') {
    return [PACKAGE_ROOT];
  }
  if (moduleName.startsWith('react-native/')) {
    const subpath = moduleName.slice('react-native/'.length);
    return [`${PACKAGE_SPECIFIER}/${subpath}`, path.join(PACKAGE_ROOT, subpath)];
  }
  return [];
}


function resolveMacOS(context, moduleName, platform, next) {
  const resolve = next ?? ((ctx, name, plat) => ctx.resolveRequest(ctx, name, plat));

  if (platform !== 'macos') {
    return resolve(context, moduleName, platform);
  }

  for (const candidate of redirectionsFor(moduleName)) {
    try {
      return resolve(context, candidate, platform);
    } catch {
      // Try the next form; the error from the original name is the useful one.
    }
  }

  const attempt = candidate => {
    try {
      return resolve(context, moduleName, candidate);
    } catch (error) {
      return error;
    }
  };

  const macos = attempt('macos');
  if (!(macos instanceof Error)) {
    const resolvedToImporter =
      typeof macos.filePath === 'string' && macos.filePath === context.originModulePath;
    if (!resolvedToImporter) {
      return macos;
    }
  }

  const ios = attempt('ios');
  if (!(ios instanceof Error)) {
    return ios;
  }

  // Report the macOS failure: it names the platform that was asked for.
  throw macos instanceof Error ? macos : ios;
}


/**
 * The module React Native runs before anything else, from *this* package.
 *
 * `@react-native/metro-config` points this at `react-native/setup-env`,
 * resolved from the app -- which in a dual install is the iOS package. That
 * module is not in the macOS graph, Metro quietly skips it (it only emits a
 * `__r` for modules it actually has), and InitializeCore never runs. Nothing
 * reports an error: the first symptom is `Property 'window' doesn't exist`
 * from whichever module happens to touch a global first.
 *
 * Both paths are returned, because the serializer has no platform to branch
 * on. Metro keeps whichever is in the graph and drops the other, so an iOS
 * bundle still runs the iOS one.
 */
function setupEnvPath() {
  try {
    return require.resolve(`${PACKAGE_SPECIFIER}/setup-env`, {paths: [PACKAGE_ROOT]});
  } catch {
    return null;
  }
}

/**
 * A Metro config fragment that teaches the resolver about macOS.
 *
 * Pass the config you are extending. If it already has a `resolveRequest` --
 * `@expo/metro-config` installs a substantial one -- this *wraps* it rather
 * than replacing it, because `context.resolveRequest` inside a custom resolver
 * is Metro's default resolver, not whatever was configured before. Assigning
 * over it silently drops the other resolver's behaviour.
 *
 * Sets nothing else, so an app keeps full control of transformer, serializer
 * and watch folders.
 *
 *   const config = getDefaultConfig(__dirname);
 *   module.exports = mergeConfig(config, getMacOSConfig(config));
 */
function getMacOSConfig(baseConfig) {
  const upstream = baseConfig?.resolver?.resolveRequest;

  const upstreamRunFirst = baseConfig?.serializer?.getModulesRunBeforeMainModule;
  const ourSetupEnv = setupEnvPath();

  return {
    resolver: {
      platforms: ['macos', 'ios', 'android', 'native'],
      resolveRequest: (context, moduleName, platform) =>
        resolveMacOS(context, moduleName, platform, upstream),
    },
    serializer: {
      getModulesRunBeforeMainModule: entryFilePath => [
        ...(upstreamRunFirst?.(entryFilePath) ?? []),
        ...(ourSetupEnv != null ? [ourSetupEnv] : []),
      ],
    },
  };
}

module.exports = {getMacOSConfig, resolveMacOS};
