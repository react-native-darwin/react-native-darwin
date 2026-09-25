/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @format
 */

const path = require('path');
const {getDefaultConfig, mergeConfig} = require('@react-native/metro-config');
// Shipped inside the package by macos/scripts/publish.sh, so a published app
// requires it as 'react-native/macos/metro-config'.
const {getMacOSConfig} = require('../metro-config');

const reactNativeRoot = path.resolve(__dirname, '../../packages/react-native');

const appNodeModules = path.resolve(__dirname, 'node_modules');

const baseConfig = getDefaultConfig(__dirname);

module.exports = mergeConfig(baseConfig, getMacOSConfig(baseConfig), {
  resolver: {
    // react-native is a path dependency here, so its own `require('react')`
    // resolves upward from packages/react-native and misses the app's copy.
    // Redirecting keeps exactly one React in the graph, which React requires.
    extraNodeModules: new Proxy(
      {'react-native': reactNativeRoot},
      {
        get(target, name) {
          if (name in target) {
            return target[name];
          }
          return path.join(appNodeModules, String(name));
        },
        has(target, name) {
          return true;
        },
      },
    ),
  },
  watchFolders: [reactNativeRoot, appNodeModules],
});
