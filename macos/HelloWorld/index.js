/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @format
 */

import {AppRegistry} from 'react-native';
import App from './App';

console.log('[js] index.js evaluated');

AppRegistry.registerComponent('HelloWorld', () => App);

console.log('[js] registered:', AppRegistry.getAppKeys().join(', '));
