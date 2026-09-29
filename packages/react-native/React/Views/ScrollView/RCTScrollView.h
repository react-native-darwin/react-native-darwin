/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h> // [macOS] the public half, which
// declares the platform vocabulary. Importing <UIKit/UIKit.h> here would reach the shim
// inside this fork and an empty header everywhere else, so a third-party pod
// got nothing -- which is how react-native-worklets failed to build.
