/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow strict-local
 * @format
 */

// [macOS] The public macOS colour API, mirroring PlatformColorValueTypesIOS.

'use strict';

import type {ColorValue} from './StyleSheet';

import {
  ColorWithSystemEffectMacOSPrivate,
  DynamicColorMacOSPrivate,
  // $FlowFixMe[cannot-resolve-module] resolved by the macOS platform extension
} from './PlatformColorValueTypes.macos';

export type DynamicColorMacOSTuple = {
  light: ColorValue,
  dark: ColorValue,
  highContrastLight?: ColorValue,
  highContrastDark?: ColorValue,
};

/**
 * A colour that follows the system appearance, the macOS counterpart of
 * `DynamicColorIOS`.
 */
export const DynamicColorMacOS = (tuple: DynamicColorMacOSTuple): ColorValue => {
  return DynamicColorMacOSPrivate({
    light: tuple.light,
    dark: tuple.dark,
    highContrastLight: tuple.highContrastLight,
    highContrastDark: tuple.highContrastDark,
  });
};

export type SystemEffectMacOS = 'none' | 'pressed' | 'deepPressed' | 'disabled' | 'rollover';

/**
 * A colour with one of AppKit's system effects applied. There is no iOS
 * equivalent: UIKit expects the caller to supply the pressed or disabled
 * colour, where AppKit derives it.
 */
export const ColorWithSystemEffectMacOS = (
  color: ColorValue,
  effect: SystemEffectMacOS,
): ColorValue => {
  return ColorWithSystemEffectMacOSPrivate(color, effect);
};
