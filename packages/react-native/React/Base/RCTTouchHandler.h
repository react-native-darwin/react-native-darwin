/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <UIKit/UIKit.h>

#import <React/RCTFrameUpdate.h>

@class RCTBridge;

@interface RCTTouchHandler : RCTPlatformGestureRecognizer

- (instancetype)initWithBridge:(RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;

- (void)attachToView:(RCTPlatformView *)view;
- (void)detachFromView:(RCTPlatformView *)view;

- (void)cancel;

@end
