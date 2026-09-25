/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow strict
 * @format
 */

// [macOS] The macOS implementation of Platform.
//
// `PlatformTypes.js` upstream already declares `'macos'` in `PlatformOSType`
// and a `MacOSPlatform` shape; only the module was missing, so `Platform.OS`
// came out as `'ios'` and every `Platform.select({macos: ...})` in the
// ecosystem silently took the iOS branch.
//
// The native constants come from the same `PlatformConstants` turbo module iOS
// uses -- the fork builds it for macOS and `RCTConstants.m` reports
// `RCTPlatformName` as `"macos"`. There is no interface idiom on macOS, so
// `isTV` and `isVision` are constants rather than reads. macOS]

import type {PlatformSelectSpec, PlatformType} from './PlatformTypes';

import NativePlatformConstantsIOS from './NativePlatformConstantsIOS';

const Platform: PlatformType = {
  __constants: null,
  OS: 'macos',
  // $FlowFixMe[unsafe-getters-setters]
  get Version(): string {
    // $FlowFixMe[object-this-reference]
    return this.constants.osVersion;
  },
  // $FlowFixMe[unsafe-getters-setters]
  get constants(): {
    isTesting: boolean,
    osVersion: string,
    reactNativeVersion: {
      major: number,
      minor: number,
      patch: number,
      prerelease: ?number,
    },
    systemName: string,
  } {
    // $FlowFixMe[object-this-reference]
    if (this.__constants == null) {
      // $FlowFixMe[object-this-reference]
      this.__constants = NativePlatformConstantsIOS.getConstants();
    }
    // $FlowFixMe[object-this-reference]
    return this.__constants;
  },
  // $FlowFixMe[unsafe-getters-setters]
  get isTV(): boolean {
    return false;
  },
  // $FlowFixMe[unsafe-getters-setters]
  get isVision(): boolean {
    return false;
  },
  // $FlowFixMe[unsafe-getters-setters]
  get isTesting(): boolean {
    if (__DEV__) {
      // $FlowFixMe[object-this-reference]
      return this.constants.isTesting;
    }
    return false;
  },
  // $FlowFixMe[unsafe-getters-setters]
  get isDisableAnimations(): boolean {
    // $FlowFixMe[object-this-reference]
    return this.constants.isDisableAnimations ?? this.isTesting;
  },
  // `macos` first, then `ios`, then `native`, then `default`. The iOS step
  // matters: almost every `Platform.select` in the ecosystem predates macOS and
  // only offers an `ios` branch, which is the right one to take here.
  select: <T>(spec: PlatformSelectSpec<T>): T =>
    // $FlowFixMe[incompatible-type]
    'macos' in spec
      ? spec.macos
      : 'ios' in spec
        ? spec.ios
        : 'native' in spec
          ? spec.native
          : spec.default,
};

export default Platform;
