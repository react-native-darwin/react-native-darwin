/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIEvent.h"

@implementation UITouch {
  NSEvent *_event;
  CGPoint _locationInWindow;
  CGPoint _previousLocationInWindow;
}

- (instancetype)initWithEvent:(NSEvent *)event phase:(UITouchPhase)phase view:(NSView *)view
{
  if ((self = [super init])) {
    _event = event;
    _phase = phase;
    _type = UITouchTypeIndirectPointer;
    _tapCount = event.type == NSEventTypeLeftMouseDown || event.type == NSEventTypeLeftMouseUp
        ? (NSUInteger)event.clickCount
        : 1;
    _timestamp = event.timestamp;
    _view = view;
    _window = event.window;
    _force = event.type == NSEventTypePressure ? event.pressure : 0;
    _maximumPossibleForce = 1;
    _majorRadius = 0;
    _majorRadiusTolerance = 0;
    _altitudeAngle = M_PI_2;  // perpendicular, i.e. not a stylus
    _azimuthAngleInView = 0;
    _locationInWindow = NSPointToCGPoint(event.locationInWindow);
    _previousLocationInWindow = _locationInWindow;
  }
  return self;
}

- (CGFloat)azimuthAngleInView:(__unused NSView *)view
{
  return 0;
}

- (CGVector)azimuthUnitVectorInView:(__unused NSView *)view
{
  return CGVectorMake(0, 0);
}

- (CGPoint)locationInView:(NSView *)view
{
  if (view == nil) {
    return _locationInWindow;
  }
  return NSPointToCGPoint([view convertPoint:NSPointFromCGPoint(_locationInWindow) fromView:nil]);
}

- (CGPoint)previousLocationInView:(NSView *)view
{
  if (view == nil) {
    return _previousLocationInWindow;
  }
  return NSPointToCGPoint([view convertPoint:NSPointFromCGPoint(_previousLocationInWindow) fromView:nil]);
}

@end

NSSet<UITouch *> *RCTPlatformTouchesForEvent(UIEvent *event)
{
  if (event == nil) {
    return [NSSet set];
  }

  UITouchPhase phase;
  switch (event.type) {
    case NSEventTypeLeftMouseDown:
    case NSEventTypeRightMouseDown:
    case NSEventTypeOtherMouseDown:
      phase = UITouchPhaseBegan;
      break;
    case NSEventTypeLeftMouseDragged:
    case NSEventTypeRightMouseDragged:
    case NSEventTypeOtherMouseDragged:
    case NSEventTypeMouseMoved:
      phase = UITouchPhaseMoved;
      break;
    case NSEventTypeLeftMouseUp:
    case NSEventTypeRightMouseUp:
    case NSEventTypeOtherMouseUp:
      phase = UITouchPhaseEnded;
      break;
    default:
      phase = UITouchPhaseStationary;
      break;
  }

  NSView *view = event.window.contentView;
  if (view != nil) {
    NSView *hit = [view hitTest:event.locationInWindow];
    if (hit != nil) {
      view = hit;
    }
  }

  return [NSSet setWithObject:[[UITouch alloc] initWithEvent:event phase:phase view:view]];
}
