/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>

// The shim's compile-time names, which is all this layer is for.
//
// Deliberately aliases rather than real classes: registering a UIKit name
// with the ObjC runtime makes Apple's own frameworks mistake the process for
// Catalyst. macOS's one-time-code AutoFill does exactly that for the focused
// text field, and answering yes sends it into UIKitMacHelper, which dlopens a
// UIKit.framework that does not exist here and takes the process down.
//
// Forward-declared first so the aliases can appear before anything uses them.
@class RCTUIKitCompatTouch;
@compatibility_alias UITouch RCTUIKitCompatTouch;


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
@interface RCTUIKitCompatTouch : NSObject

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

/**
 * The touch location in window coordinates, bottom-left origin -- AppKit's
 * convention, not UIKit's.
 *
 * UITouch has no such member; -locationInView: is the UIKit spelling. It is
 * here because react-native-macos makes its RCTUITouch an NSEvent subclass, so
 * every module written against that fork reaches for NSEvent's
 * -locationInWindow on a touch. react-native-gesture-handler does it in three
 * places. The value is already captured at init, so exposing it costs nothing.
 */
@property (nonatomic, readonly) CGPoint locationInWindow;

- (instancetype)initWithEvent:(NSEvent *)event phase:(UITouchPhase)phase view:(nullable NSView *)view;

/**
 * Advances this touch to a later point in the same gesture.
 *
 * UIKit mutates a UITouch across its phases rather than handing out a new one,
 * and React Native depends on that: the touch registry in
 * RCTSurfaceTouchHandler is keyed by the object, so a fresh instance for each
 * mouse event would look like an unrelated touch and never match.
 */
- (void)updateWithEvent:(NSEvent *)event phase:(UITouchPhase)phase;

- (CGPoint)locationInView:(nullable NSView *)view;
- (CGPoint)previousLocationInView:(nullable NSView *)view;

@end

#ifdef __cplusplus
extern "C" {
#endif

/**
 * The UITouch set for an event.
 *
 * -[UIEvent allTouches] cannot be provided as a property: NSEvent already
 * declares -allTouches returning NSSet<NSTouch *>, and a category cannot retype
 * it. This is the one place the UIKit name is genuinely unavailable, so call
 * sites use this function instead.
 *
 * A mouse is a single pointer, so the set holds at most one synthesised UITouch.
 */
NSSet<UITouch *> *RCTPlatformTouchesForEvent(UIEvent *_Nullable event);

#ifdef __cplusplus
}
#endif

@protocol UIGestureRecognizerDelegate <NSGestureRecognizerDelegate>
@optional
- (BOOL)gestureRecognizerShouldBegin:(id)gestureRecognizer;
- (BOOL)gestureRecognizer:(id)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(id)otherGestureRecognizer;
- (BOOL)gestureRecognizer:(id)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;
@end

NS_ASSUME_NONNULL_END
