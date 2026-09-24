/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>

#import "UIKitDefines.h"
#import "UIView.h"

NS_ASSUME_NONNULL_BEGIN

@class UIScrollView;

@protocol UIScrollViewDelegate <NSObject>
@optional
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewDidZoom:(UIScrollView *)scrollView;
@end

/**
 * NSScrollView presented as a UIScrollView.
 *
 * The two differ more than their names suggest. NSScrollView scrolls a
 * documentView inside a clipView, and its contentView *is* the clip view, not
 * the scrolled content. contentOffset is expressed against a bottom-left origin
 * unless the clip view is flipped. Everything below reconciles that with
 * UIKit's model, so React Native's scroll code does not have to.
 */
@interface UIScrollView : NSScrollView

@property (nonatomic, assign) CGPoint contentOffset;
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, assign) UIEdgeInsets scrollIndicatorInsets;

@property (nonatomic, assign) BOOL showsHorizontalScrollIndicator;
@property (nonatomic, assign) BOOL showsVerticalScrollIndicator;
@property (nonatomic, assign) BOOL alwaysBounceHorizontal;
@property (nonatomic, assign) BOOL alwaysBounceVertical;
@property (nonatomic, assign, getter=isScrollEnabled) BOOL scrollEnabled;
@property (nonatomic, assign) BOOL bounces;

@property (nonatomic, assign) CGFloat minimumZoomScale;
@property (nonatomic, assign) CGFloat maximumZoomScale;
@property (nonatomic, assign) CGFloat zoomScale;

// No safe area on macOS, so no automatic adjustment to make. Stored so the
// property round-trips; it has no effect.
@property (nonatomic, assign) UIScrollViewContentInsetAdjustmentBehavior contentInsetAdjustmentBehavior;
// No pull-to-refresh on macOS; stored so the component parses.
@property (nonatomic, strong, nullable) NSView *refreshControl;
// No software keyboard to dismiss on macOS; stored only.
@property (nonatomic, assign) NSInteger keyboardDismissMode;
@property (nonatomic, assign) NSInteger indicatorStyle;
// UIScrollView state and behaviour flags with no NSScrollView counterpart.
// Stored so the ScrollView component's prop plumbing round-trips; the ones that
// describe an in-flight gesture (isTracking, isDragging, isDecelerating) are
// derived from AppKit's scroll notifications where it is possible to know.
@property (nonatomic, assign) BOOL scrollsToTop;
@property (nonatomic, assign, getter=isPagingEnabled) BOOL pagingEnabled;
@property (nonatomic, assign, getter=isDirectionalLockEnabled) BOOL directionalLockEnabled;
@property (nonatomic, assign) BOOL delaysContentTouches;
@property (nonatomic, assign) BOOL canCancelContentTouches;
@property (nonatomic, assign) CGFloat decelerationRate;
@property (nonatomic, readonly, getter=isTracking) BOOL tracking;
@property (nonatomic, readonly, getter=isDragging) BOOL dragging;
@property (nonatomic, readonly, getter=isDecelerating) BOOL decelerating;
@property (nonatomic, readonly, getter=isZooming) BOOL zooming;
@property (nonatomic, assign) BOOL bouncesZoom;
@property (nonatomic, assign) BOOL showsScrollIndicator;
@property (nonatomic, assign) BOOL automaticallyAdjustsScrollIndicatorInsets;
@property (nonatomic, assign) BOOL enableFocusRing;
@property (nonatomic, weak, nullable) id<UIScrollViewDelegate> delegate;

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

// UIKit asks this before stealing a touch from a subview. There is no drag-to-
// scroll gesture on macOS, so nothing is ever cancelled.
- (BOOL)touchesShouldCancelInContentView:(NSView *)view;
// AppKit shows scrollers on its own schedule and magnifies rather than zooms;
// both are accepted so the ScrollView component's imperative API compiles.
- (void)flashScrollIndicators;
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;

@end

/**
 * A clip view that can be told to stop clamping scroll bounds.
 *
 * NSClipView constrains scrolling to the document rect. React Native drives
 * contentOffset directly and expects to be able to overshoot.
 */
@interface UIScrollViewClipView : NSClipView
@property (nonatomic, assign) BOOL constrainScrolling;
@end

NS_ASSUME_NONNULL_END
