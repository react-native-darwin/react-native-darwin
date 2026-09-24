/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

#import "UIColor.h"
#import "UIEvent.h"
#import "UIKitDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The UIKit view surface, provided on *every* NSView.
 *
 * This category is the reason the fork stays small. React Native writes
 * `for (UIView *subview in self.subviews)` in dozens of places, but
 * -[NSView subviews] returns plain NSViews that AppKit created. If the UIKit
 * surface lived only on the UIView subclass below, each of those loops would
 * be a static type lie waiting to become an unrecognised selector, and each one
 * would need an upstream edit to fix.
 *
 * Putting the surface on NSView means any view, from anywhere, answers it.
 *
 * Storage-backed properties here use associated objects. The UIView subclass
 * overrides the hot ones with real ivars.
 */
@interface NSView (UIKitCompat)

@property (nonatomic, assign, getter=isUserInteractionEnabled) BOOL userInteractionEnabled;
@property (nonatomic, assign) CGFloat alpha;
@property (nonatomic, copy, nullable) UIColor *backgroundColor;
@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, assign) CATransform3D transform3D;
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) UIViewContentMode contentMode;
@property (nonatomic, readonly) UIEdgeInsets safeAreaInsets;
@property (nonatomic, copy, nullable) NSArray *accessibilityElements;

@property (nonatomic, readonly) BOOL canBecomeFirstResponder;
@property (nonatomic, readonly) BOOL isFirstResponder;
- (BOOL)becomeFirstResponder;

// UIKit spells these without an argument. NSView's -setNeedsDisplay: and
// -setNeedsLayout: take a BOOL, so these are distinct selectors, not overrides.
- (void)setNeedsDisplay;
- (void)setNeedsLayout;
- (void)layoutIfNeeded;
- (void)layoutSubviews;

- (void)insertSubview:(NSView *)view atIndex:(NSInteger)index;
- (void)bringSubviewToFront:(NSView *)view;
- (void)sendSubviewToBack:(NSView *)view;
- (BOOL)isDescendantOfView:(NSView *)view;

- (nullable NSView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event;
- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event;

- (void)didMoveToWindow;
- (void)didMoveToSuperview;

@end

/**
 * UIView is an alias for NSView, not a subclass.
 *
 * This is the one place the layer deliberately gives up on reproducing UIKit
 * exactly, and it is worth understanding why.
 *
 * In UIKit, UIScrollView *is* a UIView. On macOS it cannot be: to scroll, it
 * has to derive from NSScrollView. If UIView were its own NSView subclass,
 * UIScrollView would be a *sibling*, and every upstream signature taking a
 * `UIView *` would reject a scroll view. There is no arrangement of single
 * inheritance that reproduces both UIKit's hierarchy and AppKit's.
 *
 * So the alias follows AppKit's truth: on macOS the common supertype of every
 * view is NSView. That makes all ~322 `UIView *` declarations in upstream
 * source correct as written, with no edit.
 *
 * What the alias cannot carry is behaviour. A plain NSView is not flipped, is
 * not layer-backed, and has no -layoutSubviews. Views that React Native
 * creates itself need all three, and they get them from RCTPlatformView below.
 */
@compatibility_alias UIView NSView;

/**
 * The concrete view class for anything React Native instantiates or subclasses.
 *
 * Three differences from a plain NSView matter, and all three are fixed here:
 *
 *   1. NSView's origin is bottom-left. -isFlipped returns YES so layout
 *      arithmetic copied from iOS lands in the right place.
 *   2. NSView is not layer-backed by default. -wantsLayer is set at init.
 *   3. NSView has no backgroundColor, transform, or layoutSubviews dispatch.
 *
 * Upstream uses this name in exactly two positions, and never as a pointer
 * type:
 *
 *     @interface RCTView : RCTPlatformView        // superclass
 *     [[RCTPlatformView alloc] initWithFrame:f]   // instantiation
 *
 * Everything else keeps saying `UIView *`. That restriction is what keeps this
 * to about 20 upstream files instead of the 538 that react-native-macos edits,
 * and macos/ci/check-budget.sh enforces it.
 */
@interface RCTPlatformView : NSView

// NSView already provides -clipsToBounds (10.9+), so it is not redeclared here.

// UIKit subclasses override -canBecomeFirstResponder and expect the framework
// to honour it. RCTPlatformView bridges that to AppKit's
// -acceptsFirstResponder, and terminates the chain at NSView's own
// implementation rather than bouncing back through the category.
@property (nonatomic, readonly) BOOL canBecomeFirstResponder;

// Draw the focus ring when this view is first responder.
@property (nonatomic, assign) BOOL enableFocusRing;

// Receive the mouse-down that activates a background window, rather than
// swallowing it to raise the window. UIKit has no equivalent; AppKit needs it.
@property (nonatomic, assign) BOOL acceptsFirstMouse;

@end

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Hit-test `view` for `point`, where `point` is in `fromView`'s coordinate space.
 *
 * Exists because the conversion is genuinely different from UIKit's.
 * -[NSView hitTest:] expects its argument in the *superview's* space, and
 * -[NSView convertPoint:fromView:] ignores layer.transform. Converting through
 * CALayer instead keeps transformed views hit-testable.
 */
NSView *_Nullable UIViewHitTestWithEvent(NSView *view, CGPoint point, NSView *fromView, UIEvent *_Nullable event);

void UIViewSetContentModeRedraw(NSView *view);
BOOL UIViewIsDescendantOfView(NSView *view, NSView *parent);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
