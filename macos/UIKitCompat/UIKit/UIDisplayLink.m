/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIDisplayLink.h"

#if TARGET_OS_OSX

#import <AppKit/AppKit.h>

@implementation RCTPlatformDisplayLink {
  __weak id _target;
  SEL _selector;
  // Held as id because CADisplayLink is macOS 14+ and the deployment target
  // is 11.0; every use is inside an @available check.
  id _displayLink;
  NSTimer *_timer;              // earlier
  CFTimeInterval _lastTimestamp;
}

+ (instancetype)displayLinkWithTarget:(id)target selector:(SEL)selector
{
  RCTPlatformDisplayLink *link = [RCTPlatformDisplayLink new];
  link->_target = target;
  link->_selector = selector;
  link->_preferredFramesPerSecond = 0;  // 0 means "native refresh rate"

  if (@available(macOS 14.0, *)) {
    NSScreen *screen = NSScreen.mainScreen;
    if (screen != nil) {
      link->_displayLink = [screen displayLinkWithTarget:link selector:@selector(_tick:)];
    }
  }
  return link;
}

- (void)_tick:(id)sender
{
  if (@available(macOS 14.0, *)) {
    if ([sender isKindOfClass:[CADisplayLink class]]) {
      _lastTimestamp = ((CADisplayLink *)sender).timestamp;
    } else {
      _lastTimestamp = CACurrentMediaTime();
    }
  } else {
    _lastTimestamp = CACurrentMediaTime();
  }

  id target = _target;
  if (target == nil) {
    return;
  }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  [target performSelector:_selector withObject:self];
#pragma clang diagnostic pop
}

- (CFTimeInterval)_interval
{
  if (_preferredFramesPerSecond > 0) {
    return 1.0 / (CFTimeInterval)_preferredFramesPerSecond;
  }
  NSScreen *screen = NSScreen.mainScreen;
  if (@available(macOS 12.0, *)) {
    NSTimeInterval minimum = screen.minimumRefreshInterval;
    if (minimum > 0) {
      return minimum;
    }
  }
  return 1.0 / 60.0;
}

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode
{
  if (_displayLink != nil) {
    if (@available(macOS 14.0, *)) {
      [(CADisplayLink *)_displayLink addToRunLoop:runloop forMode:mode];
    }
    return;
  }
  if (_timer != nil) {
    return;
  }
  _timer = [NSTimer timerWithTimeInterval:[self _interval]
                                   target:self
                                 selector:@selector(_tick:)
                                 userInfo:nil
                                  repeats:YES];
  [runloop addTimer:_timer forMode:mode];
}

- (void)removeFromRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode
{
  if (_displayLink != nil) {
    if (@available(macOS 14.0, *)) {
      [(CADisplayLink *)_displayLink removeFromRunLoop:runloop forMode:mode];
    }
    return;
  }
  [_timer invalidate];
  _timer = nil;
}

- (void)invalidate
{
  if (@available(macOS 14.0, *)) {
    [(CADisplayLink *)_displayLink invalidate];
  }
  _displayLink = nil;
  [_timer invalidate];
  _timer = nil;
  _target = nil;
}

- (BOOL)isPaused
{
  if (_displayLink != nil) {
    if (@available(macOS 14.0, *)) {
      return ((CADisplayLink *)_displayLink).isPaused;
    }
  }
  return _timer == nil;
}

- (void)setPaused:(BOOL)paused
{
  if (_displayLink != nil) {
    if (@available(macOS 14.0, *)) {
      ((CADisplayLink *)_displayLink).paused = paused;
    }
    return;
  }
  // An NSTimer cannot pause, so honour it by dropping the tick.
  _timer.fireDate = paused ? NSDate.distantFuture : NSDate.date;
}

- (CFTimeInterval)timestamp
{
  return _lastTimestamp;
}

- (CFTimeInterval)duration
{
  if (_displayLink != nil) {
    if (@available(macOS 14.0, *)) {
      return ((CADisplayLink *)_displayLink).duration;
    }
  }
  return [self _interval];
}

- (CFTimeInterval)targetTimestamp
{
  if (_displayLink != nil) {
    if (@available(macOS 14.0, *)) {
      return ((CADisplayLink *)_displayLink).targetTimestamp;
    }
  }
  return _lastTimestamp + [self _interval];
}

@end

#endif // TARGET_OS_OSX
