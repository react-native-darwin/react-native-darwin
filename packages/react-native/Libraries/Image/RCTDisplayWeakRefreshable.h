/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@protocol RCTDisplayRefreshable

- (void)displayDidRefresh:(RCTPlatformDisplayLink *)displayLink;  // [macOS] RCTPlatformDisplayLink; an alias for CADisplayLink off macOS

@end

@interface RCTDisplayWeakRefreshable : NSObject

@property (nonatomic, weak) id<RCTDisplayRefreshable> refreshable;

+ (RCTPlatformDisplayLink *)displayLinkWithWeakRefreshable:(id<RCTDisplayRefreshable>)refreshable;  // [macOS] RCTPlatformDisplayLink; an alias for CADisplayLink off macOS

@end
