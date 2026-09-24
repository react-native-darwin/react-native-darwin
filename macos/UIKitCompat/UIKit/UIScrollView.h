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
@property (nonatomic, assign) BOOL enableFocusRing;
@property (nonatomic, weak, nullable) id<UIScrollViewDelegate> delegate;

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

// UIKit asks this before stealing a touch from a subview. There is no drag-to-
// scroll gesture on macOS, so nothing is ever cancelled.
- (BOOL)touchesShouldCancelInContentView:(NSView *)view;

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
