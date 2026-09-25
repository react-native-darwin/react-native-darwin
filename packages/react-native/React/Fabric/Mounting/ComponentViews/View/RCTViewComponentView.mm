/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTViewComponentView.h"
#import <React/RCTSurfaceHostingProxyRootView.h>

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <algorithm> // [macOS] std::find, for matching a press against keyDownEvents
#import <objc/runtime.h>
#import <ranges>

#import <RCTSwiftUIWrapper/RCTSwiftUIContainerViewWrapper.h>
#import <React/RCTAssert.h>
#import <React/RCTBackgroundImageUtils.h>
#import <React/RCTBorderDrawing.h>
#import <React/RCTBoxShadow.h>
#import <React/RCTConversions.h>
#import <React/RCTLinearGradient.h>
#import <React/RCTLocalizedString.h>
#import <React/RCTRadialGradient.h>
#if TARGET_OS_OSX // [macOS] drag and drop: RCTDataURL for dragged image data,
                  // UTType to name what was dropped.
#import <React/RCTUtils.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#endif // macOS]
#import <react/featureflags/ReactNativeFeatureFlags.h>
#import <react/renderer/components/view/ViewComponentDescriptor.h>
#import <react/renderer/components/view/ViewEventEmitter.h>
#import <react/renderer/components/view/ViewProps.h>
#import <react/renderer/components/view/accessibilityPropsConversions.h>
#import <react/renderer/graphics/BlendMode.h>

#ifdef RCT_DYNAMIC_FRAMEWORKS
#import <React/RCTComponentViewFactory.h>
#endif

using namespace facebook::react;

const CGFloat BACKGROUND_COLOR_ZPOSITION = -1024.0f;

@implementation RCTViewComponentView {
  UIColor *_backgroundColor;
  CALayer *_backgroundColorLayer;
  __weak CALayer *_borderLayer;
  CALayer *_outlineLayer;
  NSMutableArray<CALayer *> *_boxShadowLayers;
  CALayer *_filterLayer;
  NSMutableArray<CALayer *> *_backgroundImageLayers;
  BOOL _needsInvalidateLayer;
  BOOL _isJSResponder;
  BOOL _removeClippedSubviews;
  NSMutableArray<UIView *> *_reactSubviews;
  NSSet<NSString *> *_Nullable _propKeysManagedByAnimated_DO_NOT_USE_THIS_IS_BROKEN;
  UIView *_containerView;
  BOOL _useCustomContainerView;
  NSMutableSet<NSString *> *_accessibilityOrderNativeIDs;
  RCTSwiftUIContainerViewWrapper *_swiftUIWrapper;
  BOOL _focusable;
#if TARGET_OS_OSX // [macOS
  // AppKit reads these rather than being told them, so they are answered from
  // stored values by the overrides further down.
  BOOL _allowsVibrancy;
  BOOL _mouseDownCanMoveWindow;
  NSTrackingArea *_mouseTrackingArea;
#endif // macOS]
}

#ifdef RCT_DYNAMIC_FRAMEWORKS
+ (void)load
{
  [RCTComponentViewFactory.currentComponentViewFactory registerComponentViewClass:self];
}
#endif

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _props = ViewShadowNode::defaultSharedProps();
    _reactSubviews = [NSMutableArray new];
#if TARGET_OS_OSX // [macOS] mirror HostPlatformViewProps' defaults
    _mouseDownCanMoveWindow = YES;
    _allowsVibrancy = NO;
#endif // macOS]
#if !TARGET_OS_TV
    self.multipleTouchEnabled = YES;
#endif
    _useCustomContainerView = NO;
    _removeClippedSubviews = NO;
  }
  return self;
}

- (facebook::react::Props::Shared)props
{
  return _props;
}

- (void)setContentView:(UIView *)contentView
{
  if (_contentView) {
    [_contentView removeFromSuperview];
  }

  _contentView = contentView;

  if (_contentView) {
    [self.currentContainerView addSubview:_contentView];
    _contentView.frame = RCTCGRectFromRect(_layoutMetrics.getContentFrame());
  }
}

// Rejects hits against views whose 2D transform collapses an axis (e.g. `scaleX: 0`,
// `scaleY: 0`, or any other non-invertible affine). Such views are visually degenerate, and
// UIKit's `-convertPoint:fromView:` falls back to the original matrix when
// `CGAffineTransformInvert` can't invert, so without this check the degenerate transform is
// applied to the touch point and the view can still register hits along the collapsed axis.
static BOOL RCTLayerTransformCollapsesAxis(CALayer *layer)
{
  CATransform3D t = layer.transform;
  // Determinant of the 2x2 projection onto the XY plane. Anything non-zero is invertible; we
  // treat values within float epsilon as zero to avoid numerical issues near machine precision.
  CGFloat det = t.m11 * t.m22 - t.m12 * t.m21;
  return fabs(det) < (CGFloat)1e-6;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
  if (RCTLayerTransformCollapsesAxis(self.layer)) {
    return NO;
  }
  if (UIEdgeInsetsEqualToEdgeInsets(self.hitTestEdgeInsets, UIEdgeInsetsZero)) {
    return [super pointInside:point withEvent:event];
  }
  CGRect hitFrame = UIEdgeInsetsInsetRect(self.bounds, self.hitTestEdgeInsets);
  return CGRectContainsPoint(hitFrame, point);
}

- (UIColor *)backgroundColor
{
  return _backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
  _backgroundColor = backgroundColor;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
    [self invalidateLayer];
  }
}

#pragma mark - RCTComponentViewProtocol

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  RCTAssert(
      self == [RCTViewComponentView class],
      @"`+[RCTComponentViewProtocol componentDescriptorProvider]` must be implemented for all subclasses (and `%@` particularly).",
      NSStringFromClass([self class]));
  return concreteComponentDescriptorProvider<ViewComponentDescriptor>();
}

- (void)mountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index
{
  RCTAssert(
      childComponentView.superview == nil,
      @"Attempt to mount already mounted component view. (parent: %@, child: %@, index: %@, existing parent: %@)",
      self,
      childComponentView,
      @(index),
      @([childComponentView.superview tag]));

  if (_removeClippedSubviews) {
    [_reactSubviews insertObject:childComponentView atIndex:index];
  } else {
    [self.currentContainerView insertSubview:childComponentView atIndex:index];
  }
}

- (void)unmountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index
{
  if (_removeClippedSubviews) {
    [_reactSubviews removeObjectAtIndex:index];
  } else {
    RCTAssert(
        childComponentView.superview != nil,
        @"Attempt to unmount a view which is not mounted. (parent: %@, child: %@, index: %@)",
        self,
        childComponentView,
        @(index));
    RCTAssert(
        childComponentView.superview == self.currentContainerView,
        @"Attempt to unmount a view which is mounted inside a different view. (parent: %@, child: %@, index: %@, existing parent: %@)",
        self,
        childComponentView,
        @(index),
        @([childComponentView.superview tag]));
    RCTAssert(
        (self.currentContainerView.subviews.count > index) &&
            [self.currentContainerView.subviews objectAtIndex:index] == childComponentView,
        @"Attempt to unmount a view which has a different index. (parent: %@, child: %@, index: %@, actual index: %@, tag at index: %@)",
        self,
        childComponentView,
        @(index),
        @([self.currentContainerView.subviews indexOfObject:childComponentView]),
        @([[self.currentContainerView.subviews objectAtIndex:index] tag]));
  }

  [childComponentView removeFromSuperview];
}

- (void)_updateRemoveClippedSubviewsState
{
  if (_removeClippedSubviews) {
    // Toggled ON: populate _reactSubviews from the current view hierarchy.
    // Actual clipping will happen on the next scroll event.
    RCTAssert(
        _reactSubviews.count == 0,
        @"_reactSubviews should be empty when toggling removeClippedSubviews on. (view: %@, count: %@)",
        self,
        @(_reactSubviews.count));
    if (self.currentContainerView.subviews.count > 0) {
      _reactSubviews = [NSMutableArray arrayWithArray:self.currentContainerView.subviews];
    }
  } else {
    // Toggled OFF: re-mount all children in the correct order, then clear the tracking array.
    // addSubview: on an already-present child moves it to the front, so iterating in order
    // produces the correct subview ordering.
    for (UIView *view in _reactSubviews) {
      [self.currentContainerView addSubview:view];
    }
    [_reactSubviews removeAllObjects];
  }
}

