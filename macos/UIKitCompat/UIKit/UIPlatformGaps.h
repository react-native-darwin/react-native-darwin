/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * Small AppKit gaps: properties and methods UIKit has that AppKit simply does
 * not, on classes that already exist. One file rather than a dozen, because
 * each is a few lines and none of them warrants its own header.
 */

#pragma once

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

#import "UIEvent.h"
#import "UIKitDefines.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIScreen

@interface NSScreen (UIKitCompat)
// UIScreen.scale. NSScreen spells it backingScaleFactor.
@property (nonatomic, readonly) CGFloat scale;
// UIScreen.coordinateSpace. Only -bounds is ever read off it, so the screen
// stands in for itself.
@property (nonatomic, readonly) NSScreen *coordinateSpace;
@property (nonatomic, readonly) CGRect bounds;
@end

#pragma mark - UIWindow

@interface NSWindow (UIKitCompat)
// UIWindow is initialised from a frame. An NSWindow needs a style mask and a
// backing store as well; this picks sensible defaults for a React Native
// overlay window.
- (instancetype)initWithFrame:(CGRect)frame;
// UIKit spells NSWindow's -level as -windowLevel.
@property (nonatomic, assign) CGFloat windowLevel;
// UIWindow.windowScene. macOS has no scenes; always nil.
// Writable: upstream clears it when tearing an alert window down.
@property (nonatomic, strong, nullable) id windowScene;
@property (nonatomic, assign) UIUserInterfaceStyle overrideUserInterfaceStyle;
@end

@interface NSImage (UIKitCompatCGImage)
- (nullable instancetype)initWithCGImage:(CGImageRef)cgImage scale:(CGFloat)scale orientation:(NSInteger)orientation;
@end

typedef NS_ENUM(NSInteger, UISemanticContentAttribute) {
  UISemanticContentAttributeUnspecified = 0,
  UISemanticContentAttributePlayback,
  UISemanticContentAttributeSpatial,
  UISemanticContentAttributeForceLeftToRight,
  UISemanticContentAttributeForceRightToLeft,
};

@interface NSView (UIKitCompatTag)
/**
 * UIKit's tag is read-write; NSView's is read-only and returns -1.
 *
 * React Native stores its own view tags here and looks views up by them, so
 * both halves are needed. The getter deliberately overrides NSView's, which
 * makes -viewWithTag: find React's tags -- the behaviour upstream expects.
 *
 * NSControl and its subclasses define their own -tag, and a subclass beats a
 * superclass category, so AppKit controls keep AppKit's meaning. Only plain
 * NSViews are affected.
 */
- (NSInteger)tag;
- (void)setTag:(NSInteger)tag;
@end

@interface NSView (UIKitCompatTint)
// UIKit's tintColor. AppKit has contentTintColor on controls only, so this is
// stored and applied to the layer where it is meaningful.
@property (nonatomic, strong, nullable) NSColor *tintColor;
@end

// AppKit's hover tracking is NSTrackingArea, not a recogniser. This exists so
// the pointer-event plumbing parses; it never fires.
@interface UIHoverGestureRecognizer : NSGestureRecognizer
@end

@interface NSGestureRecognizer (UIKitCompat)
// UIKit lets a recogniser swallow the touches it consumed. AppKit's responder
// chain has no equivalent switch, so this is stored and never acted on.
@property (nonatomic, assign) BOOL cancelsTouchesInView;
@property (nonatomic, assign) BOOL delaysTouchesBegan;
@property (nonatomic, assign) BOOL delaysTouchesEnded;
@end

@interface NSPasteboard (UIKitCompat)
// UIPasteboard.string. NSPasteboard reads by type.
// NSPasteboard already has +generalPasteboard; only -string is missing.
@property (nonatomic, copy, nullable) NSString *string;
@end

@interface NSImage (UIKitCompatResizing)
// UIImage.images is the frame list of an animated image. NSImage has no
// animation model, so this is always nil.
@property (nonatomic, readonly, nullable) NSArray<NSImage *> *images;
- (NSImage *)resizableImageWithCapInsets:(UIEdgeInsets)capInsets;
- (NSImage *)resizableImageWithCapInsets:(UIEdgeInsets)capInsets resizingMode:(NSInteger)resizingMode;
@end

@interface NSImage (UIKitCompatDrawing)
// NSImage already has -drawInRect: (10.9+); only -drawAtPoint: is missing.
- (void)drawAtPoint:(CGPoint)point;
+ (nullable NSImage *)systemImageNamed:(NSString *)name;
@end

typedef NS_ENUM(NSInteger, UIImageResizingMode) {
  UIImageResizingModeTile = 0,
  UIImageResizingModeStretch = 1,
};

@interface NSWindow (UIKitCompatLayout)
// UIWindow is a UIView, so upstream sends it view messages. NSWindow is not,
// so the few that are used are forwarded to the content view.
- (void)layoutSubviews;
- (void)setNeedsLayout;
// UIWindow's show-me method.
- (void)makeKeyAndVisible;
// UIKit reads traits off the window; AppKit off the effective appearance.
- (CGPoint)convertPoint:(CGPoint)point toView:(nullable NSView *)view;
- (CGPoint)convertPoint:(CGPoint)point fromView:(nullable NSView *)view;
@end

