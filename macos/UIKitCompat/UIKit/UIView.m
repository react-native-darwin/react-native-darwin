/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIView.h"

#import <objc/runtime.h>

#pragma mark - NSView (UIKitCompat)

static const void *kUserInteractionEnabledKey = &kUserInteractionEnabledKey;
static const void *kBackgroundColorKey = &kBackgroundColorKey;
static const void *kTransform3DKey = &kTransform3DKey;
static const void *kContentModeKey = &kContentModeKey;

@implementation NSView (UIKitCompat)

- (BOOL)isUserInteractionEnabled
{
  NSNumber *stored = objc_getAssociatedObject(self, kUserInteractionEnabledKey);
  // Default YES, matching UIView.
  return stored == nil ? YES : stored.boolValue;
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
  objc_setAssociatedObject(
      self, kUserInteractionEnabledKey, @(userInteractionEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)alpha
{
  return self.alphaValue;
}

- (void)setAlpha:(CGFloat)alpha
{
  self.alphaValue = alpha;
}

- (UIColor *)backgroundColor
{
  return objc_getAssociatedObject(self, kBackgroundColorKey);
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
  objc_setAssociatedObject(self, kBackgroundColorKey, backgroundColor, OBJC_ASSOCIATION_COPY_NONATOMIC);
  if (backgroundColor != nil) {
    self.wantsLayer = YES;
    self.layer.backgroundColor = backgroundColor.UIKitCompatCGColor;
  } else if (self.layer != nil) {
    self.layer.backgroundColor = NULL;
  }
}

- (CGAffineTransform)transform
{
  return CATransform3DGetAffineTransform(self.transform3D);
}

- (void)setTransform:(CGAffineTransform)transform
{
  self.transform3D = CATransform3DMakeAffineTransform(transform);
}

- (CATransform3D)transform3D
{
  NSValue *stored = objc_getAssociatedObject(self, kTransform3DKey);
  if (stored == nil) {
    return CATransform3DIdentity;
  }
  CATransform3D transform;
  [stored getValue:&transform size:sizeof(transform)];
  return transform;
}

- (void)setTransform3D:(CATransform3D)transform3D
{
  // A layer-backed NSView anchors at {0, 0}; UIView anchors at {0.5, 0.5}.
  // Without this adjustment a rotation would pivot around the corner rather
  // than the centre, which is not what any RN style means.
  self.wantsLayer = YES;
  CGPoint anchorPoint = self.layer.anchorPoint;
  CATransform3D applied = transform3D;
  if (CGPointEqualToPoint(anchorPoint, CGPointZero) && !CATransform3DEqualToTransform(transform3D, CATransform3DIdentity)) {
    CATransform3D originAdjust =
        CATransform3DTranslate(CATransform3DIdentity, self.frame.size.width / 2, self.frame.size.height / 2, 0);
    applied = CATransform3DConcat(CATransform3DConcat(CATransform3DInvert(originAdjust), transform3D), originAdjust);
  }

  objc_setAssociatedObject(
      self,
      kTransform3DKey,
      [NSValue valueWithBytes:&transform3D objCType:@encode(CATransform3D)],
      OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  self.layer.transform = applied;
}

- (CGPoint)center
{
  return CGPointMake(NSMidX(self.frame), NSMidY(self.frame));
}

- (void)setCenter:(CGPoint)center
{
  NSRect frame = self.frame;
  frame.origin.x = center.x - frame.size.width / 2;
  frame.origin.y = center.y - frame.size.height / 2;
  self.frame = frame;
}

- (UIViewContentMode)contentMode
{
  NSNumber *stored = objc_getAssociatedObject(self, kContentModeKey);
  return stored == nil ? UIViewContentModeScaleToFill : (UIViewContentMode)stored.integerValue;
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
  objc_setAssociatedObject(self, kContentModeKey, @(contentMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  if (contentMode == UIViewContentModeRedraw) {
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    return;
  }

  switch (contentMode) {
    case UIViewContentModeScaleToFill:
      self.layerContentsPlacement = NSViewLayerContentsPlacementScaleAxesIndependently;
      break;
    case UIViewContentModeScaleAspectFit:
      self.layerContentsPlacement = NSViewLayerContentsPlacementScaleProportionallyToFit;
      break;
    case UIViewContentModeScaleAspectFill:
      self.layerContentsPlacement = NSViewLayerContentsPlacementScaleProportionallyToFill;
      break;
    case UIViewContentModeCenter:
      self.layerContentsPlacement = NSViewLayerContentsPlacementCenter;
      break;
    case UIViewContentModeTop:
      self.layerContentsPlacement = NSViewLayerContentsPlacementTop;
      break;
    case UIViewContentModeBottom:
      self.layerContentsPlacement = NSViewLayerContentsPlacementBottom;
      break;
    case UIViewContentModeLeft:
      self.layerContentsPlacement = NSViewLayerContentsPlacementLeft;
      break;
    case UIViewContentModeRight:
      self.layerContentsPlacement = NSViewLayerContentsPlacementRight;
      break;
    case UIViewContentModeTopLeft:
      self.layerContentsPlacement = NSViewLayerContentsPlacementTopLeft;
      break;
    case UIViewContentModeTopRight:
      self.layerContentsPlacement = NSViewLayerContentsPlacementTopRight;
      break;
    case UIViewContentModeBottomLeft:
      self.layerContentsPlacement = NSViewLayerContentsPlacementBottomLeft;
      break;
    case UIViewContentModeBottomRight:
      self.layerContentsPlacement = NSViewLayerContentsPlacementBottomRight;
      break;
    case UIViewContentModeRedraw:
      break;
  }
}

- (UIEdgeInsets)safeAreaInsets
{
  // A macOS window has no notch and no home indicator. Full-size content views
  // under a titlebar are the one real case, and RN does not create those.
  return UIEdgeInsetsZero;
}

- (NSArray *)accessibilityElements
{
  return self.accessibilityChildren;
}

- (void)setAccessibilityElements:(NSArray *)accessibilityElements
{
  self.accessibilityChildren = accessibilityElements;
}

- (BOOL)canBecomeFirstResponder
{
  return self.acceptsFirstResponder;
}

- (BOOL)isFirstResponder
{
  return self.window.firstResponder == self;
}

- (BOOL)becomeFirstResponder
{
  return [self.window makeFirstResponder:self];
}

- (void)setNeedsDisplay
{
  self.needsDisplay = YES;
}

- (void)setNeedsLayout
{
  self.needsLayout = YES;
}

- (void)layoutIfNeeded
{
  if (self.needsLayout) {
    [self layoutSubtreeIfNeeded];
  }
}

- (void)layoutSubviews
{
  // No-op. UIView overrides this; plain NSViews have nothing to lay out the
  // React way. Defined so upstream can call it on any view without a guard.
}

- (void)insertSubview:(NSView *)view atIndex:(NSInteger)index
{
  NSArray<__kindof NSView *> *subviews = self.subviews;
  if (index < 0 || (NSUInteger)index >= subviews.count) {
    [self addSubview:view];
  } else {
    [self addSubview:view positioned:NSWindowBelow relativeTo:subviews[(NSUInteger)index]];
  }
}

- (void)bringSubviewToFront:(NSView *)view
{
  if (view.superview != self) {
    return;
  }
  [view removeFromSuperview];
  [self addSubview:view positioned:NSWindowAbove relativeTo:nil];
}

- (void)sendSubviewToBack:(NSView *)view
{
  if (view.superview != self) {
    return;
  }
  [view removeFromSuperview];
  [self addSubview:view positioned:NSWindowBelow relativeTo:nil];
}

- (BOOL)isDescendantOfView:(NSView *)view
{
  return [self isDescendantOf:view];
}

- (NSView *)hitTest:(CGPoint)point withEvent:(__unused UIEvent *)event
{
  if (!self.isUserInteractionEnabled) {
    return nil;
  }
  // -[NSView hitTest:] wants the point in the *superview's* space; UIKit's
  // -hitTest:withEvent: gets it in the receiver's. Convert before delegating.
  NSView *superview = self.superview;
  NSPoint pointInSuperview = superview != nil ? [self convertPoint:NSPointFromCGPoint(point) toView:superview]
                                              : NSPointFromCGPoint(point);
  return [self hitTest:pointInSuperview];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(__unused UIEvent *)event
{
  return self.isUserInteractionEnabled && NSPointInRect(NSPointFromCGPoint(point), self.bounds);
}

- (void)didMoveToWindow
{
  // Bridged from -viewDidMoveToWindow by UIView. No-op for plain NSViews.
}

- (void)didMoveToSuperview
{
  // Bridged from -viewDidMoveToSuperview by UIView. No-op for plain NSViews.
}

@end

#pragma mark - RCTPlatformView

@implementation RCTPlatformView {
  UIColor *_backgroundColor;
  BOOL _respondsToDisplayLayer;
  BOOL _hasCustomTransform3D;
  CATransform3D _transform3D;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
  NSSet<NSString *> *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
  NSString *alternatePath = nil;

  if ([key isEqualToString:@"alpha"]) {
    alternatePath = @"alphaValue";
  } else if ([key isEqualToString:@"isAccessibilityElement"]) {
    alternatePath = @"accessibilityElement";
  }

  if (alternatePath != nil) {
    keyPaths = keyPaths != nil ? [keyPaths setByAddingObject:alternatePath] : [NSSet setWithObject:alternatePath];
  }

  return keyPaths;
}

static RCTPlatformView *RCTPlatformViewCommonInit(RCTPlatformView *self)
{
  if (self != nil) {
    self.wantsLayer = YES;
    self->_enableFocusRing = YES;
    self->_respondsToDisplayLayer = [self respondsToSelector:@selector(displayLayer:)];
    self->_transform3D = CATransform3DIdentity;
    self->_hasCustomTransform3D = NO;
  }
  return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
  return RCTPlatformViewCommonInit([super initWithFrame:frameRect]);
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
  return RCTPlatformViewCommonInit([super initWithCoder:coder]);
}

// UIKit's origin is top-left. Everything React Native computes assumes it.
- (BOOL)isFlipped
{
  return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
  if (_acceptsFirstMouse || [super acceptsFirstMouse:event]) {
    return YES;
  }
  // Honour the flag if any ancestor set it, so a whole subtree can opt in.
  NSView *view = self;
  while ((view = view.superview)) {
    if ([view isKindOfClass:[RCTPlatformView class]] && ((RCTPlatformView *)view).acceptsFirstMouse) {
      return YES;
    }
  }
  return NO;
}

- (void)viewDidMoveToWindow
{
  [super viewDidMoveToWindow];
  [self didMoveToWindow];
}

- (void)viewDidMoveToSuperview
{
  [super viewDidMoveToSuperview];
  [self didMoveToSuperview];
}

- (void)layout
{
  [super layout];
  if (self.window != nil) {
    [self layoutSubviews];
  }
}

- (void)layoutSubviews
{
  // Overridden by React Native's view classes. Deliberately does not call
  // -[super layoutSubviews], which is the category's no-op.
}

- (UIColor *)backgroundColor
{
  return _backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
  if (_backgroundColor != backgroundColor && ![_backgroundColor isEqual:backgroundColor]) {
    _backgroundColor = [backgroundColor copy];
    self.needsDisplay = YES;
  }
}

- (CATransform3D)transform3D
{
  return _transform3D;
}

- (void)setTransform3D:(CATransform3D)transform3D
{
  CGPoint anchorPoint = self.layer.anchorPoint;
  CATransform3D applied = transform3D;
  if (CGPointEqualToPoint(anchorPoint, CGPointZero) && !CATransform3DEqualToTransform(transform3D, CATransform3DIdentity)) {
    CATransform3D originAdjust =
        CATransform3DTranslate(CATransform3DIdentity, self.frame.size.width / 2, self.frame.size.height / 2, 0);
    applied = CATransform3DConcat(CATransform3DConcat(CATransform3DInvert(originAdjust), transform3D), originAdjust);
  }

  _transform3D = transform3D;
  _hasCustomTransform3D = !CATransform3DEqualToTransform(transform3D, CATransform3DIdentity);
  self.layer.transform = applied;
}

- (BOOL)wantsUpdateLayer
{
  return _respondsToDisplayLayer || _hasCustomTransform3D;
}

- (void)updateLayer
{
  CALayer *layer = self.layer;

  // A CGColor is not appearance-aware. When the effective appearance flips
  // between light and dark, the NSColor still resolves correctly but the
  // CGColor we handed the layer does not, so re-derive it here.
  if (_backgroundColor != nil) {
    layer.backgroundColor = _backgroundColor.UIKitCompatCGColor;
  }

  // AppKit resets layer.transform during its own layout pass, because NSView
  // has no transform property of its own to restore from. Re-apply ours.
  if (_hasCustomTransform3D && !CATransform3DEqualToTransform(layer.transform, _transform3D)) {
    layer.transform = _transform3D;
  }

  if (_respondsToDisplayLayer) {
    [(id<CALayerDelegate>)self displayLayer:layer];
  }
}

- (void)drawRect:(CGRect)rect
{
  if (_backgroundColor != nil) {
    [_backgroundColor set];
    NSRectFill(rect);
  }
  [super drawRect:rect];
}

- (NSView *)hitTest:(NSPoint)point
{
  // AppKit calls this with a point in the superview's space. Convert through
  // CALayer rather than -convertPoint:fromView:, which ignores layer.transform
  // and so mis-hits any transformed view.
  CGPoint localPoint = point;
  if (self.layer.superlayer != nil) {
    localPoint = [self.layer convertPoint:point fromLayer:self.layer.superlayer];
  }
  return [self hitTest:localPoint withEvent:nil];
}

- (BOOL)acceptsFirstResponder
{
  return self.canBecomeFirstResponder;
}

@end

#pragma mark - Free functions

NSView *UIViewHitTestWithEvent(NSView *view, CGPoint point, NSView *fromView, __unused UIEvent *event)
{
  NSView *superview = view.superview;
  if (superview == nil) {
    return [view hitTest:NSPointFromCGPoint(point)];
  }
  NSPoint pointInSuperview = [superview.layer convertPoint:point fromLayer:fromView.layer];
  return [view hitTest:pointInSuperview];
}

void UIViewSetContentModeRedraw(NSView *view)
{
  view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;
}

BOOL UIViewIsDescendantOfView(NSView *view, NSView *parent)
{
  return [view isDescendantOf:parent];
}