- (void)updateClippedSubviewsWithClipRect:(CGRect)clipRect relativeToView:(UIView *)clipView
{
  if (!_removeClippedSubviews) {
    // Use default behavior if unmounting is disabled
    return [super updateClippedSubviewsWithClipRect:clipRect relativeToView:clipView];
  }

  if (_reactSubviews.count == 0) {
    // Do nothing if we have no subviews
    return;
  }

  if (CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
    // Do nothing if layout hasn't happened yet
    return;
  }

  // Convert clipping rect to local coordinates
  clipRect = [clipView convertRect:clipRect toView:self];

  // Mount / unmount views
  for (UIView *view in _reactSubviews) {
    if (CGRectIntersectsRect(clipRect, view.frame)) {
      // View is at least partially visible, so remount it if unmounted
      [self.currentContainerView addSubview:view];
      // View is visible, update clipped subviews
      [view updateClippedSubviewsWithClipRect:clipRect relativeToView:self];
    } else if (view.superview) {
      // View is completely outside the clipRect, so unmount it
      [view removeFromSuperview];
    }
  }
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
  RCTAssert(props, @"`props` must not be `null`.");

#ifndef NS_BLOCK_ASSERTIONS
  auto propsRawPtr = _props.get();
  RCTAssert(
      propsRawPtr &&
          ([self class] == [RCTViewComponentView class] ||
           typeid(*propsRawPtr).hash_code() != typeid(const ViewProps).hash_code()),
      @"`RCTViewComponentView` subclasses (and `%@` particularly) must setup `_props`"
       " instance variable with a default value in the constructor.",
      NSStringFromClass([self class]));
#endif

  const auto &oldViewProps = static_cast<const ViewProps &>(*_props);
  const auto &newViewProps = static_cast<const ViewProps &>(*props);

  BOOL needsInvalidateLayer = NO;

  // `opacity`
  if (oldViewProps.opacity != newViewProps.opacity &&
      ![_propKeysManagedByAnimated_DO_NOT_USE_THIS_IS_BROKEN containsObject:@"opacity"]) {
    self.layer.opacity = (float)newViewProps.opacity;
    needsInvalidateLayer = YES;
  }

  // Disable `removeClippedSubviews` when Fabric View Culling is enabled.
  if (!ReactNativeFeatureFlags::enableViewCulling()) {
    if (oldViewProps.removeClippedSubviews != newViewProps.removeClippedSubviews) {
      _removeClippedSubviews = newViewProps.removeClippedSubviews;
      [self _updateRemoveClippedSubviewsState];
    }
  }

  // `backgroundColor`
  if (oldViewProps.backgroundColor != newViewProps.backgroundColor) {
    self.backgroundColor = RCTUIColorFromSharedColor(newViewProps.backgroundColor);
    needsInvalidateLayer = YES;
  }

  // `shadowColor`
  if (oldViewProps.shadowColor != newViewProps.shadowColor) {
    UIColor *shadowColor = RCTUIColorFromSharedColor(newViewProps.shadowColor);
    self.layer.shadowColor = shadowColor.CGColor;
    needsInvalidateLayer = YES;
  }

  // `shadowOffset`
  if (oldViewProps.shadowOffset != newViewProps.shadowOffset) {
    self.layer.shadowOffset = RCTCGSizeFromSize(newViewProps.shadowOffset);
    needsInvalidateLayer = YES;
  }

  // `shadowOpacity`
  if (oldViewProps.shadowOpacity != newViewProps.shadowOpacity) {
    self.layer.shadowOpacity = (float)newViewProps.shadowOpacity;
    needsInvalidateLayer = YES;
  }

  // `shadowRadius`
  if (oldViewProps.shadowRadius != newViewProps.shadowRadius) {
    self.layer.shadowRadius = (CGFloat)newViewProps.shadowRadius;
    needsInvalidateLayer = YES;
  }

  // `backfaceVisibility`
  if (oldViewProps.backfaceVisibility != newViewProps.backfaceVisibility) {
    self.layer.doubleSided = newViewProps.backfaceVisibility == BackfaceVisibility::Visible;
  }

  // `cursor`
  if (oldViewProps.cursor != newViewProps.cursor) {
    needsInvalidateLayer = YES;
  }

  // `shouldRasterize`
  if (oldViewProps.shouldRasterize != newViewProps.shouldRasterize) {
    self.layer.shouldRasterize = newViewProps.shouldRasterize;
    self.layer.rasterizationScale = newViewProps.shouldRasterize ? self.traitCollection.displayScale : 1.0;
  }

  // `pointerEvents`
  if (oldViewProps.pointerEvents != newViewProps.pointerEvents) {
    self.userInteractionEnabled = newViewProps.pointerEvents != PointerEventsMode::None;
  }

  // `transform`
  if ((oldViewProps.transform != newViewProps.transform ||
       oldViewProps.transformOrigin != newViewProps.transformOrigin) &&
      ![_propKeysManagedByAnimated_DO_NOT_USE_THIS_IS_BROKEN containsObject:@"transform"]) {
    auto newTransform = newViewProps.resolveTransform(_layoutMetrics);
    CATransform3D caTransform = RCTCATransform3DFromTransformMatrix(newTransform);

    self.layer.transform = caTransform;
    // Enable edge antialiasing in rotation, skew, or perspective transforms
    self.layer.allowsEdgeAntialiasing = caTransform.m12 != 0.0f || caTransform.m21 != 0.0f || caTransform.m34 != 0.0f;
  }

  // `hitSlop`
  if (oldViewProps.hitSlop != newViewProps.hitSlop) {
    self.hitTestEdgeInsets = {
        -newViewProps.hitSlop.top,
        -newViewProps.hitSlop.left,
        -newViewProps.hitSlop.bottom,
        -newViewProps.hitSlop.right};
  }

  // `overflow`
  if (oldViewProps.getClipsContentToBounds() != newViewProps.getClipsContentToBounds()) {
    self.currentContainerView.clipsToBounds = newViewProps.getClipsContentToBounds();
    needsInvalidateLayer = YES;
  }

  // `border`
  if (oldViewProps.borderStyles != newViewProps.borderStyles || oldViewProps.borderRadii != newViewProps.borderRadii ||
      oldViewProps.borderColors != newViewProps.borderColors) {
    needsInvalidateLayer = YES;
  }

  // `outline`
  if (oldViewProps.outlineStyle != newViewProps.outlineStyle ||
      oldViewProps.outlineColor != newViewProps.outlineColor ||
      oldViewProps.outlineOffset != newViewProps.outlineOffset ||
      oldViewProps.outlineWidth != newViewProps.outlineWidth) {
    needsInvalidateLayer = YES;
  }

  // `nativeId`
  if (oldViewProps.nativeId != newViewProps.nativeId) {
    self.nativeId = RCTNSStringFromStringNilIfEmpty(newViewProps.nativeId);
  }

  // `accessible`
  if (oldViewProps.accessible != newViewProps.accessible) {
    self.accessibilityElement.isAccessibilityElement = newViewProps.accessible;
  }

  // `accessibilityLabel`
  if (oldViewProps.accessibilityLabel != newViewProps.accessibilityLabel) {
    self.accessibilityElement.accessibilityLabel = RCTNSStringFromStringNilIfEmpty(newViewProps.accessibilityLabel);
  }

  // `accessibilityLanguage`
  if (oldViewProps.accessibilityLanguage != newViewProps.accessibilityLanguage) {
    self.accessibilityElement.accessibilityLanguage =
        RCTNSStringFromStringNilIfEmpty(newViewProps.accessibilityLanguage);
  }

  // `accessibilityHint`
  if (oldViewProps.accessibilityHint != newViewProps.accessibilityHint) {
    self.accessibilityElement.accessibilityHint = RCTNSStringFromStringNilIfEmpty(newViewProps.accessibilityHint);
  }

  // `accessibilityViewIsModal`
  if (oldViewProps.accessibilityViewIsModal != newViewProps.accessibilityViewIsModal) {
    self.accessibilityElement.accessibilityViewIsModal = newViewProps.accessibilityViewIsModal;
  }

  // `accessibilityElementsHidden`
  if (oldViewProps.accessibilityElementsHidden != newViewProps.accessibilityElementsHidden) {
    self.accessibilityElement.accessibilityElementsHidden = newViewProps.accessibilityElementsHidden;
  }

  // `accessibilityShowsLargeContentViewer`
  if (oldViewProps.accessibilityShowsLargeContentViewer != newViewProps.accessibilityShowsLargeContentViewer) {
#if !TARGET_OS_TV
    if (@available(iOS 13.0, *)) {
      if (newViewProps.accessibilityShowsLargeContentViewer) {
        self.showsLargeContentViewer = YES;
        UILargeContentViewerInteraction *interaction = [[UILargeContentViewerInteraction alloc] init];
        [self addInteraction:interaction];
      } else {
        self.showsLargeContentViewer = NO;
      }
    }
#endif
  }

  // `accessibilityLargeContentTitle`
  if (oldViewProps.accessibilityLargeContentTitle != newViewProps.accessibilityLargeContentTitle) {
#if !TARGET_OS_TV
    if (@available(iOS 13.0, *)) {
      self.largeContentTitle = RCTNSStringFromStringNilIfEmpty(newViewProps.accessibilityLargeContentTitle);
    }
#endif
  }

  // `accessibilityOrder`
  if (oldViewProps.accessibilityOrder != newViewProps.accessibilityOrder &&
      ReactNativeFeatureFlags::enableAccessibilityOrder()) {
    // Creating a set since a lot of logic requires lookups in here. However,
    // we still need to preserve the orginal order. So just read from props
    // if need to access that
    _accessibilityOrderNativeIDs = [NSMutableSet new];
    for (const std::string &childId : newViewProps.accessibilityOrder) {
      [_accessibilityOrderNativeIDs addObject:RCTNSStringFromString(childId)];
    }

    // If we are prop updating and have children we can go ahead and assign this prop.
    // Otherwise, we might not have children attached yet and need to wait before then.
    if (self.currentContainerView.subviews.count > 0) {
      [self updateAccessibilityElements];
    }
  }

  // `accessibilityTraits`
  if (oldViewProps.accessibilityTraits != newViewProps.accessibilityTraits) {
    self.accessibilityElement.accessibilityTraits =
        RCTUIAccessibilityTraitsFromAccessibilityTraits(newViewProps.accessibilityTraits);
  }

  // `accessibilityState`
  if (oldViewProps.accessibilityState != newViewProps.accessibilityState) {
    self.accessibilityTraits &= ~(UIAccessibilityTraitNotEnabled | UIAccessibilityTraitSelected);
    const auto accessibilityState = newViewProps.accessibilityState.value_or(AccessibilityState{});
    if (accessibilityState.selected) {
      self.accessibilityTraits |= UIAccessibilityTraitSelected;
    }
    if (accessibilityState.disabled) {
      self.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
    }
  }

  // `accessibilityIgnoresInvertColors`
  if (oldViewProps.accessibilityIgnoresInvertColors != newViewProps.accessibilityIgnoresInvertColors) {
    self.accessibilityIgnoresInvertColors = newViewProps.accessibilityIgnoresInvertColors;
  }

  // `accessibilityValue`
  if (oldViewProps.accessibilityValue != newViewProps.accessibilityValue) {
    if (newViewProps.accessibilityValue.text.has_value()) {
      self.accessibilityElement.accessibilityValue =
          RCTNSStringFromStringNilIfEmpty(newViewProps.accessibilityValue.text.value());
    } else if (
        newViewProps.accessibilityValue.now.has_value() && newViewProps.accessibilityValue.min.has_value() &&
        newViewProps.accessibilityValue.max.has_value()) {
      CGFloat val = (CGFloat)(newViewProps.accessibilityValue.now.value()) /
          (newViewProps.accessibilityValue.max.value() - newViewProps.accessibilityValue.min.value());
      self.accessibilityElement.accessibilityValue =
          [NSNumberFormatter localizedStringFromNumber:@(val) numberStyle:NSNumberFormatterPercentStyle];
      ;
    } else {
      self.accessibilityElement.accessibilityValue = nil;
    }
  }

  if (oldViewProps.accessibilityRespondsToUserInteraction != newViewProps.accessibilityRespondsToUserInteraction) {
    self.accessibilityElement.accessibilityRespondsToUserInteraction =
        newViewProps.accessibilityRespondsToUserInteraction;
  }

  // `testId`
  if (oldViewProps.testId != newViewProps.testId) {
    SEL setAccessibilityIdentifierSelector = @selector(setAccessibilityIdentifier:);
    NSString *identifier = RCTNSStringFromString(newViewProps.testId);
    if ([self.accessibilityElement respondsToSelector:setAccessibilityIdentifierSelector]) {
      UIView *accessibilityView = (UIView *)self.accessibilityElement;
      accessibilityView.accessibilityIdentifier = identifier;
    } else {
      self.accessibilityIdentifier = identifier;
    }
  }

  // `filter`
  if (oldViewProps.filter != newViewProps.filter) {
    needsInvalidateLayer = YES;
  }

  // `focusable`
#if TARGET_OS_TV
  if (oldViewProps.focusable != newViewProps.focusable) {
    _focusable = (bool)newViewProps.focusable;
  }
#endif

  // `mixBlendMode`
  if (oldViewProps.mixBlendMode != newViewProps.mixBlendMode) {
    switch (newViewProps.mixBlendMode) {
      case BlendMode::Multiply:
        self.layer.compositingFilter = @"multiplyBlendMode";
        break;
      case BlendMode::Screen:
        self.layer.compositingFilter = @"screenBlendMode";
        break;
      case BlendMode::Overlay:
        self.layer.compositingFilter = @"overlayBlendMode";
        break;
      case BlendMode::Darken:
        self.layer.compositingFilter = @"darkenBlendMode";
        break;
      case BlendMode::Lighten:
        self.layer.compositingFilter = @"lightenBlendMode";
        break;
      case BlendMode::ColorDodge:
        self.layer.compositingFilter = @"colorDodgeBlendMode";
        break;
      case BlendMode::ColorBurn:
        self.layer.compositingFilter = @"colorBurnBlendMode";
        break;
      case BlendMode::HardLight:
        self.layer.compositingFilter = @"hardLightBlendMode";
        break;
      case BlendMode::SoftLight:
        self.layer.compositingFilter = @"softLightBlendMode";
        break;
      case BlendMode::Difference:
        self.layer.compositingFilter = @"differenceBlendMode";
        break;
      case BlendMode::Exclusion:
        self.layer.compositingFilter = @"exclusionBlendMode";
        break;
      case BlendMode::Hue:
        self.layer.compositingFilter = @"hueBlendMode";
        break;
      case BlendMode::Saturation:
        self.layer.compositingFilter = @"saturationBlendMode";
        break;
      case BlendMode::Color:
        self.layer.compositingFilter = @"colorBlendMode";
        break;
      case BlendMode::Luminosity:
        self.layer.compositingFilter = @"luminosityBlendMode";
        break;
      case BlendMode::PlusLighter:
        self.layer.compositingFilter = @"linearDodgeBlendMode";
        break;
      case BlendMode::Normal:
        self.layer.compositingFilter = nil;
        break;
    }
  }

  // `backgroundImage`
  if (oldViewProps.backgroundImage != newViewProps.backgroundImage ||
      oldViewProps.backgroundPosition != newViewProps.backgroundPosition ||
      oldViewProps.backgroundRepeat != newViewProps.backgroundRepeat ||
      oldViewProps.backgroundSize != newViewProps.backgroundSize) {
    needsInvalidateLayer = YES;
  }

  // `boxShadow`
  if (oldViewProps.boxShadow != newViewProps.boxShadow) {
    needsInvalidateLayer = YES;
  }

  _needsInvalidateLayer = _needsInvalidateLayer || needsInvalidateLayer;

#if TARGET_OS_OSX // [macOS
  [self _updateMacOSProps:oldViewProps newProps:newViewProps];
#endif // macOS]

  _props = std::static_pointer_cast<const ViewProps>(props);
}

