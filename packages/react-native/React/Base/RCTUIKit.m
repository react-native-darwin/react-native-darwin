/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// [macOS] Implementation of the react-native-macos compatibility surface
// declared in RCTUIKit.h. See that header for why it exists. macOS]

#import <React/RCTUIKit.h>

#if TARGET_OS_OSX

@implementation RCTConvert (RCTUIKitCompat)

+ (NSColor *)NSColor:(id)json
{
  return [RCTConvert UIColor:json];
}

+ (NSImage *)NSImage:(id)json
{
  return [RCTConvert UIImage:json];
}

@end

#endif // TARGET_OS_OSX
