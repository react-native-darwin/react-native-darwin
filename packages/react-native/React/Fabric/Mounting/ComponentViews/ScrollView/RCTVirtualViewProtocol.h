/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <React/RCTVirtualViewMode.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RCTVirtualViewProtocol <NSObject>

- (NSString *)virtualViewID;
- (CGRect)containerRelativeRect:(RCTPlatformView *)view;
- (void)onModeChange:(RCTVirtualViewMode)newMode targetRect:(CGRect)targetRect thresholdRect:(CGRect)thresholdRect;
@end

NS_ASSUME_NONNULL_END