#if TARGET_OS_OSX // [macOS
/**
 * The props AppKit has and UIKit does not. They are declared in
 * HostPlatformViewProps, so `ViewProps` already carries them on this platform.
 */
- (void)_updateMacOSProps:(const ViewProps &)oldViewProps newProps:(const ViewProps &)newViewProps
{
  if (oldViewProps.tooltip != newViewProps.tooltip) {
    self.toolTip = newViewProps.tooltip.has_value() ? RCTNSStringFromString(*newViewProps.tooltip) : nil;
  }

  if (oldViewProps.acceptsFirstMouse != newViewProps.acceptsFirstMouse) {
    self.acceptsFirstMouse = newViewProps.acceptsFirstMouse;
  }

  if (oldViewProps.mouseDownCanMoveWindow != newViewProps.mouseDownCanMoveWindow) {
    _mouseDownCanMoveWindow = newViewProps.mouseDownCanMoveWindow;
  }

  if (oldViewProps.enableFocusRing != newViewProps.enableFocusRing) {
    self.enableFocusRing = newViewProps.enableFocusRing;
  }

  // -allowsVibrancy and -canBecomeKeyView are read by AppKit rather than set,
  // so the values are stored and the overrides below answer from them.
  if (oldViewProps.allowsVibrancy != newViewProps.allowsVibrancy) {
    _allowsVibrancy = newViewProps.allowsVibrancy;
    self.needsDisplay = YES;
  }

  if (oldViewProps.focusable != newViewProps.focusable) {
    _focusable = newViewProps.focusable;
  }

  if (oldViewProps.hostPlatformEvents != newViewProps.hostPlatformEvents) {
    [self _updateMouseTracking:newViewProps.hostPlatformEvents.wantsMouseTracking()];
  }

  if (oldViewProps.draggedTypes != newViewProps.draggedTypes) {
    [self _updateDraggedTypes:newViewProps.draggedTypes];
  }
}

/**
 * AppKit delivers a drag only to views that registered for one of the
 * pasteboard types it carries, so without this the drag handlers are
 * unreachable. The three names are the kinds React Native models; each maps to
 * the pasteboard types AppKit actually uses for it.
 */
- (void)_updateDraggedTypes:(const std::vector<std::string> &)draggedTypes
{
  [self unregisterDraggedTypes];

  if (draggedTypes.empty()) {
    return;
  }

  NSMutableArray<NSPasteboardType> *types = [NSMutableArray arrayWithCapacity:draggedTypes.size()];
  for (const auto &draggedType : draggedTypes) {
    if (draggedType == "fileUrl") {
      [types addObject:NSPasteboardTypeFileURL];
    } else if (draggedType == "image") {
      [types addObject:NSPasteboardTypePNG];
      [types addObject:NSPasteboardTypeTIFF];
    } else if (draggedType == "string") {
      [types addObject:NSPasteboardTypeString];
    }
  }
  [self registerForDraggedTypes:types];
}

/**
 * A view only tracks the mouse while something is listening. Tracking every
 * view would cost a dispatch per view per mouse move.
 */
- (void)_updateMouseTracking:(BOOL)wanted
{
  if (wanted == (_mouseTrackingArea != nil)) {
    return;
  }

  if (!wanted) {
    [self removeTrackingArea:_mouseTrackingArea];
    _mouseTrackingArea = nil;
    return;
  }

  _mouseTrackingArea = [[NSTrackingArea alloc]
      initWithRect:NSZeroRect
           options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect
             owner:self
          userInfo:nil];
  [self addTrackingArea:_mouseTrackingArea];
}

- (HostPlatformViewEventEmitter::MouseEvent)_mouseEventFromNSEvent:(NSEvent *)event
{
  NSPoint inWindow = event.locationInWindow;
  NSPoint inView = [self convertPoint:inWindow fromView:nil];
  NSPoint onScreen = self.window != nil ? [self.window convertPointToScreen:inWindow] : inWindow;

  HostPlatformViewEventEmitter::MouseEvent mouseEvent = {};
  mouseEvent.clientX = inView.x;
  mouseEvent.clientY = inView.y;
  mouseEvent.pageX = inWindow.x;
  mouseEvent.pageY = inWindow.y;
  mouseEvent.screenX = onScreen.x;
  mouseEvent.screenY = onScreen.y;
  return mouseEvent;
}

- (void)mouseEntered:(NSEvent *)event
{
  [super mouseEntered:event];
  if (_eventEmitter != nullptr) {
    _eventEmitter->onMouseEnter([self _mouseEventFromNSEvent:event]);
  }
}

- (void)mouseExited:(NSEvent *)event
{
  [super mouseExited:event];
  if (_eventEmitter != nullptr) {
    _eventEmitter->onMouseLeave([self _mouseEventFromNSEvent:event]);
  }
}

- (void)mouseUp:(NSEvent *)event
{
  [super mouseUp:event];
  const auto &viewProps = static_cast<const ViewProps &>(*_props);
  if (_eventEmitter != nullptr && event.clickCount == 2 &&
      viewProps.hostPlatformEvents[HostPlatformViewEvents::Offset::DoubleClick]) {
    _eventEmitter->onDoubleClick([self _mouseEventFromNSEvent:event]);
  }
}

- (void)rightMouseUp:(NSEvent *)event
{
  [super rightMouseUp:event];
  const auto &viewProps = static_cast<const ViewProps &>(*_props);
  if (_eventEmitter != nullptr && viewProps.hostPlatformEvents[HostPlatformViewEvents::Offset::AuxClick]) {
    _eventEmitter->onAuxClick([self _mouseEventFromNSEvent:event]);
  }
}

#pragma mark - Drag and Drop Events

/**
 * The pasteboard, shaped like the DOM DataTransfer so a drop handler reads the
 * same on macOS as on the web.
 *
 * Dragged files are reported by path. Dragged image *data* -- an image dragged
 * out of a browser, say, with no file behind it -- has no path to give, so it
 * is reported as a data: URL instead; `uri` is what a consumer feeds to
 * <Image> either way.
 */
- (DataTransfer)_dataTransferForPasteboard:(NSPasteboard *)pasteboard
{
  DataTransfer dataTransfer{};

  NSArray<NSURL *> *fileURLs = [pasteboard readObjectsForClasses:@[ [NSURL class] ]
                                                         options:@{NSPasteboardURLReadingFileURLsOnlyKey : @YES}]
      ?: @[];

  for (NSURL *fileURL in fileURLs) {
    BOOL isDirectory = NO;
    if (![NSFileManager.defaultManager fileExistsAtPath:fileURL.path isDirectory:&isDirectory] || isDirectory) {
      continue;
    }

    UTType *type = [UTType typeWithFilenameExtension:fileURL.pathExtension];
    NSString *mimeType = type.preferredMIMEType;
    std::string typeString = mimeType != nil ? mimeType.UTF8String : "";

    DataTransferFile file = {
        .name = fileURL.lastPathComponent != nil ? fileURL.lastPathComponent.UTF8String : "",
        .type = typeString,
        .uri = fileURL.path != nil ? fileURL.path.UTF8String : "",
    };

    NSNumber *fileSize = nil;
    if ([fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL]) {
      file.size = fileSize.intValue;
    }

    if ([mimeType hasPrefix:@"image/"]) {
      NSImage *image = [[NSImage alloc] initWithContentsOfURL:fileURL];
      CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
      if (cgImage != NULL) {
        file.width = static_cast<int>(CGImageGetWidth(cgImage));
        file.height = static_cast<int>(CGImageGetHeight(cgImage));
      }
    }

    dataTransfer.files.push_back(file);
    dataTransfer.items.push_back({.kind = "file", .type = typeString});
    dataTransfer.types.push_back(typeString);
  }

  NSPasteboardType imageType = [pasteboard availableTypeFromArray:@[ NSPasteboardTypePNG, NSPasteboardTypeTIFF ]];
  if (imageType != nil && fileURLs.count == 0) {
    NSString *mimeType = [imageType isEqualToString:NSPasteboardTypePNG] ? UTTypePNG.preferredMIMEType
                                                                        : UTTypeTIFF.preferredMIMEType;
    NSData *imageData = [pasteboard dataForType:imageType];
    std::string typeString = mimeType != nil ? mimeType.UTF8String : "";

    NSString *dataURL = RCTDataURL(mimeType, imageData).absoluteString;
    DataTransferFile file = {
        .name = "",
        .type = typeString,
        .uri = dataURL != nil ? dataURL.UTF8String : "",
    };
    file.size = static_cast<int>(imageData.length);

    NSImage *image = [[NSImage alloc] initWithData:imageData];
    CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
    if (cgImage != NULL) {
      file.width = static_cast<int>(CGImageGetWidth(cgImage));
      file.height = static_cast<int>(CGImageGetHeight(cgImage));
    }

    dataTransfer.files.push_back(file);
    dataTransfer.items.push_back({.kind = "image", .type = typeString});
    dataTransfer.types.push_back(typeString);
  }

  return dataTransfer;
}

