/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIScrollView.h"

@implementation UIScrollViewClipView

- (BOOL)isFlipped
{
  return YES;
}

- (NSRect)constrainBoundsRect:(NSRect)proposedBounds
{
  if (!_constrainScrolling) {
    return proposedBounds;
  }
  return [super constrainBoundsRect:proposedBounds];
}

@end

@implementation UIScrollView {
  UIView *_documentView;
  BOOL _liveScrolling;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
  if ((self = [super initWithFrame:frameRect])) {
    _scrollEnabled = YES;
    _bounces = YES;
    _minimumZoomScale = 1.0;
    _maximumZoomScale = 1.0;
    _zoomScale = 1.0;

    UIScrollViewClipView *clipView = [[UIScrollViewClipView alloc] initWithFrame:self.bounds];
    clipView.constrainScrolling = NO;
    clipView.drawsBackground = NO;
    self.contentView = clipView;

    _documentView = [[UIView alloc] initWithFrame:self.bounds];
    self.documentView = _documentView;

    self.drawsBackground = NO;
    self.hasHorizontalScroller = YES;
    self.hasVerticalScroller = YES;
    self.autohidesScrollers = YES;

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(UIKitCompatBoundsDidChange:)
                                               name:NSViewBoundsDidChangeNotification
                                             object:clipView];
    clipView.postsBoundsChangedNotifications = YES;

    _decelerationRate = 0.998;  // UIScrollViewDecelerationRateNormal
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(UIKitCompatWillStartLiveScroll:)
                                               name:NSScrollViewWillStartLiveScrollNotification
                                             object:self];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(UIKitCompatDidEndLiveScroll:)
                                               name:NSScrollViewDidEndLiveScrollNotification
                                             object:self];
  }
  return self;
}

- (void)dealloc
{
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)UIKitCompatWillStartLiveScroll:(__unused NSNotification *)notification
{
  _liveScrolling = YES;
  if ([_delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
    [_delegate scrollViewWillBeginDragging:self];
  }
}

- (void)UIKitCompatDidEndLiveScroll:(__unused NSNotification *)notification
{
  _liveScrolling = NO;
  if ([_delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
    [_delegate scrollViewDidEndDragging:self willDecelerate:NO];
  }
}

- (void)UIKitCompatBoundsDidChange:(__unused NSNotification *)notification
{
  if ([_delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
    [_delegate scrollViewDidScroll:self];
  }
}

- (CGPoint)contentOffset
{
  // The clip view is flipped, so its bounds origin already reads top-left-down,
  // which is what UIKit means by contentOffset.
  return NSPointToCGPoint(self.contentView.bounds.origin);
}

- (void)setContentOffset:(CGPoint)contentOffset
{
  [self.contentView scrollToPoint:NSPointFromCGPoint(contentOffset)];
  [self reflectScrolledClipView:self.contentView];
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
  if (!animated) {
    self.contentOffset = contentOffset;
    return;
  }
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
    context.allowsImplicitAnimation = YES;
    [self.contentView.animator setBoundsOrigin:NSPointFromCGPoint(contentOffset)];
  }
      completionHandler:^{
        [self reflectScrolledClipView:self.contentView];
      }];
}

- (CGSize)contentSize
{
  return NSSizeToCGSize(_documentView.frame.size);
}

- (void)setContentSize:(CGSize)contentSize
{
  _documentView.frame = NSMakeRect(0, 0, contentSize.width, contentSize.height);
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
  _contentInset = contentInset;
  self.automaticallyAdjustsContentInsets = NO;
  super.contentInsets = NSEdgeInsetsMake(contentInset.top, contentInset.left, contentInset.bottom, contentInset.right);
}

- (void)setScrollIndicatorInsets:(UIEdgeInsets)scrollIndicatorInsets
{
  _scrollIndicatorInsets = scrollIndicatorInsets;
  super.scrollerInsets = NSEdgeInsetsMake(
      scrollIndicatorInsets.top, scrollIndicatorInsets.left, scrollIndicatorInsets.bottom, scrollIndicatorInsets.right);
}

- (void)setShowsHorizontalScrollIndicator:(BOOL)showsHorizontalScrollIndicator
{
  _showsHorizontalScrollIndicator = showsHorizontalScrollIndicator;
  self.hasHorizontalScroller = showsHorizontalScrollIndicator;
}

- (void)setShowsVerticalScrollIndicator:(BOOL)showsVerticalScrollIndicator
{
  _showsVerticalScrollIndicator = showsVerticalScrollIndicator;
  self.hasVerticalScroller = showsVerticalScrollIndicator;
}

- (void)setZoomScale:(CGFloat)zoomScale
{
  _zoomScale = zoomScale;
  self.magnification = zoomScale;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
  _scrollEnabled = scrollEnabled;
  // NSScrollView has no scrollEnabled. Removing the scrollers and refusing
  // scroll wheel events in -scrollWheel: is the closest equivalent.
  self.hasHorizontalScroller = scrollEnabled && _showsHorizontalScrollIndicator;
  self.hasVerticalScroller = scrollEnabled && _showsVerticalScrollIndicator;
}

- (void)scrollWheel:(NSEvent *)event
{
  if (!_scrollEnabled) {
    // Pass it up so an enclosing scroll view can still handle it.
    [self.nextResponder scrollWheel:event];
    return;
  }
  [super scrollWheel:event];
}

- (void)flashScrollIndicators
{
  [self flashScrollers];
}

- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated
{
  [self magnifyToFitRect:NSRectFromCGRect(rect)];
  if (animated) {
    [self reflectScrolledClipView:self.contentView];
  }
}

- (BOOL)isTracking
{
  // AppKit reports a scroll gesture through NSScrollViewWillStartLiveScroll /
  // DidEndLiveScroll rather than a flag; _liveScrolling tracks that pair.
  return _liveScrolling;
}

- (BOOL)isDragging
{
  return _liveScrolling;
}

- (BOOL)isDecelerating
{
  // Momentum phase is not distinguishable from a drag through the public API.
  return NO;
}

- (BOOL)isZooming
{
  return NO;
}

- (BOOL)touchesShouldCancelInContentView:(__unused NSView *)view
{
  return NO;
}

- (BOOL)isFlipped
{
  return YES;
}

@end