@interface UIWindowScene (UIKitCompatCoordinateSpace)
@property (nonatomic, readonly, nullable) NSScreen *coordinateSpace;
@property (nonatomic, readonly, nullable) NSScreen *screen;
@property (nonatomic, readonly) NSArray<NSWindow *> *windows;
@end

@interface NSWindow (UIKitCompatRootViewController)
// UIWindow.rootViewController maps onto NSWindow.contentViewController.
@property (nonatomic, strong, nullable) NSViewController *rootViewController;
- (instancetype)initWithWindowScene:(nullable id)windowScene;
@end

@interface NSView (UIKitCompatAccessibilityElement)
// NSAccessibility spells the setter -setAccessibilityElement:. UIKit code
// writes view.isAccessibilityElement = YES, which needs this selector.
- (void)setIsAccessibilityElement:(BOOL)isAccessibilityElement;
@end

@interface NSViewController (UIKitCompatPresentation)
@property (nonatomic, assign) UIModalPresentationStyle modalPresentationStyle;
@end

@interface NSView (UIKitCompatAccessibilityGaps)
// UIKit accessibility properties with no direct NSAccessibility counterpart.
// Stored so upstream reads and writes round-trip; where AppKit has an analogue
// it is applied.
@property (nonatomic, assign) BOOL accessibilityElementsHidden;
@property (nonatomic, assign) BOOL accessibilityIgnoresInvertColors;
@property (nonatomic, assign) BOOL accessibilityViewIsModal;
@property (nonatomic, assign) BOOL shouldGroupAccessibilityChildren;
@property (nonatomic, assign) BOOL isAccessibilityElementByDefault;
@property (nonatomic, assign) BOOL multipleTouchEnabled;
@property (nonatomic, assign) BOOL exclusiveTouch;
@end

@interface NSApplication (UIKitCompatOpenURL)
// UIApplication's three-argument opener. NSWorkspace does the work.
- (void)openURL:(NSURL *)url
              options:(nullable NSDictionary<NSString *, id> *)options
    completionHandler:(void (^_Nullable)(BOOL success))completion;
@property (nonatomic, readonly) NSSet *connectedScenes;
@end

@interface NSWindow (UIKitCompatConvertRect)
- (CGRect)convertRect:(CGRect)rect toView:(nullable NSView *)view;
- (CGRect)convertRect:(CGRect)rect fromView:(nullable NSView *)view;
- (CGRect)convertRect:(CGRect)rect fromCoordinateSpace:(nullable id)coordinateSpace;
- (CGRect)convertRect:(CGRect)rect toCoordinateSpace:(nullable id)coordinateSpace;
// UIWindow is a UIView, so upstream hides it like one.
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@end

@interface NSView (UIKitCompatCallbacks)
// UIKit lifecycle hooks with no AppKit counterpart. Declared so any view can be
// sent them; RCTPlatformView drives the trait one from -viewDidChangeEffectiveAppearance.
- (void)safeAreaInsetsDidChange;
- (void)traitCollectionDidChange:(nullable id)previousTraitCollection;
- (CGSize)sizeThatFits:(CGSize)size;
// UIView.opaque. NSView has -isOpaque read-only; this stores the intent and
// keeps the layer in step.
@property (nonatomic, assign, getter=isOpaqueForUIKitCompat) BOOL opaque;
- (NSArray *)focusItemsInRect:(CGRect)rect;
// Large Content Viewer is an iOS accessibility affordance with no Mac analogue.
@property (nonatomic, assign) BOOL showsLargeContentViewer;
@property (nonatomic, copy, nullable) NSString *largeContentTitle;
@property (nonatomic, strong, nullable) NSImage *largeContentImage;
@property (nonatomic, assign) BOOL scalesLargeContentImage;
@end

@interface NSView (UIKitCompatUserInterfaceStyle)
// UIKit lets a view force light or dark. AppKit's equivalent is to set an
// explicit NSAppearance.
@property (nonatomic, assign) UIUserInterfaceStyle overrideUserInterfaceStyle;
@property (nonatomic, assign) NSInteger accessibilityTraits;
@end

@interface NSViewController (UIKitCompatAppearance)
@property (nonatomic, assign) UIUserInterfaceStyle overrideUserInterfaceStyle;
@property (nonatomic, assign) NSInteger modalTransitionStyle;
@property (nonatomic, assign) BOOL modalInPresentation;
- (void)viewWillLayoutSubviews;
@end

// UIKit's accessibility action object. NSAccessibilityCustomAction exists from
// macOS 11 and is close enough to alias.
@compatibility_alias UIAccessibilityCustomAction NSAccessibilityCustomAction;

@interface NSGestureRecognizer (UIKitCompatTouches)
// UIGestureRecognizer subclasses override these. AppKit routes the equivalent
// through -mouseDown: and friends, so the touch hooks are declared here and
// RCTSurfaceTouchHandler's overrides are driven from the mouse handlers.
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)reset;
@end