- (DragEvent)_dragEventFromDraggingInfo:(id<NSDraggingInfo>)info
{
  NSPoint inWindow = info.draggingLocation;
  NSPoint inView = [self convertPoint:inWindow fromView:nil];
  NSEventModifierFlags flags = self.window.currentEvent.modifierFlags;

  DragEvent event = {};
  event.clientX = inView.x;
  event.clientY = inView.y;
  event.pageX = inWindow.x;
  event.pageY = inWindow.y;
  event.screenX = inWindow.x;
  event.screenY = inWindow.y;
  event.altKey = static_cast<bool>(flags & NSEventModifierFlagOption);
  event.ctrlKey = static_cast<bool>(flags & NSEventModifierFlagControl);
  event.shiftKey = static_cast<bool>(flags & NSEventModifierFlagShift);
  event.metaKey = static_cast<bool>(flags & NSEventModifierFlagCommand);
  event.dataTransfer = [self _dataTransferForPasteboard:info.draggingPasteboard];
  return event;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
  if (_eventEmitter != nullptr) {
    _eventEmitter->onDragEnter([self _dragEventFromDraggingInfo:sender]);
  }

  // The answer is the cursor the user sees, so it has to reflect what this view
  // would actually accept -- claiming a drag the pasteboard cannot satisfy shows
  // a drop cursor over content that will refuse it.
  if ([sender.draggingPasteboard availableTypeFromArray:self.registeredDraggedTypes] == nil) {
    return NSDragOperationNone;
  }

  NSDragOperation offered = sender.draggingSourceOperationMask;
  if (offered & NSDragOperationLink) {
    return NSDragOperationLink;
  }
  if (offered & NSDragOperationCopy) {
    return NSDragOperationCopy;
  }
  return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
  if (_eventEmitter != nullptr) {
    _eventEmitter->onDragLeave([self _dragEventFromDraggingInfo:sender]);
  }
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
  if (_eventEmitter == nullptr) {
    return NO;
  }
  _eventEmitter->onDrop([self _dragEventFromDraggingInfo:sender]);
  return YES;
}

#pragma mark - Keyboard Events

/**
 * The W3C `key` name for a press, per https://www.w3.org/TR/uievents-key/.
 *
 * `charactersIgnoringModifiers` already gives the right answer for anything
 * printable. The cases below are the ones where it gives a private-use unichar
 * (the arrows, the function keys) or a control character (Return, Delete)
 * instead of a name. Tab and Escape are matched on keyCode rather than
 * character because AppKit reports them as \t and \e, which would otherwise
 * arrive as those literal characters.
 *
 * Naming follows the cross-platform reconciliation react-native-windows and
 * react-native-macos both use, so a key handler is portable between them.
 */
static NSString *RCTKeyFromNSEvent(NSEvent *event)
{
  NSString *characters = event.charactersIgnoringModifiers;
  unichar code = characters.length > 0 ? [characters characterAtIndex:0] : 0;

  switch (event.keyCode) {
    case 48:
      return @"Tab";
    case 53:
      return @"Escape";
    default:
      break;
  }

  switch (code) {
    case NSEnterCharacter:
    case NSNewlineCharacter:
    case NSCarriageReturnCharacter:
      return @"Enter";
    case NSLeftArrowFunctionKey:
      return @"ArrowLeft";
    case NSRightArrowFunctionKey:
      return @"ArrowRight";
    case NSUpArrowFunctionKey:
      return @"ArrowUp";
    case NSDownArrowFunctionKey:
      return @"ArrowDown";
    case NSBackspaceCharacter:
    case NSDeleteCharacter:
      return @"Backspace";
    case NSDeleteFunctionKey:
      return @"Delete";
    case NSHomeFunctionKey:
      return @"Home";
    case NSEndFunctionKey:
      return @"End";
    case NSPageUpFunctionKey:
      return @"PageUp";
    case NSPageDownFunctionKey:
      return @"PageDown";
    default:
      break;
  }

  if (code >= NSF1FunctionKey && code <= NSF12FunctionKey) {
    return [NSString stringWithFormat:@"F%u", (unsigned)(code - NSF1FunctionKey + 1)];
  }

  return characters;
}

/**
 * Emits the press and reports whether the view claimed it.
 *
 * Claiming matters because AppKit interprets an unclaimed key itself once the
 * responder chain is done with it: Tab moves focus, Escape cancels, anything
 * else beeps. A view says which keys it means to act on through `keyDownEvents`
 * / `keyUpEvents`, and only those suppress the default behaviour. Listening via
 * `onKeyDown` alone deliberately does not, so observing a key does not change
 * what it does.
 */
