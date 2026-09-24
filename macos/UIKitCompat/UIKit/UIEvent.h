/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

// UIEvent is an alias, not a subclass: AppKit hands NSEvents to us from the
// responder chain, and those must satisfy every UIEvent-typed parameter.
@compatibility_alias UIEvent NSEvent;

typedef NS_ENUM(NSInteger, UITouchPhase) {
  UITouchPhaseBegan = 0,
  UITouchPhaseMoved,
  UITouchPhaseStationary,
  UITouchPhaseEnded,
  UITouchPhaseCancelled,
};

typedef NS_ENUM(NSInteger, UITouchType) {
  UITouchTypeDirect = 0,
  UITouchTypeIndirect,
  UITouchTypePencil,
  UITouchTypeIndirectPointer,
};

/**
 * A synthetic touch, built from an NSEvent.
 *
 * macOS has no UITouch. React Native's touch handlers are written against one,
 * so the mouse is translated into a single-finger touch sequence here rather
 * than in React Native. Keeping the translation inside the shim is what lets
 * RCTTouchHandler compile unmodified.
 */
@interface UITouch : NSObject

@property (nonatomic, readonly) UITouchPhase phase;
@property (nonatomic, readonly) UITouchType type;
@property (nonatomic, readonly) NSUInteger tapCount;
@property (nonatomic, readonly) NSTimeInterval timestamp;
@property (nonatomic, readonly, weak, nullable) NSView *view;
@property (nonatomic, readonly, weak, nullable) NSWindow *window;
@property (nonatomic, readonly) CGFloat force;
// A mouse is a point, so the contact radius is zero. Present because pointer
// event plumbing reads it unconditionally.
@property (nonatomic, readonly) CGFloat majorRadius;
@property (nonatomic, readonly) CGFloat majorRadiusTolerance;
// Stylus geometry. A mouse reports none of it; these are UIKit's own defaults
// for a non-stylus touch.
@property (nonatomic, readonly) CGFloat altitudeAngle;
@property (nonatomic, readonly) CGFloat azimuthAngleInView;
- (CGFloat)azimuthAngleInView:(nullable NSView *)view;
- (CGVector)azimuthUnitVectorInView:(nullable NSView *)view;
@property (nonatomic, readonly) CGFloat maximumPossibleForce;

- (instancetype)initWithEvent:(NSEvent *)event phase:(UITouchPhase)phase view:(nullable NSView *)view;

- (CGPoint)locationInView:(nullable NSView *)view;
- (CGPoint)previousLocationInView:(nullable NSView *)view;

@end

@protocol UIGestureRecognizerDelegate <NSGestureRecognizerDelegate>
@optional
- (BOOL)gestureRecognizerShouldBegin:(id)gestureRecognizer;
- (BOOL)gestureRecognizer:(id)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(id)otherGestureRecognizer;
- (BOOL)gestureRecognizer:(id)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;
@end

NS_ASSUME_NONNULL_END
