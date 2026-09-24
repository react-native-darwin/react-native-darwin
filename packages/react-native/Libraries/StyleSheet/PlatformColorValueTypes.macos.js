/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow strict-local
 * @format
 */

// [macOS] The macOS colour types.
//
// `semantic` and `dynamic` carry over from iOS unchanged -- RCTConvert resolves
// both on this platform, and semantic names are looked up on NSColor, so
// AppKit's whole vocabulary (labelColor, windowBackgroundColor,
// controlAccentColor, ...) works. What iOS has no equivalent for is
// `colorWithSystemEffect`, AppKit's pressed / disabled / rollover variants of a
// colour, so that is added here. macOS]


import type {ProcessedColorValue} from './processColor';
import type {ColorValue, NativeColorValue} from './StyleSheet';

/** The actual type of the opaque NativeColorValue on macOS platform */
type LocalNativeColorValue = {
  semantic?: Array<string>,
  colorWithSystemEffect?: {
    baseColor: ?(ColorValue | ProcessedColorValue),
    systemEffect: string,
  },
  dynamic?: {
    light: ?(ColorValue | ProcessedColorValue),
    dark: ?(ColorValue | ProcessedColorValue),
    highContrastLight?: ?(ColorValue | ProcessedColorValue),
    highContrastDark?: ?(ColorValue | ProcessedColorValue),
  },
};

export const PlatformColor = (...names: Array<string>): NativeColorValue => {
  // $FlowExpectedError[incompatible-type] LocalNativeColorValue is the iOS LocalNativeColorValue type
  return {semantic: names} as LocalNativeColorValue;
};

export type DynamicColorMacOSTuplePrivate = {
  light: ColorValue,
  dark: ColorValue,
  highContrastLight?: ColorValue,
  highContrastDark?: ColorValue,
};

export const DynamicColorMacOSPrivate = (
  tuple: DynamicColorMacOSTuplePrivate,
): ColorValue => {
  return {
    dynamic: {
      light: tuple.light,
      dark: tuple.dark,
      highContrastLight: tuple.highContrastLight,
      highContrastDark: tuple.highContrastDark,
    },
    /* $FlowExpectedError[incompatible-type]
     * LocalNativeColorValue is the actual type of the opaque NativeColorValue on macOS platform */
  } as LocalNativeColorValue;
};

export type SystemEffectMacOSPrivate =
  | 'none'
  | 'pressed'
  | 'deepPressed'
  | 'disabled'
  | 'rollover';

export const ColorWithSystemEffectMacOSPrivate = (
  color: ColorValue,
  effect: SystemEffectMacOSPrivate,
): ColorValue => {
  return {
    colorWithSystemEffect: {
      baseColor: color,
      systemEffect: effect,
    },
    /* $FlowExpectedError[incompatible-type]
     * LocalNativeColorValue is the actual type of the opaque NativeColorValue */
  } as LocalNativeColorValue;
};

const _normalizeColorObject = (
  color: LocalNativeColorValue,
): ?LocalNativeColorValue => {
  if ('colorWithSystemEffect' in color && color.colorWithSystemEffect !== undefined) {
    const normalizeColor = require('./normalizeColor').default;
    const spec = color.colorWithSystemEffect;
    return {
      colorWithSystemEffect: {
        // $FlowFixMe[incompatible-call]
        baseColor: normalizeColor(spec.baseColor),
        systemEffect: spec.systemEffect,
      },
    };
  } else if ('semantic' in color) {
    // an AppKit or iOS semantic colour
    return color;
  } else if ('dynamic' in color && color.dynamic !== undefined) {
    const normalizeColor = require('./normalizeColor').default;

    // a dynamic, appearance aware color
    const dynamic = color.dynamic;
    const dynamicColor: LocalNativeColorValue = {
      dynamic: {
        // $FlowFixMe[incompatible-use]
        light: normalizeColor(dynamic.light),
        // $FlowFixMe[incompatible-use]
        dark: normalizeColor(dynamic.dark),
        // $FlowFixMe[incompatible-use]
        highContrastLight: normalizeColor(dynamic.highContrastLight),
        // $FlowFixMe[incompatible-use]
        highContrastDark: normalizeColor(dynamic.highContrastDark),
      },
    };
    return dynamicColor;
  }
  return null;
};

export const normalizeColorObject: (
  color: NativeColorValue,
  /* $FlowExpectedError[incompatible-type]
   * LocalNativeColorValue is the actual type of the opaque NativeColorValue on macOS platform */
) => ?ProcessedColorValue = _normalizeColorObject;

const _processColorObject = (
  color: LocalNativeColorValue,
): ?LocalNativeColorValue => {
  if ('dynamic' in color && color.dynamic != null) {
    const processColor = require('./processColor').default;
    const dynamic = color.dynamic;
    const dynamicColor: LocalNativeColorValue = {
      dynamic: {
        // $FlowFixMe[incompatible-use]
        light: processColor(dynamic.light),
        // $FlowFixMe[incompatible-use]
        dark: processColor(dynamic.dark),
        // $FlowFixMe[incompatible-use]
        highContrastLight: processColor(dynamic.highContrastLight),
        // $FlowFixMe[incompatible-use]
        highContrastDark: processColor(dynamic.highContrastDark),
      },
    };
    return dynamicColor;
  }
  return color;
};

export const processColorObject: (
  color: NativeColorValue,
  /* $FlowExpectedError[incompatible-type]
   * LocalNativeColorValue is the actual type of the opaque NativeColorValue on macOS platform */
) => ?NativeColorValue = _processColorObject;