- (BOOL)handleKeyboardEvent:(NSEvent *)event
{
  NSEventModifierFlags flags = event.modifierFlags;
  KeyEvent keyEvent = {
      .key = RCTStringFromNSString(RCTKeyFromNSEvent(event)),
      .altKey = static_cast<bool>(flags & NSEventModifierFlagOption),
      .ctrlKey = static_cast<bool>(flags & NSEventModifierFlagControl),
      .shiftKey = static_cast<bool>(flags & NSEventModifierFlagShift),
      .metaKey = static_cast<bool>(flags & NSEventModifierFlagCommand),
      .capsLockKey = static_cast<bool>(flags & NSEventModifierFlagCapsLock),
      .numericPadKey = static_cast<bool>(flags & NSEventModifierFlagNumericPad),
      .helpKey = static_cast<bool>(flags & NSEventModifierFlagHelp),
      .functionKey = static_cast<bool>(flags & NSEventModifierFlagFunction),
  };

  BOOL isKeyDown = event.type == NSEventTypeKeyDown;
  const auto &viewProps = static_cast<const ViewProps &>(*_props);

  // Calling super walks the responder chain, which is the view hierarchy, so
  // every ancestor view would emit the same press. Fabric bubbles the event
  // through the shadow tree on its own, so only the innermost view should emit.
  // The flag rides on the NSEvent because that is the one object the whole
  // chain shares.
  static const char kEmittedKey = 0;
  if (_eventEmitter != nullptr && !((NSNumber *)objc_getAssociatedObject(event, &kEmittedKey)).boolValue) {
    if (isKeyDown) {
      _eventEmitter->onKeyDown(keyEvent);
    } else {
      _eventEmitter->onKeyUp(keyEvent);
    }
    objc_setAssociatedObject(event, &kEmittedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  const auto &handled = isKeyDown ? viewProps.keyDownEvents : viewProps.keyUpEvents;
  return std::find(handled.cbegin(), handled.cend(), keyEvent) != handled.cend();
}

- (void)keyDown:(NSEvent *)event
{
  if (![self handleKeyboardEvent:event]) {
    [super keyDown:event];
  }
}

- (void)keyUp:(NSEvent *)event
{
  if (![self handleKeyboardEvent:event]) {
    [super keyUp:event];
  }
}

- (BOOL)allowsVibrancy
{
  return _allowsVibrancy;
}

- (BOOL)mouseDownCanMoveWindow
{
  return _mouseDownCanMoveWindow;
}

- (BOOL)canBecomeKeyView
{
  return _focusable;
}

- (BOOL)acceptsFirstResponder
{
  return _focusable || [super acceptsFirstResponder];
}
#endif // macOS]

- (void)updateEventEmitter:(const EventEmitter::Shared &)eventEmitter
{
  assert(std::dynamic_pointer_cast<const ViewEventEmitter>(eventEmitter));
  _eventEmitter = std::static_pointer_cast<const ViewEventEmitter>(eventEmitter);
}

- (void)updateLayoutMetrics:(const LayoutMetrics &)layoutMetrics
           oldLayoutMetrics:(const LayoutMetrics &)oldLayoutMetrics
{
  // Using stored `_layoutMetrics` as `oldLayoutMetrics` here to avoid
  // re-applying individual sub-values which weren't changed.
  [super updateLayoutMetrics:layoutMetrics oldLayoutMetrics:_layoutMetrics];

  // Capture the frame size that was used by updateProps to resolve the
  // transform, before overwriting _layoutMetrics. This is important because
  // _layoutMetrics may be stale (e.g., from a recycled view) and differ from
  // the oldLayoutMetrics parameter (which comes from the shadow tree).
  auto previousFrameSize = _layoutMetrics.frame.size;

  _layoutMetrics = layoutMetrics;
  _needsInvalidateLayer = YES;

  _borderLayer.frame = self.layer.bounds;

  if (_contentView) {
    _contentView.frame = RCTCGRectFromRect(_layoutMetrics.getContentFrame());
  }

  if (_containerView) {
    _containerView.frame = CGRectMake(0, 0, self.layer.bounds.size.width, self.layer.bounds.size.height);
  }

  if (_backgroundColorLayer) {
    _backgroundColorLayer.frame = CGRectMake(0, 0, self.layer.bounds.size.width, self.layer.bounds.size.height);
  }

  // Recompute the transform whenever the layout size differs from what was
  // used in updateProps. Using previousFrameSize (the stored _layoutMetrics)
  // instead of the oldLayoutMetrics parameter ensures correctness even when
  // the view was recycled with stale dimensions.
  if ((_props->transformOrigin.isSet() || !_props->transform.operations.empty()) &&
      layoutMetrics.frame.size != previousFrameSize) {
    auto newTransform = _props->resolveTransform(layoutMetrics);
    self.layer.transform = RCTCATransform3DFromTransformMatrix(newTransform);
  }

  if (_swiftUIWrapper != nullptr) {
    [_swiftUIWrapper updateLayoutWithBounds:self.bounds];
  }
}

- (BOOL)isJSResponder
{
  return _isJSResponder;
}

- (void)setIsJSResponder:(BOOL)isJSResponder
{
  _isJSResponder = isJSResponder;
}

- (void)finalizeUpdates:(RNComponentViewUpdateMask)updateMask
{
  [super finalizeUpdates:updateMask];
  _useCustomContainerView = [self styleWouldClipOverflowInk];
  if (!_needsInvalidateLayer) {
    return;
  }

  _needsInvalidateLayer = NO;
  [self invalidateLayer];
}

- (void)prepareForRecycle
{
  [super prepareForRecycle];

  // If view was managed by animated, its props need to align with UIView's properties.
  const auto &props = static_cast<const ViewProps &>(*_props);
  if ([_propKeysManagedByAnimated_DO_NOT_USE_THIS_IS_BROKEN containsObject:@"transform"]) {
    self.layer.transform = RCTCATransform3DFromTransformMatrix(props.transform);
  }
  if ([_propKeysManagedByAnimated_DO_NOT_USE_THIS_IS_BROKEN containsObject:@"opacity"]) {
    self.layer.opacity = (float)props.opacity;
  }

  // Clean up box shadow layers to prevent cross-component contamination
  if (_boxShadowLayers != nullptr) {
    for (CALayer *boxShadowLayer = nullptr in _boxShadowLayers) {
      [boxShadowLayer removeFromSuperlayer];
    }
    [_boxShadowLayers removeAllObjects];
    _boxShadowLayers = nil;
  }

  // Clean up other visual layers
  [_backgroundColorLayer removeFromSuperlayer];
  _backgroundColorLayer = nil;
  [_borderLayer removeFromSuperlayer];
  _borderLayer = nil;
  [_outlineLayer removeFromSuperlayer];
  _outlineLayer = nil;
  [_filterLayer removeFromSuperlayer];
  _filterLayer = nil;
  [self clearExistingBackgroundImageLayers];

  _propKeysManagedByAnimated_DO_NOT_USE_THIS_IS_BROKEN = nil;
  _eventEmitter.reset();
  _isJSResponder = NO;
  _removeClippedSubviews = NO;
  _reactSubviews = [NSMutableArray new];
  _layoutMetrics = {};
}

- (void)setPropKeysManagedByAnimated_DO_NOT_USE_THIS_IS_BROKEN:(NSSet<NSString *> *_Nullable)props
{
  _propKeysManagedByAnimated_DO_NOT_USE_THIS_IS_BROKEN = props;
}

- (NSSet<NSString *> *_Nullable)propKeysManagedByAnimated_DO_NOT_USE_THIS_IS_BROKEN
{
  return _propKeysManagedByAnimated_DO_NOT_USE_THIS_IS_BROKEN;
}

- (UIView *)betterHitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  // This is a classic textbook implementation of `hitTest:` with a couple of improvements:
  //   * It does not stop algorithm if some touch is outside the view
  //     which does not have `clipToBounds` enabled.
  //   * Taking `layer.zIndex` field into an account is not required because
  //     lists of `ShadowView`s are already sorted based on `zIndex` prop.

  if (!self.userInteractionEnabled || self.hidden || self.alpha < 0.01) {
    return nil;
  }

  BOOL isPointInside = [self pointInside:point withEvent:event];

  UIView *currentContainerView = self.currentContainerView;

  BOOL clipsToBounds = currentContainerView.clipsToBounds;

  clipsToBounds = clipsToBounds || _layoutMetrics.overflowInset == EdgeInsets{};

  if (clipsToBounds && !isPointInside) {
    return nil;
  }

  for (UIView *subview = nullptr in [currentContainerView.subviews reverseObjectEnumerator]) {
    UIView *hitView = [subview hitTest:[subview convertPoint:point fromView:currentContainerView] withEvent:event];
    if (hitView) {
      return hitView;
    }
  }

  return isPointInside ? self : nil;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  switch (_props->pointerEvents) {
    case PointerEventsMode::Auto:
      return [self betterHitTest:point withEvent:event];
    case PointerEventsMode::None:
      return nil;
    case PointerEventsMode::BoxOnly:
      return [self pointInside:point withEvent:event] ? self : nil;
    case PointerEventsMode::BoxNone:
      UIView *view = [self betterHitTest:point withEvent:event];
      return view != self ? view : nil;
  }
}

static RCTCornerRadii RCTCornerRadiiFromBorderRadii(BorderRadii borderRadii)
{
  return RCTCornerRadii{
      .topLeftHorizontal = (CGFloat)borderRadii.topLeft.horizontal,
      .topLeftVertical = (CGFloat)borderRadii.topLeft.vertical,
      .topRightHorizontal = (CGFloat)borderRadii.topRight.horizontal,
      .topRightVertical = (CGFloat)borderRadii.topRight.vertical,
      .bottomLeftHorizontal = (CGFloat)borderRadii.bottomLeft.horizontal,
      .bottomLeftVertical = (CGFloat)borderRadii.bottomLeft.vertical,
      .bottomRightHorizontal = (CGFloat)borderRadii.bottomRight.horizontal,
      .bottomRightVertical = (CGFloat)borderRadii.bottomRight.vertical};
}

static RCTCornerRadii
RCTCreateOutlineCornerRadiiFromBorderRadii(const BorderRadii &borderRadii, CGFloat outlineWidth, CGFloat outlineOffset)
{
  return RCTCornerRadii{
      borderRadii.topLeft.horizontal != 0 ? borderRadii.topLeft.horizontal + outlineWidth + outlineOffset : 0,
      borderRadii.topLeft.vertical != 0 ? borderRadii.topLeft.vertical + outlineWidth + outlineOffset : 0,
      borderRadii.topRight.horizontal != 0 ? borderRadii.topRight.horizontal + outlineWidth + outlineOffset : 0,
      borderRadii.topRight.vertical != 0 ? borderRadii.topRight.vertical + outlineWidth + outlineOffset : 0,
      borderRadii.bottomLeft.horizontal != 0 ? borderRadii.bottomLeft.horizontal + outlineWidth + outlineOffset : 0,
      borderRadii.bottomLeft.vertical != 0 ? borderRadii.bottomLeft.vertical + outlineWidth + outlineOffset : 0,
      borderRadii.bottomRight.horizontal != 0 ? borderRadii.bottomRight.horizontal + outlineWidth + outlineOffset : 0,
      borderRadii.bottomRight.vertical != 0 ? borderRadii.bottomRight.vertical + outlineWidth + outlineOffset : 0};
}

// To be used for CSS properties like `border` and `outline`.
static void RCTAddContourEffectToLayer(
    CALayer *layer,
    const RCTCornerRadii &cornerRadii,
    const RCTBorderColors &contourColors,
    const UIEdgeInsets &contourInsets,
    const RCTBorderStyle &contourStyle)
{
  UIImage *image = RCTGetBorderImage(
      contourStyle, layer.bounds.size, cornerRadii, contourInsets, contourColors, [UIColor clearColor], NO);

  if (image == nil) {
    layer.contents = nil;
  } else {
    CGSize imageSize = image.size;
    UIEdgeInsets imageCapInsets = image.capInsets;
    CGRect contentsCenter = CGRect{
        CGPoint{imageCapInsets.left / imageSize.width, imageCapInsets.top / imageSize.height},
        CGSize{(CGFloat)1.0 / imageSize.width, (CGFloat)1.0 / imageSize.height}};
    layer.contents = (id)image.CGImage;
    layer.contentsScale = image.scale;

    BOOL isResizable = !UIEdgeInsetsEqualToEdgeInsets(image.capInsets, UIEdgeInsetsZero);
    if (isResizable) {
      layer.contentsCenter = contentsCenter;
    } else {
      layer.contentsCenter = CGRect{CGPoint{0.0, 0.0}, CGSize{1.0, 1.0}};
    }
  }

  // If mutations are applied inside of Animation block, it may cause layer to be animated.
  // To stop that, imperatively remove all animations from layer.
  [layer removeAllAnimations];
}

static RCTBorderColors RCTCreateRCTBorderColorsFromBorderColors(BorderColors borderColors)
{
  return RCTBorderColors{
      .top = RCTUIColorFromSharedColor(borderColors.top),
      .left = RCTUIColorFromSharedColor(borderColors.left),
      .bottom = RCTUIColorFromSharedColor(borderColors.bottom),
      .right = RCTUIColorFromSharedColor(borderColors.right)};
}

static CALayerCornerCurve CornerCurveFromBorderCurve(BorderCurve borderCurve)
{
  // The constants are available only starting from iOS 13
  // CALayerCornerCurve is a typealias on NSString *
  switch (borderCurve) {
    case BorderCurve::Continuous:
      return @"continuous"; // kCACornerCurveContinuous;
    case BorderCurve::Circular:
      return @"circular"; // kCACornerCurveCircular;
  }
}

static RCTBorderStyle RCTBorderStyleFromBorderStyle(BorderStyle borderStyle)
{
  switch (borderStyle) {
    case BorderStyle::Solid:
      return RCTBorderStyleSolid;
    case BorderStyle::Dotted:
      return RCTBorderStyleDotted;
    case BorderStyle::Dashed:
      return RCTBorderStyleDashed;
  }
}

static RCTBorderStyle RCTBorderStyleFromOutlineStyle(OutlineStyle outlineStyle)
{
  switch (outlineStyle) {
    case OutlineStyle::Solid:
      return RCTBorderStyleSolid;
    case OutlineStyle::Dotted:
      return RCTBorderStyleDotted;
    case OutlineStyle::Dashed:
      return RCTBorderStyleDashed;
  }
}

- (BOOL)styleWouldClipOverflowInk
{
  const auto borderMetrics = _props->resolveBorderMetrics(_layoutMetrics);
  BOOL nonZeroBorderWidth = !(borderMetrics.borderWidths.isUniform() && borderMetrics.borderWidths.left == 0);
  BOOL clipToPaddingBox = ReactNativeFeatureFlags::enableIOSViewClipToPaddingBox();
  return _props->getClipsContentToBounds() &&
      ((!_props->boxShadow.empty() || (clipToPaddingBox && nonZeroBorderWidth)) || _props->outlineWidth != 0);
}

// The view that is used as the receiver for all styling (borders, background,
// etc.). Most of the time, this is just `self`. When a view has a filter like
// `blur` applied, we need to wrap it in a SwiftUI view to render the effect.
// In this case, `effectiveContentView` will be the content view inside the
// SwiftUI wrapper.
- (UIView *)effectiveContentView
{
  if (!ReactNativeFeatureFlags::enableSwiftUIBasedFilters()) {
    return self;
  }

  UIView *effectiveContentView = self;

  if (self.styleNeedsSwiftUIContainer) {
    if (_swiftUIWrapper == nullptr) {
      _swiftUIWrapper = [RCTSwiftUIContainerViewWrapper new];
      UIView *swiftUIContentView = [[RCTUIView alloc] init];  // [macOS] needs a flipped, layer-backed view
      for (UIView *subview = nullptr in self.subviews) {
        [swiftUIContentView addSubview:subview];
      }
      swiftUIContentView.clipsToBounds = self.clipsToBounds;
      self.clipsToBounds = NO;
      swiftUIContentView.layer.mask = self.layer.mask;
      self.layer.mask = nil;
      [_swiftUIWrapper updateContentView:swiftUIContentView];
      [_swiftUIWrapper updateLayoutWithBounds:self.bounds];
      [self addSubview:_swiftUIWrapper.hostingView];

      [self transferVisualPropertiesFromView:self toView:swiftUIContentView];
    }

    effectiveContentView = _swiftUIWrapper.contentView;
  } else {
    if (_swiftUIWrapper != nullptr) {
      UIView *swiftUIContentView = _swiftUIWrapper.contentView;
      for (UIView *subview = nullptr in swiftUIContentView.subviews) {
        [self addSubview:subview];
      }
      self.clipsToBounds = swiftUIContentView.clipsToBounds;
      self.layer.mask = swiftUIContentView.layer.mask;

      [self transferVisualPropertiesFromView:swiftUIContentView toView:self];

      [_swiftUIWrapper.hostingView removeFromSuperview];
      _swiftUIWrapper = nil;
    }
  }

  return effectiveContentView;
}

// This UIView is the UIView that holds all subviews. It is sometimes not self
// because we want to render "overflow ink" that extends beyond the bounds of
// the view and is not affected by clipping.
- (UIView *)currentContainerView
{
  UIView *effectiveContentView = self.effectiveContentView;

  if (_useCustomContainerView) {
    if (!_containerView) {
      _containerView = [[RCTUIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];  // [macOS] needs a flipped, layer-backed view
      for (UIView *subview = nullptr in effectiveContentView.subviews) {
        [_containerView addSubview:subview];
      }
      _containerView.clipsToBounds = effectiveContentView.clipsToBounds;
      effectiveContentView.clipsToBounds = NO;
      _containerView.layer.mask = effectiveContentView.layer.mask;
      effectiveContentView.layer.mask = nil;
      [effectiveContentView addSubview:_containerView];
    }

    effectiveContentView = _containerView;
  } else {
    if (_containerView) {
      for (UIView *subview in _containerView.subviews) {
        [effectiveContentView addSubview:subview];
      }
      effectiveContentView.clipsToBounds = _containerView.clipsToBounds;
      effectiveContentView.layer.mask = _containerView.layer.mask;
      [_containerView removeFromSuperview];
      _containerView = nil;
    }
  }
  return effectiveContentView;
}

- (void)invalidateLayer
{
  CALayer *layer = self.effectiveContentView.layer;

  if (CGSizeEqualToSize(layer.bounds.size, CGSizeZero)) {
    return;
  }

  const auto borderMetrics = _props->resolveBorderMetrics(_layoutMetrics);

  // Stage 1. Shadow Path
  BOOL const layerHasShadow = layer.shadowOpacity > 0 && CGColorGetAlpha(layer.shadowColor) > 0;
  if (layerHasShadow) {
    if (CGColorGetAlpha(_backgroundColor.CGColor) > 0.999) {
      // If view has a solid background color, calculate shadow path from border.
      const RCTCornerInsets cornerInsets =
          RCTGetCornerInsets(RCTCornerRadiiFromBorderRadii(borderMetrics.borderRadii), UIEdgeInsetsZero);
      CGPathRef shadowPath = RCTPathCreateWithRoundedRect(self.bounds, cornerInsets, nil, NO);
      layer.shadowPath = shadowPath;
      CGPathRelease(shadowPath);
    } else {
      // Can't accurately calculate box shadow, so fall back to pixel-based shadow.
      layer.shadowPath = nil;
    }
  } else {
    layer.shadowPath = nil;
  }

#if !TARGET_OS_TV && defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && \
    __IPHONE_OS_VERSION_MAX_ALLOWED >= 170000 /* __IPHONE_17_0 */
  // Stage 1.5. Cursor / Hover Effects
  if (@available(iOS 17.0, *)) {
    UIHoverStyle *hoverStyle = nil;
    if (_props->cursor == Cursor::Pointer) {
      const RCTCornerInsets cornerInsets =
          RCTGetCornerInsets(RCTCornerRadiiFromBorderRadii(borderMetrics.borderRadii), UIEdgeInsetsZero);
#if TARGET_OS_IOS
      // Due to an Apple bug, it seems on iOS, UIShapes made with `[UIShape shapeWithBezierPath:]`
      // evaluate their shape on the superviews' coordinate space. This leads to the hover shape
      // rendering incorrectly on iOS, iOS apps in compatibility mode on visionOS, but not on visionOS.
      // To work around this, for iOS, we can calculate the border path based on `view.frame` (the
      // superview's coordinate space) instead of view.bounds.
      CGPathRef borderPath = RCTPathCreateWithRoundedRect(self.frame, cornerInsets, NULL, NO);
#else // TARGET_OS_VISION
      CGPathRef borderPath = RCTPathCreateWithRoundedRect(self.bounds, cornerInsets, NULL, NO);
#endif
      UIBezierPath *bezierPath = [UIBezierPath bezierPathWithCGPath:borderPath];
      CGPathRelease(borderPath);
      UIShape *shape = [UIShape shapeWithBezierPath:bezierPath];

      hoverStyle = [UIHoverStyle styleWithEffect:[UIHoverAutomaticEffect effect] shape:shape];
    }
    [self setHoverStyle:hoverStyle];
  }
#endif
  const bool useCoreAnimationBorderRendering =
      borderMetrics.borderColors.isUniform() && borderMetrics.borderWidths.isUniform() &&
      borderMetrics.borderStyles.isUniform() && borderMetrics.borderStyles.left == BorderStyle::Solid &&
      areBorderRadiiCircular(borderMetrics.borderRadii) &&
      (
          // iOS draws borders in front of the content whereas CSS draws them behind
          // the content. For this reason, only use iOS border drawing when clipping
          // or when the border is hidden.
          borderMetrics.borderWidths.left == 0 || self.currentContainerView.clipsToBounds ||
          (colorComponentsFromColor(borderMetrics.borderColors.left).alpha == 0 &&
           (*borderMetrics.borderColors.left).getUIColor() != nullptr));

  // background color
  UIColor *backgroundColor = [_backgroundColor resolvedColorWithTraitCollection:self.traitCollection];
  // The reason we sometimes do not set self.layer's backgroundColor is because
  // we want to support non-uniform border radii, which apple does not natively
  // support. To get this behavior we need to create a CGPath in the shape that
  // we want. If we mask self.layer to this path, we would be clipping subviews
  // which we may not want to do. The generalized solution in this case is just
  // create a new layer
  if (useCoreAnimationBorderRendering) {
    [_backgroundColorLayer removeFromSuperlayer];
    _backgroundColorLayer = nil;
    layer.backgroundColor = backgroundColor.CGColor;
  } else {
    layer.backgroundColor = nil;
    if (!_backgroundColorLayer) {
      _backgroundColorLayer = [CALayer layer];
      _backgroundColorLayer.zPosition = BACKGROUND_COLOR_ZPOSITION;
      [layer addSublayer:_backgroundColorLayer];
    }
    [self shapeLayerToMatchView:_backgroundColorLayer borderMetrics:borderMetrics];
    _backgroundColorLayer.backgroundColor = backgroundColor.CGColor;
    [_backgroundColorLayer removeAllAnimations];
  }

  // borders
  if (useCoreAnimationBorderRendering) {
    [_borderLayer removeFromSuperlayer];
    _borderLayer = nil;

    layer.borderWidth = (CGFloat)borderMetrics.borderWidths.left;
    UIColor *borderColor = RCTUIColorFromSharedColor(borderMetrics.borderColors.left);
    layer.borderColor = borderColor.CGColor;
    layer.cornerRadius = (CGFloat)borderMetrics.borderRadii.topLeft.horizontal;
    layer.cornerCurve = CornerCurveFromBorderCurve(borderMetrics.borderCurves.topLeft);
  } else {
    if (!_borderLayer) {
      CALayer *borderLayer = [CALayer new];
      borderLayer.zPosition = BACKGROUND_COLOR_ZPOSITION + 1;
      borderLayer.frame = layer.bounds;
      borderLayer.magnificationFilter = kCAFilterNearest;
      [layer addSublayer:borderLayer];
      _borderLayer = borderLayer;
    }

    layer.borderWidth = 0;
    layer.borderColor = nil;
    layer.cornerRadius = 0;

    RCTBorderColors borderColors = RCTCreateRCTBorderColorsFromBorderColors(borderMetrics.borderColors);

    RCTAddContourEffectToLayer(
        _borderLayer,
        RCTCornerRadiiFromBorderRadii(borderMetrics.borderRadii),
        borderColors,
        RCTUIEdgeInsetsFromEdgeInsets(borderMetrics.borderWidths),
        RCTBorderStyleFromBorderStyle(borderMetrics.borderStyles.left));
  }

  // outline
  [_outlineLayer removeFromSuperlayer];
  _outlineLayer = nil;
  if (_props->outlineWidth != 0) {
    if (!_outlineLayer) {
      CALayer *outlineLayer = [CALayer new];
      outlineLayer.magnificationFilter = kCAFilterNearest;
      outlineLayer.zPosition = BACKGROUND_COLOR_ZPOSITION + 2;

      [layer addSublayer:outlineLayer];
      _outlineLayer = outlineLayer;
    }
    _outlineLayer.frame = CGRectInset(
        layer.bounds, -_props->outlineOffset - _props->outlineWidth, -_props->outlineOffset - _props->outlineWidth);

    if (areBorderRadiiCircular(borderMetrics.borderRadii) && borderMetrics.borderRadii.topLeft.horizontal == 0) {
      UIColor *outlineColor = RCTUIColorFromSharedColor(_props->outlineColor);
      _outlineLayer.borderWidth = _props->outlineWidth;
      _outlineLayer.borderColor = outlineColor.CGColor;
    } else {
      UIColor *outlineColor = RCTUIColorFromSharedColor(_props->outlineColor);

      RCTAddContourEffectToLayer(
          _outlineLayer,
          RCTCreateOutlineCornerRadiiFromBorderRadii(
              borderMetrics.borderRadii, _props->outlineWidth, _props->outlineOffset),
          RCTBorderColors{outlineColor, outlineColor, outlineColor, outlineColor},
          UIEdgeInsets{_props->outlineWidth, _props->outlineWidth, _props->outlineWidth, _props->outlineWidth},
          RCTBorderStyleFromOutlineStyle(_props->outlineStyle));
    }
  }

  // filter
  [_filterLayer removeFromSuperlayer];
  _filterLayer = nil;
  if (_swiftUIWrapper != nullptr) {
    [_swiftUIWrapper resetStyles];
  }
  self.layer.opacity = (float)_props->opacity;
  if (!_props->filter.empty()) {
    float multiplicativeBrightness = 1;
    bool hasBrightnessFilter = false;
    for (const auto &primitive : _props->filter) {
      if (primitive.type == FilterType::DropShadow) {
        if (_swiftUIWrapper != nullptr && std::holds_alternative<DropShadowParams>(primitive.parameters)) {
          const auto &dropShadowParams = std::get<DropShadowParams>(primitive.parameters);
          UIColor *shadowColor = RCTUIColorFromSharedColor(dropShadowParams.color);
          [_swiftUIWrapper updateDropShadow:@(dropShadowParams.standardDeviation)
                                          x:@(dropShadowParams.offsetX)
                                          y:@(dropShadowParams.offsetY)
                                      color:shadowColor];
        }
      } else if (std::holds_alternative<Float>(primitive.parameters)) {
        if (primitive.type == FilterType::Brightness) {
          multiplicativeBrightness *= std::get<Float>(primitive.parameters);
          hasBrightnessFilter = true;
        } else if (primitive.type == FilterType::Opacity) {
          self.layer.opacity *= std::get<Float>(primitive.parameters);
        } else if (primitive.type == FilterType::Blur) {
          if (_swiftUIWrapper != nullptr) {
            Float blurRadius = std::get<Float>(primitive.parameters);
            [_swiftUIWrapper updateBlurRadius:@(blurRadius)];
          }
        } else if (primitive.type == FilterType::Grayscale) {
          if (_swiftUIWrapper != nullptr) {
            Float grayscale = std::get<Float>(primitive.parameters);
            [_swiftUIWrapper updateGrayscale:@(grayscale)];
          }
        } else if (primitive.type == FilterType::Saturate) {
          if (_swiftUIWrapper != nullptr) {
            Float saturation = std::get<Float>(primitive.parameters);
            [_swiftUIWrapper updateSaturation:@(saturation)];
          }
        } else if (primitive.type == FilterType::Contrast) {
          if (_swiftUIWrapper != nullptr) {
            Float contrast = std::get<Float>(primitive.parameters);
            [_swiftUIWrapper updateContrast:@(contrast)];
          }
        } else if (primitive.type == FilterType::HueRotate) {
          if (_swiftUIWrapper != nullptr) {
            Float hueRotateDegrees = std::get<Float>(primitive.parameters);
            [_swiftUIWrapper updateHueRotate:@(hueRotateDegrees)];
          }
        }
      }
    }

    if (hasBrightnessFilter) {
      _filterLayer = [CALayer layer];
      [self shapeLayerToMatchView:_filterLayer borderMetrics:borderMetrics];
      _filterLayer.compositingFilter = @"multiplyBlendMode";
      _filterLayer.backgroundColor = [UIColor colorWithRed:multiplicativeBrightness
                                                     green:multiplicativeBrightness
                                                      blue:multiplicativeBrightness
                                                     alpha:self.layer.opacity]
                                         .CGColor;
      // So that this layer is always above any potential sublayers this view may
      // add
      _filterLayer.zPosition = CGFLOAT_MAX;
      [layer addSublayer:_filterLayer];
    }
  }

  // background image
  [self clearExistingBackgroundImageLayers];
  if (!_props->backgroundImage.empty()) {
    const auto borderMetricsBI = _props->resolveBorderMetrics(_layoutMetrics);

    // background-origin: padding-box
    CGRect backgroundPositioningArea = RCTCGRectFromRect(_layoutMetrics.getPaddingFrame());
    // background-clip: border-box
    CGRect backgroundPaintingArea = self.layer.bounds;

    size_t imageIndex = _props->backgroundImage.size() - 1;
    // iterate in reverse to match CSS specification
    for (const auto &backgroundImage : std::ranges::reverse_view(_props->backgroundImage)) {
      BackgroundSize backgroundSize = BackgroundSizeLengthPercentage{};
      if (!_props->backgroundSize.empty()) {
        backgroundSize = _props->backgroundSize[imageIndex % _props->backgroundSize.size()];
      }

      BackgroundPosition backgroundPosition;
      if (!_props->backgroundPosition.empty()) {
        backgroundPosition = _props->backgroundPosition[imageIndex % _props->backgroundPosition.size()];
      }

      BackgroundRepeat backgroundRepeat;
      if (!_props->backgroundRepeat.empty()) {
        backgroundRepeat = _props->backgroundRepeat[imageIndex % _props->backgroundRepeat.size()];
      }

      CGSize backgroundImageSize = [RCTBackgroundImageUtils calculateBackgroundImageSize:backgroundPositioningArea
                                                                       itemIntrinsicSize:backgroundPositioningArea.size
                                                                          backgroundSize:backgroundSize
                                                                        backgroundRepeat:backgroundRepeat];

      CALayer *gradientLayer;

      if (std::holds_alternative<LinearGradient>(backgroundImage)) {
        const auto &linearGradient = std::get<LinearGradient>(backgroundImage);
        gradientLayer = [RCTLinearGradient gradientLayerWithSize:backgroundImageSize gradient:linearGradient];
      } else if (std::holds_alternative<RadialGradient>(backgroundImage)) {
        const auto &radialGradient = std::get<RadialGradient>(backgroundImage);
        gradientLayer = [RCTRadialGradient gradientLayerWithSize:backgroundImageSize gradient:radialGradient];
      }

      if (gradientLayer != nil) {
        CALayer *backgroundImageLayer =
            [RCTBackgroundImageUtils createBackgroundImageLayerWithSize:backgroundPositioningArea
                                                           paintingArea:backgroundPaintingArea
                                                               itemSize:backgroundImageSize
                                                     backgroundPosition:backgroundPosition
                                                       backgroundRepeat:backgroundRepeat
                                                              itemLayer:gradientLayer];
        [self shapeLayerToMatchView:backgroundImageLayer borderMetrics:borderMetricsBI];
        backgroundImageLayer.masksToBounds = YES;
        backgroundImageLayer.zPosition = BACKGROUND_COLOR_ZPOSITION;
        [layer addSublayer:backgroundImageLayer];
        [_backgroundImageLayers addObject:backgroundImageLayer];
      }

      imageIndex--;
    }
  }

  // box shadow
  for (CALayer *boxShadowLayer in _boxShadowLayers) {
    [boxShadowLayer removeFromSuperlayer];
  }
  [_boxShadowLayers removeAllObjects];
  if (!_props->boxShadow.empty()) {
    if (!_boxShadowLayers) {
      _boxShadowLayers = [NSMutableArray new];
    }
    for (auto it = _props->boxShadow.rbegin(); it != _props->boxShadow.rend(); ++it) {
      CALayer *shadowLayer = RCTGetBoxShadowLayer(
          *it,
          RCTCornerRadiiFromBorderRadii(borderMetrics.borderRadii),
          RCTUIEdgeInsetsFromEdgeInsets(borderMetrics.borderWidths),
          self.layer.bounds.size);
      shadowLayer.zPosition = _borderLayer.zPosition;
      [layer addSublayer:shadowLayer];
      [_boxShadowLayers addObject:shadowLayer];
    }
  }

  // clipping
  self.currentContainerView.layer.mask = nil;
  if (self.currentContainerView.clipsToBounds) {
    BOOL clipToPaddingBox = ReactNativeFeatureFlags::enableIOSViewClipToPaddingBox();
    if (!clipToPaddingBox) {
      if (areBorderRadiiCircular(borderMetrics.borderRadii)) {
        self.currentContainerView.layer.cornerRadius = borderMetrics.borderRadii.topLeft.horizontal;
      } else {
        CALayer *maskLayer =
            [self createMaskLayer:self.bounds
                     cornerInsets:RCTGetCornerInsets(
                                      RCTCornerRadiiFromBorderRadii(borderMetrics.borderRadii), UIEdgeInsetsZero)];
        self.currentContainerView.layer.mask = maskLayer;
      }

      for (UIView *subview in self.currentContainerView.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
          RCTCornerInsets cornerInsets = RCTGetCornerInsets(
              RCTCornerRadiiFromBorderRadii(borderMetrics.borderRadii),
              RCTUIEdgeInsetsFromEdgeInsets(borderMetrics.borderWidths));

          // If the subview is an image view, we have to apply the mask directly to the image view's layer,
          // otherwise the image might overflow with the border radius.
          subview.layer.mask = [self createMaskLayer:subview.bounds cornerInsets:cornerInsets];
        }
      }
    } else if (
        !borderMetrics.borderWidths.isUniform() || borderMetrics.borderWidths.left != 0 ||
        !areBorderRadiiCircular(borderMetrics.borderRadii)) {
      CALayer *maskLayer = [self createMaskLayer:RCTCGRectFromRect(_layoutMetrics.getPaddingFrame())
                                    cornerInsets:RCTGetCornerInsets(
                                                     RCTCornerRadiiFromBorderRadii(borderMetrics.borderRadii),
                                                     RCTUIEdgeInsetsFromEdgeInsets(borderMetrics.borderWidths))];
      self.currentContainerView.layer.mask = maskLayer;
    } else {
      self.currentContainerView.layer.cornerRadius = borderMetrics.borderRadii.topLeft.horizontal;
    }
  }
}

// Shapes the given layer to match the shape of this View's layer. This is
// basically just accounting for size, position, and border radius.
- (void)shapeLayerToMatchView:(CALayer *)layer borderMetrics:(BorderMetrics)borderMetrics
{
  // Bounds is needed here to account for scaling transforms properly and ensure
  // we do not scale twice
  layer.frame = CGRectMake(0, 0, self.layer.bounds.size.width, self.layer.bounds.size.height);
  if (areBorderRadiiCircular(borderMetrics.borderRadii)) {
    layer.mask = nil;
    layer.cornerRadius = borderMetrics.borderRadii.topLeft.horizontal;
    layer.cornerCurve = CornerCurveFromBorderCurve(borderMetrics.borderCurves.topLeft);
  } else {
    CAShapeLayer *maskLayer = [self
        createMaskLayer:self.bounds
           cornerInsets:RCTGetCornerInsets(RCTCornerRadiiFromBorderRadii(borderMetrics.borderRadii), UIEdgeInsetsZero)];
    layer.mask = maskLayer;
    layer.cornerRadius = 0;
  }
}

- (CAShapeLayer *)createMaskLayer:(CGRect)bounds cornerInsets:(RCTCornerInsets)cornerInsets
{
  CGPathRef path = RCTPathCreateWithRoundedRect(bounds, cornerInsets, nil, NO);
  CAShapeLayer *maskLayer = [CAShapeLayer layer];
  maskLayer.path = path;
  CGPathRelease(path);
  return maskLayer;
}

- (void)clearExistingBackgroundImageLayers
{
  if (_backgroundImageLayers == nil) {
    _backgroundImageLayers = [NSMutableArray new];
    return;
  }
  for (CALayer *backgroundImageLayer in _backgroundImageLayers) {
    [backgroundImageLayer removeFromSuperlayer];
  }
  [_backgroundImageLayers removeAllObjects];
}

#pragma mark - Accessibility

- (NSObject *)accessibilityElement
{
  return self;
}

- (void)didMoveToSuperview
{
  // At this point we are guaranteed to have subviews, if we are going to have them
  if (ReactNativeFeatureFlags::enableAccessibilityOrder()) {
    [self updateAccessibilityElements];
  }
}

- (void)updateAccessibilityElements
{
  if ([_accessibilityOrderNativeIDs count] == 0) {
    self.accessibilityElements = nil;
    return;
  }

  NSMutableDictionary<NSString *, UIView *> *nativeIdToView = [NSMutableDictionary new];
  [RCTViewComponentView collectAccessibilityElements:self
                                      intoDictionary:nativeIdToView
                                           nativeIds:_accessibilityOrderNativeIDs];

  NSMutableArray *accessibilityElements = [NSMutableArray new];
  for (const auto &childId : _props->accessibilityOrder) {
    NSString *nsStringChildId = RCTNSStringFromString(childId);

    UIView *viewWithMatchingNativeId = [nativeIdToView objectForKey:nsStringChildId];
    if (viewWithMatchingNativeId != nil) {
      [accessibilityElements addObject:viewWithMatchingNativeId];
    }
  }

  self.accessibilityElements = accessibilityElements;
}

+ (void)collectAccessibilityElements:(UIView *)view
                      intoDictionary:(NSMutableDictionary<NSString *, UIView *> *)dict
                           nativeIds:(NSSet<NSString *> *)nativeIds
{
  for (UIView *subview in view.subviews) {
    if ([subview isKindOfClass:[RCTViewComponentView class]] &&
        [nativeIds containsObject:((RCTViewComponentView *)subview).nativeId]) {
      [dict setObject:subview forKey:((RCTViewComponentView *)subview).nativeId];
    }
    [RCTViewComponentView collectAccessibilityElements:subview intoDictionary:dict nativeIds:nativeIds];
  }
}

static NSString *RCTRecursiveAccessibilityLabel(UIView *view)
{
  // Result string is initialized lazily to prevent useless but costly allocations.
  NSMutableString *result = nil;
  for (UIView *subview in view.subviews) {
    // Skip subviews that have accessibilityElementsHidden set to YES
    if (subview.accessibilityElementsHidden) {
      continue;
    }
    NSString *label = subview.accessibilityLabel;
    if (!label) {
      label = RCTRecursiveAccessibilityLabel(subview);
    }
    if (label && label.length > 0) {
      if (result == nil) {
        result = [NSMutableString string];
      }
      if (result.length > 0) {
        [result appendString:@", "];
      }
      [result appendString:label];
    }
  }
  return result;
}

- (NSString *)accessibilityLabel
{
  NSString *label = super.accessibilityLabel;
  if (label) {
    return label;
  }

  if (self.isAccessibilityElement) {
    return RCTRecursiveAccessibilityLabel(self.currentContainerView);
  }
  return nil;
}

- (NSString *)accessibilityLabelForCoopting
{
  return super.accessibilityLabel;
}

- (BOOL)wantsToCooptLabel
{
  return !super.accessibilityLabel && super.isAccessibilityElement;
}

- (BOOL)canBecomeFocused
{
  return _focusable;
}

- (BOOL)isAccessibilityElement
{
  if (self.contentView != nil) {
    return self.contentView.isAccessibilityElement;
  }

  return [super isAccessibilityElement];
}

- (NSString *)accessibilityValue
{
  const auto &props = static_cast<const ViewProps &>(*_props);
  const auto accessibilityState = props.accessibilityState.value_or(AccessibilityState{});

  // Handle Switch.
  if ((self.accessibilityTraits & AccessibilityTraitSwitch) == AccessibilityTraitSwitch) {
    if (accessibilityState.checked == AccessibilityState::Checked) {
      return @"1";
    } else if (accessibilityState.checked == AccessibilityState::Unchecked) {
      return @"0";
    }
  }

  NSMutableArray *valueComponents = [NSMutableArray new];
  NSString *roleString = (props.role != Role::None) ? [NSString stringWithUTF8String:toString(props.role).c_str()]
                                                    : [NSString stringWithUTF8String:props.accessibilityRole.c_str()];

  // In iOS, checkbox and radio buttons aren't recognized as traits. However,
  // because our apps use checkbox and radio buttons often, we should announce
  // these to screenreader users.  (They should already be familiar with them
  // from using web).
  if ([roleString isEqualToString:@"checkbox"]) {
    [valueComponents addObject:RCTLocalizedString("checkbox", "checkable interactive control")];
  }

  if ([roleString isEqualToString:@"radio"]) {
    [valueComponents
        addObject:
            RCTLocalizedString(
                "radio button",
                "a checkable input that when associated with other radio buttons, only one of which can be checked at a time")];
  }

  // Handle states which haven't already been handled.
  if (accessibilityState.checked == AccessibilityState::Checked) {
    [valueComponents
        addObject:RCTLocalizedString("checked", "a checkbox, radio button, or other widget which is checked")];
  }
  if (accessibilityState.checked == AccessibilityState::Unchecked) {
    [valueComponents
        addObject:RCTLocalizedString("unchecked", "a checkbox, radio button, or other widget which is unchecked")];
  }
  if (accessibilityState.checked == AccessibilityState::Mixed) {
    [valueComponents
        addObject:RCTLocalizedString(
                      "mixed", "a checkbox, radio button, or other widget which is both checked and unchecked")];
  }
  if (accessibilityState.expanded.value_or(false)) {
    [valueComponents
        addObject:RCTLocalizedString("expanded", "a menu, dialog, accordian panel, or other widget which is expanded")];
  }

  if (accessibilityState.busy) {
    [valueComponents addObject:RCTLocalizedString("busy", "an element currently being updated or modified")];
  }

  // Using super.accessibilityValue:
  // 1. to access the value that is set to accessibilityValue in updateProps
  // 2. can't access from self.accessibilityElement because it resolves to self
  if (super.accessibilityValue) {
    [valueComponents addObject:super.accessibilityValue];
  }

  if (valueComponents.count > 0) {
    return [valueComponents componentsJoinedByString:@", "];
  }

  return nil;
}

#pragma mark - Accessibility Events

- (BOOL)shouldGroupAccessibilityChildren
{
  return YES;
}

- (NSArray<UIAccessibilityCustomAction *> *)accessibilityCustomActions
{
  const auto &accessibilityActions = _props->accessibilityActions;

  if (accessibilityActions.empty()) {
    return nil;
  }

  NSMutableArray<UIAccessibilityCustomAction *> *customActions = [NSMutableArray array];
  for (const auto &accessibilityAction : accessibilityActions) {
    NSString *actionName = RCTNSStringFromString(accessibilityAction.name);
    NSString *actionLabel = actionName;

    if (accessibilityAction.label.has_value()) {
      actionLabel = RCTNSStringFromString(accessibilityAction.label.value());
    }

    [customActions
        addObject:[[UIAccessibilityCustomAction alloc] initWithName:actionLabel
                                                             target:self
                                                           selector:@selector(didActivateAccessibilityCustomAction:)]];
  }

  return [customActions copy];
}

- (BOOL)accessibilityActivate
{
  if (_eventEmitter && _props->onAccessibilityTap) {
    _eventEmitter->onAccessibilityTap();
    return YES;
  } else {
    return NO;
  }
}

- (BOOL)accessibilityPerformMagicTap
{
  if (_eventEmitter && _props->onAccessibilityMagicTap) {
    _eventEmitter->onAccessibilityMagicTap();
    return YES;
  } else {
    return NO;
  }
}

- (BOOL)accessibilityPerformEscape
{
  if (_eventEmitter && _props->onAccessibilityEscape) {
    _eventEmitter->onAccessibilityEscape();
    return YES;
  } else {
    return NO;
  }
}

- (void)accessibilityIncrement
{
  if (_eventEmitter && _props->onAccessibilityAction) {
    _eventEmitter->onAccessibilityAction("increment");
  }
}

- (void)accessibilityDecrement
{
  if (_eventEmitter && _props->onAccessibilityAction) {
    _eventEmitter->onAccessibilityAction("decrement");
  }
}

- (BOOL)didActivateAccessibilityCustomAction:(UIAccessibilityCustomAction *)action
{
  if (_eventEmitter && _props->onAccessibilityAction) {
    // iOS defines the name as the localized label, so iterate through accessibilityActions to find the matching
    // non-localized action name when passing to JS. This allows for standard action names across platforms.
    NSString *actionName = action.name;
    for (const auto &accessibilityAction : _props->accessibilityActions) {
      if (accessibilityAction.label.has_value() &&
          [RCTNSStringFromString(accessibilityAction.label.value()) isEqualToString:action.name]) {
        actionName = RCTNSStringFromString(accessibilityAction.name);
        break;
      }
    }
    _eventEmitter->onAccessibilityAction(RCTStringFromNSString(actionName));
    return YES;
  } else {
    return NO;
  }
}

- (SharedTouchEventEmitter)touchEventEmitterAtPoint:(CGPoint)point
{
  return _eventEmitter;
}

- (NSString *)componentViewName_DO_NOT_USE_THIS_IS_BROKEN
{
  return RCTNSStringFromString([[self class] componentDescriptorProvider].name);
}

- (BOOL)styleNeedsSwiftUIContainer
{
  if (!_props->filter.empty()) {
    for (const auto &primitive : _props->filter) {
      if (primitive.type == FilterType::Blur || primitive.type == FilterType::Grayscale ||
          primitive.type == FilterType::DropShadow || primitive.type == FilterType::Saturate ||
          primitive.type == FilterType::Contrast || primitive.type == FilterType::HueRotate) {
        return YES;
      }
    }
  }
  return NO;
}

- (void)transferVisualPropertiesFromView:(UIView *)sourceView toView:(UIView *)destinationView
{
  // shadow
  destinationView.layer.shadowColor = sourceView.layer.shadowColor;
  sourceView.layer.shadowColor = nil;
  destinationView.layer.shadowOffset = sourceView.layer.shadowOffset;
  sourceView.layer.shadowOffset = CGSizeZero;
  destinationView.layer.shadowOpacity = sourceView.layer.shadowOpacity;
  sourceView.layer.shadowOpacity = 0;
  destinationView.layer.shadowRadius = sourceView.layer.shadowRadius;
  sourceView.layer.shadowRadius = 0;

  // background
  destinationView.layer.backgroundColor = sourceView.layer.backgroundColor;
  sourceView.layer.backgroundColor = nil;
  if (_backgroundColorLayer != nullptr) {
    [destinationView.layer addSublayer:_backgroundColorLayer];
  }

  // border
  destinationView.layer.borderColor = sourceView.layer.borderColor;
  sourceView.layer.borderColor = nil;
  destinationView.layer.borderWidth = sourceView.layer.borderWidth;
  sourceView.layer.borderWidth = 0;

  // corner
  destinationView.layer.cornerRadius = sourceView.layer.cornerRadius;
  sourceView.layer.cornerRadius = 0;
  destinationView.layer.cornerCurve = sourceView.layer.cornerCurve;

  // custom layers
  if (_borderLayer != nullptr) {
    [destinationView.layer addSublayer:_borderLayer];
  }
  if (_outlineLayer != nullptr) {
    [destinationView.layer addSublayer:_outlineLayer];
  }
  if (_filterLayer != nullptr) {
    [destinationView.layer addSublayer:_filterLayer];
  }
  for (CALayer *layer = nullptr in _backgroundImageLayers) {
    [destinationView.layer addSublayer:layer];
  }
  for (CALayer *layer = nullptr in _boxShadowLayers) {
    [destinationView.layer addSublayer:layer];
  }
}

#pragma mark - Focus Events

- (BOOL)canBecomeFirstResponder
{
  return ReactNativeFeatureFlags::enableImperativeFocus();
}

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args
{
  if ([commandName isEqualToString:@"focus"]) {
    [self focus];
    return;
  }

  if ([commandName isEqualToString:@"blur"]) {
    [self blur];
    return;
  }
}

#if TARGET_OS_TV
/// Finds the containing RCTSurfaceHostingProxyRootView by walking up the view
/// hierarchy.
- (RCTSurfaceHostingProxyRootView *)containingRootView
{
  UIView *view = self;
  while (view != nil) {
    if ([view isKindOfClass:[RCTSurfaceHostingProxyRootView class]]) {
      return (RCTSurfaceHostingProxyRootView *)view;
    }
    view = view.superview;
  }
  return nil;
}
#endif

- (void)focus
{
#if TARGET_OS_OSX // [macOS] On AppKit -becomeFirstResponder is the window
  // notifying the view that it happened, not the view asking. Sending it
  // directly changes nothing: -makeFirstResponder: is the request. Without
  // this, `focusable` views never receive key events, because nothing ever
  // makes them first responder -- AppKit moves focus on Tab only, and only
  // when Full Keyboard Access is on.
  [self.window makeFirstResponder:self];
#else // [macOS]
  [self becomeFirstResponder];
#endif // [macOS]

#if TARGET_OS_TV
  RCTSurfaceHostingProxyRootView *rootView = [self containingRootView];
  if (rootView == nil) {
    return;
  }

  rootView.reactPreferredFocusedView = self;
  [rootView setNeedsFocusUpdate];
  [rootView updateFocusIfNeeded];
#endif
}

- (void)blur
{
#if TARGET_OS_OSX // [macOS] Symmetrically: resigning is granted by the window,
  // and only if this view still holds the focus.
  if (self.window.firstResponder == self) {
    [self.window makeFirstResponder:nil];
  }
#else // [macOS]
  [self resignFirstResponder];
#endif // [macOS]
}

- (BOOL)becomeFirstResponder
{
  if (![super becomeFirstResponder]) {
    return NO;
  }

  if (_eventEmitter && ReactNativeFeatureFlags::enableImperativeFocus()) {
    _eventEmitter->onFocus();
  }

  return YES;
}

- (BOOL)resignFirstResponder
{
  if (![super resignFirstResponder]) {
    return NO;
  }

  if (_eventEmitter && ReactNativeFeatureFlags::enableImperativeFocus()) {
    _eventEmitter->onBlur();
  }

  return YES;
}

#if TARGET_OS_TV

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context
       withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
  if (context.previouslyFocusedView == context.nextFocusedView) {
    return;
  }

  // Do not resignFirstRespodner if we lost focus, let whoever took focus
  // becomeFirstResponder thereby resigning for us. If we resign here,
  // first responder will be assigned to some ancestor view and they
  // can temporarily call onFocus/onBlur
  if (context.nextFocusedView == self) {
    [self becomeFirstResponder];
  } else if (context.previouslyFocusedView == self && context.nextFocusedView == nil) {
    [self resignFirstResponder];
  }

  [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
}

#endif

@end

#ifdef __cplusplus
extern "C" {
#endif

// Can't the import generated Plugin.h because plugins are not in this BUCK target
Class<RCTComponentViewProtocol> RCTViewCls(void);

#ifdef __cplusplus
}
#endif

Class<RCTComponentViewProtocol> RCTViewCls(void)
{
  return RCTViewComponentView.class;
}
