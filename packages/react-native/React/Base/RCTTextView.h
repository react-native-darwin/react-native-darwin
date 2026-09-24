/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS] Compatibility header for third-party code written against
// microsoft/react-native-macos, which still carries the legacy Paper text view.
//
// Upstream React Native removed RCTTextView when Fabric replaced the old text
// implementation, but published macOS modules still import it. react-native-svg
// is the case in hand: RNSVGTopAlignedLabel.h imports this header and then
// derives from NSTextView, using nothing the header declares.
//
// So this provides the include, not the class. A module that genuinely needs
// the legacy view will now fail on the unknown type, which says what is wrong
// far better than a missing file does.
//
// See React/Base/RCTUIKit.h for the rest of the react-native-macos
// compatibility surface. macOS]

#pragma once

#import <TargetConditionals.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

#import <React/RCTUIKit.h>