@interface NSView (UIKitCompatSubviewOrdering)
- (void)insertSubview:(NSView *)view aboveSubview:(NSView *)siblingSubview;
- (void)insertSubview:(NSView *)view belowSubview:(NSView *)siblingSubview;
@end

@interface NSStackView (UIKitCompatAxis)
// UIStackView.axis; NSStackView calls it orientation.
// UILayoutConstraintAxis and NSUserInterfaceLayoutOrientation share values.
@property (nonatomic, assign) NSInteger axis;
@end

// iOS-only accessibility affordance, declared so the property type resolves.
@interface UILargeContentViewerInteraction : NSObject
@end

@interface NSColor (UIKitCompatTraitResolution)
- (NSColor *)resolvedColorWithTraitCollection:(nullable id)traitCollection;
@end

@interface NSGestureRecognizer (UIKitCompatLocation)
// NSGestureRecognizer already has -locationInView:; only the multi-touch
// accessors are missing, and a mouse only ever reports one pointer.
- (NSUInteger)numberOfTouches;
- (CGPoint)locationOfTouch:(NSUInteger)touchIndex inView:(nullable NSView *)view;
@end

@interface NSViewController (UIKitCompatModal)
- (void)presentViewController:(NSViewController *)viewController
                     animated:(BOOL)animated
                   completion:(void (^_Nullable)(void))completion;
- (void)dismissViewControllerAnimated:(BOOL)animated completion:(void (^_Nullable)(void))completion;
@property (nonatomic, readonly, nullable) NSViewController *presentedViewController;
@end

@interface NSFont (UIKitCompatFamilies)
// UIFont vends family members from the class; AppKit routes it through
// NSFontManager.
+ (NSArray<NSString *> *)fontNamesForFamilyName:(NSString *)familyName;
+ (NSArray<NSString *> *)familyNames;
@end

@interface NSView (UIKitCompatSemanticContent)
// UIKit pins a view's layout direction with this. AppKit's equivalent is
// -userInterfaceLayoutDirection, which this maps onto.
@property (nonatomic, assign) UISemanticContentAttribute semanticContentAttribute;
@end

@interface NSView (UIKitCompatCoordinateSpace)
- (CGPoint)convertPoint:(CGPoint)point toCoordinateSpace:(id)coordinateSpace;
- (CGPoint)convertPoint:(CGPoint)point fromCoordinateSpace:(id)coordinateSpace;
@end

extern const CGFloat UIWindowLevelNormal;
extern const CGFloat UIWindowLevelAlert;
extern const CGFloat UIWindowLevelStatusBar;

#pragma mark - UIViewController

@interface NSViewController (UIKitCompat)
// UIKit's post-layout hook. Bridged from -viewDidLayout.
- (void)viewDidLayoutSubviews;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;
@end

/**
 * UIKit scales a font for the user's preferred content size. macOS has no
 * Dynamic Type; the system text size is fixed per control. Sizes pass through
 * unchanged so Dynamic Type call sites compile and behave as "no scaling".
 */
@interface UIFontMetrics : NSObject
@property (class, nonatomic, readonly) UIFontMetrics *defaultMetrics;
+ (instancetype)metricsForTextStyle:(NSString *)textStyle;
- (NSFont *)scaledFontForFont:(NSFont *)font;
- (CGFloat)scaledValueForValue:(CGFloat)value;
@end

typedef NSString *UIFontTextStyle NS_TYPED_ENUM;
extern UIFontTextStyle const UIFontTextStyleBody;
extern UIFontTextStyle const UIFontTextStyleCallout;
extern UIFontTextStyle const UIFontTextStyleCaption1;
extern UIFontTextStyle const UIFontTextStyleCaption2;
extern UIFontTextStyle const UIFontTextStyleFootnote;
extern UIFontTextStyle const UIFontTextStyleHeadline;
extern UIFontTextStyle const UIFontTextStyleSubheadline;
extern UIFontTextStyle const UIFontTextStyleLargeTitle;
extern UIFontTextStyle const UIFontTextStyleTitle1;
extern UIFontTextStyle const UIFontTextStyleTitle2;
extern UIFontTextStyle const UIFontTextStyleTitle3;

#pragma mark - CADisplayLink

/**
 * CADisplayLink exists on macOS only from 14.0, and even there it is vended by
 * NSScreen or NSView rather than by a class method.
 *
 * This category restores UIKit's factory. Below macOS 14 there is no display
 * link to hand back, so it returns nil and callers fall back to their timer
 * path -- which is what React Native already does when a display link is
 * unavailable.
 */
@interface CADisplayLink (UIKitCompat)
+ (nullable CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)selector;
@end

#pragma mark - Background fetch

typedef NS_ENUM(NSUInteger, UIBackgroundFetchResult) {
  UIBackgroundFetchResultNewData = 0,
  UIBackgroundFetchResultNoData = 1,
  UIBackgroundFetchResultFailed = 2,
};

NS_ASSUME_NONNULL_END
