/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTDisplayWeakRefreshable.h"

@implementation RCTDisplayWeakRefreshable

+ (RCTPlatformDisplayLink *)displayLinkWithWeakRefreshable:(id<RCTDisplayRefreshable>)refreshable  // [macOS] RCTPlatformDisplayLink; an alias for CADisplayLink off macOS
{
  RCTDisplayWeakRefreshable *target = [[RCTDisplayWeakRefreshable alloc] initWithRefreshable:refreshable];
  return [RCTPlatformDisplayLink displayLinkWithTarget:target selector:@selector(displayDidRefresh:)];  // [macOS] RCTPlatformDisplayLink; an alias for CADisplayLink off macOS
}

- (instancetype)initWithRefreshable:(id<RCTDisplayRefreshable>)refreshable
{
  if (self = [super init]) {
    _refreshable = refreshable;
  }
  return self;
}

- (void)displayDidRefresh:(RCTPlatformDisplayLink *)displayLink  // [macOS] RCTPlatformDisplayLink; an alias for CADisplayLink off macOS
{
  [_refreshable displayDidRefresh:displayLink];
}

@end
