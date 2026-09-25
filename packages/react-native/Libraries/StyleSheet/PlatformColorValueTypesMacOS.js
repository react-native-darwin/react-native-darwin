/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow strict-local
 * @format
 */

// [macOS] The off-macOS stand-in, matching how PlatformColorValueTypesIOS.js
// behaves elsewhere: importing is fine, calling is not.

import type {ColorValue} from './StyleSheet';

export type DynamicColorMacOSTuple = {
  light: ColorValue,
  dark: ColorValue,
  highContrastLight?: ColorValue,
  highContrastDark?: ColorValue,
};

export const DynamicColorMacOS = (_tuple: DynamicColorMacOSTuple): ColorValue => {
  throw new Error('DynamicColorMacOS is not available on this platform.');
};

export type SystemEffectMacOS = 'none' | 'pressed' | 'deepPressed' | 'disabled' | 'rollover';

export const ColorWithSystemEffectMacOS = (
  _color: ColorValue,
  _effect: SystemEffectMacOS,
): ColorValue => {
  throw new Error('ColorWithSystemEffectMacOS is not available on this platform.');
};
