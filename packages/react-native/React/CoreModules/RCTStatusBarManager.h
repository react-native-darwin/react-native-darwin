/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <UIKit/UIKit.h>

#import <React/RCTConvert.h>
#import <React/RCTEventEmitter.h>

#if !TARGET_OS_TV
@interface RCTConvert (UIStatusBar)

+ (RCTPlatformStatusBarStyle)UIStatusBarStyle:(id)json;
+ (RCTPlatformStatusBarAnimation)UIStatusBarAnimation:(id)json;

@end
#endif

@interface RCTStatusBarManager : RCTEventEmitter

@end
