/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIPlatformGaps.h"

#import "UIColor.h"
#import "UIStatusBar.h"
#import "UIView.h"

#import <objc/runtime.h>

const CGFloat UIWindowLevelNormal = 0;
const CGFloat UIWindowLevelAlert = 2000;
const CGFloat UIWindowLevelStatusBar = 1000;

@implementation NSBezierPath (UIKitCompat)

+ (NSBezierPath *)bezierPathWithRoundedRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius
{
  return [NSBezierPath bezierPathWithRoundedRect:NSRectFromCGRect(rect)
                                         xRadius:cornerRadius
                                         yRadius:cornerRadius];
}

- (void)appendPath:(NSBezierPath *)path
{
  [self appendBezierPath:path];
}

@end

@implementation NSScreen (UIKitCompat)

- (CGFloat)scale
{
  return self.backingScaleFactor;
}

- (NSScreen *)coordinateSpace
{
  return self;
}

- (CGRect)bounds
{
  return NSRectToCGRect(self.frame);
}

@end

static NSAppearance *_Nullable UIKitCompatAppearanceForStyle(UIUserInterfaceStyle style);

@implementation NSWindow (UIKitCompat)

- (instancetype)initWithFrame:(CGRect)frame
{
  return [self initWithContentRect:NSRectFromCGRect(frame)
                         styleMask:NSWindowStyleMaskBorderless
                           backing:NSBackingStoreBuffered
                             defer:NO];
}

- (CGFloat)windowLevel
{
  return (CGFloat)self.level;
}

- (void)setWindowLevel:(CGFloat)level
{
  self.level = (NSWindowLevel)level;
}

- (UIWindowScene *)windowScene
{
  return objc_getAssociatedObject(self, @selector(windowScene));
}

- (void)setWindowScene:(UIWindowScene *)windowScene
{
  objc_setAssociatedObject(self, @selector(windowScene), windowScene, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIUserInterfaceStyle)overrideUserInterfaceStyle
{
  NSNumber *stored = objc_getAssociatedObject(self, @selector(overrideUserInterfaceStyle));
  return stored == nil ? UIUserInterfaceStyleUnspecified : (UIUserInterfaceStyle)stored.integerValue;
}

- (void)setOverrideUserInterfaceStyle:(UIUserInterfaceStyle)style
{
  objc_setAssociatedObject(
      self, @selector(overrideUserInterfaceStyle), @(style), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  self.appearance = UIKitCompatAppearanceForStyle(style);
}

@end

@implementation NSImage (UIKitCompatCGImage)

- (instancetype)initWithCGImage:(CGImageRef)cgImage scale:(CGFloat)scale orientation:(__unused NSInteger)orientation
{
  if (cgImage == NULL) {
    return nil;
  }
  CGFloat effectiveScale = scale > 0 ? scale : 1.0;
  NSSize size = NSMakeSize(CGImageGetWidth(cgImage) / effectiveScale, CGImageGetHeight(cgImage) / effectiveScale);
  return [self initWithCGImage:cgImage size:size];
}

@end

// Overriding -tag from a category is the intent here, not an accident: see the
// header for why both halves are needed.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation NSView (UIKitCompatTag)

- (NSInteger)tag
{
  NSNumber *stored = objc_getAssociatedObject(self, @selector(tag));
  // -1 is what NSView itself answers when nothing has claimed a tag.
  return stored == nil ? -1 : stored.integerValue;
}

- (void)setTag:(NSInteger)tag
{
  objc_setAssociatedObject(self, @selector(tag), @(tag), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma clang diagnostic pop

@implementation NSView (UIKitCompatTint)

- (NSColor *)tintColor
{
  return objc_getAssociatedObject(self, @selector(tintColor));
}

- (void)setTintColor:(NSColor *)tintColor
{
  objc_setAssociatedObject(self, @selector(tintColor), tintColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  if ([self respondsToSelector:@selector(setContentTintColor:)]) {
    [(id)self setContentTintColor:tintColor];
  }
}

@end

@implementation RCTUIKitCompatHoverGestureRecognizer
@end

@implementation NSGestureRecognizer (UIKitCompat)

- (BOOL)cancelsTouchesInView
{
  return [objc_getAssociatedObject(self, @selector(cancelsTouchesInView)) boolValue];
}

- (void)setCancelsTouchesInView:(BOOL)value
{
  objc_setAssociatedObject(self, @selector(cancelsTouchesInView), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)delaysTouchesBegan
{
  return [objc_getAssociatedObject(self, @selector(delaysTouchesBegan)) boolValue];
}

- (void)setDelaysTouchesBegan:(BOOL)value
{
  objc_setAssociatedObject(self, @selector(delaysTouchesBegan), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)delaysTouchesEnded
{
  return [objc_getAssociatedObject(self, @selector(delaysTouchesEnded)) boolValue];
}

- (void)setDelaysTouchesEnded:(BOOL)value
{
  objc_setAssociatedObject(self, @selector(delaysTouchesEnded), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation NSPasteboard (UIKitCompat)

- (NSString *)string
{
  return [self stringForType:NSPasteboardTypeString];
}

- (void)setString:(NSString *)string
{
  [self clearContents];
  if (string != nil) {
    [self setString:string forType:NSPasteboardTypeString];
  }
}

@end

@implementation NSImage (UIKitCompatResizing)

- (NSArray<NSImage *> *)images
{
  // NSImage has no animation model; an animated asset is a single image with
  // multiple representations, not a frame list.
  return nil;
}

- (NSImage *)resizableImageWithCapInsets:(UIEdgeInsets)capInsets
{
  return [self resizableImageWithCapInsets:capInsets resizingMode:0];
}

- (NSImage *)resizableImageWithCapInsets:(UIEdgeInsets)capInsets resizingMode:(__unused NSInteger)resizingMode
{
  // AppKit's nine-part stretching is a property of the image, not a new object.
  self.capInsets = NSEdgeInsetsMake(capInsets.top, capInsets.left, capInsets.bottom, capInsets.right);
  self.resizingMode = NSImageResizingModeStretch;
  return self;
}

@end

@implementation NSImage (UIKitCompatDrawing)

- (void)drawAtPoint:(CGPoint)point
{
  [self drawAtPoint:NSPointFromCGPoint(point) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
}

+ (NSImage *)systemImageNamed:(NSString *)name
{
  if (@available(macOS 11.0, *)) {
    return [NSImage imageWithSystemSymbolName:name accessibilityDescription:nil];
  }
  return nil;
}

@end

// UIScene and UIWindowScene are declared in UIKitDefines.h so upstream scene
// pointers resolve. They are never instantiated, but a category needs the class
// to exist at link time, so the implementations live here.
@implementation RCTUIKitCompatWindowScene
@end

@implementation RCTUIKitCompatWindowScene (UIKitCompatCoordinateSpace)

- (NSScreen *)coordinateSpace
{
  return NSScreen.mainScreen;
}

- (NSScreen *)screen
{
  return NSScreen.mainScreen;
}

- (NSArray<NSWindow *> *)windows
{
  return NSApp.windows ?: @[];
}

- (NSWindow *)keyWindow
{
  return NSApp.keyWindow ?: NSApp.mainWindow;
}

- (id)statusBarManager
{
  return [UIStatusBarManager new];
}

@end

@implementation RCTUIKitCompatScene

- (UISceneActivationState)activationState
{
  return NSApp.isActive ? UISceneActivationStateForegroundActive : UISceneActivationStateForegroundInactive;
}

@end

@implementation NSWindow (UIKitCompatBounds)

- (CGRect)bounds
{
  NSRect frame = self.frame;
  return CGRectMake(0, 0, frame.size.width, frame.size.height);
}

- (UIEdgeInsets)safeAreaInsets
{
  // No notch, no home indicator.
  return UIEdgeInsetsZero;
}

- (CGFloat)alpha
{
  return self.alphaValue;
}

- (void)setAlpha:(CGFloat)alpha
{
  self.alphaValue = alpha;
}

- (NSColor *)backgroundColorForUIKitCompat
{
  return self.backgroundColor;
}

- (void)setBackgroundColorForUIKitCompat:(NSColor *)color
{
  self.backgroundColor = color;
}

- (CALayer *)layer
{
  // Windows draw through their content view's layer.
  self.contentView.wantsLayer = YES;
  return self.contentView.layer;
}

- (void)addSubview:(NSView *)view
{
  if (self.contentView == nil) {
    self.contentView = [[NSView alloc] initWithFrame:NSRectFromCGRect(self.bounds)];
  }
  [self.contentView addSubview:view];
}

- (NSView *)hitTest:(CGPoint)point withEvent:(__unused UIEvent *)event
{
  return [self.contentView hitTest:NSPointFromCGPoint(point)];
}

@end

@implementation NSViewController (UIKitCompatDismissal)

- (BOOL)isBeingDismissed
{
  return NO;
}

- (BOOL)isBeingPresented
{
  return self.presentingViewController != nil;
}

@end

@implementation NSWindow (UIKitCompatLayout)

- (void)layoutSubviews
{
  [self.contentView layoutSubviews];
}

- (void)setNeedsLayout
{
  self.contentView.needsLayout = YES;
}

- (void)makeKeyAndVisible
{
  [self makeKeyAndOrderFront:nil];
}

- (CGPoint)convertPoint:(CGPoint)point toView:(NSView *)view
{
  NSPoint inWindow = NSPointFromCGPoint(point);
  return view == nil ? point : NSPointToCGPoint([view convertPoint:inWindow fromView:nil]);
}

- (CGPoint)convertPoint:(CGPoint)point fromView:(NSView *)view
{
  NSPoint p = NSPointFromCGPoint(point);
  return view == nil ? point : NSPointToCGPoint([view convertPoint:p toView:nil]);
}

@end

@implementation NSWindow (UIKitCompatRootViewController)

- (NSViewController *)rootViewController
{
  return self.contentViewController;
}

- (void)setRootViewController:(NSViewController *)rootViewController
{
  // Assigning -contentViewController makes NSWindow resize itself to fit that
  // controller's view. UIWindow does the opposite: the window keeps its frame
  // and the root view is stretched to fill it.
  //
  // React Native's root view has no useful size when it is installed -- Fabric
  // has not laid anything out yet -- so the AppKit behaviour collapses the
  // window to a point, and the app runs with nothing on screen. Keep the frame
  // the caller chose, and let the view follow it.
  NSRect frame = self.frame;
  self.contentViewController = rootViewController;
  if (!NSIsEmptyRect(frame)) {
    [self setFrame:frame display:YES];
    rootViewController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    rootViewController.view.frame = self.contentLayoutRect;
  }
}

- (instancetype)initWithWindowScene:(__unused id)windowScene
{
  // There are no scenes on macOS; fall back to a borderless window.
  return [self initWithFrame:CGRectZero];
}

@end

@implementation NSView (UIKitCompatAccessibilityElement)

- (void)setIsAccessibilityElement:(BOOL)isAccessibilityElement
{
  self.accessibilityElement = isAccessibilityElement;
}

@end

@implementation NSViewController (UIKitCompatPresentation)

- (UIModalPresentationStyle)modalPresentationStyle
{
  // AppKit presents sheets and popovers, not full screens; the value is stored
  // for round-tripping and does not change presentation.
  NSNumber *stored = objc_getAssociatedObject(self, @selector(modalPresentationStyle));
  return stored == nil ? UIModalPresentationFullScreen : (UIModalPresentationStyle)stored.integerValue;
}

- (void)setModalPresentationStyle:(UIModalPresentationStyle)style
{
  objc_setAssociatedObject(self, @selector(modalPresentationStyle), @(style), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#define UIKIT_COMPAT_BOOL_PROP(name, setter)                                                        \
  -(BOOL)name                                                                                       \
  {                                                                                                 \
    return [objc_getAssociatedObject(self, @selector(name)) boolValue];                             \
  }                                                                                                 \
  -(void)setter : (BOOL)value                                                                       \
  {                                                                                                 \
    objc_setAssociatedObject(self, @selector(name), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);   \
  }

@implementation NSView (UIKitCompatAccessibilityGaps)

- (BOOL)accessibilityElementsHidden
{
  return [objc_getAssociatedObject(self, @selector(accessibilityElementsHidden)) boolValue];
}

- (void)setAccessibilityElementsHidden:(BOOL)hidden
{
  objc_setAssociatedObject(self, @selector(accessibilityElementsHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  // The closest AppKit behaviour: drop the subtree from the accessibility tree.
  self.accessibilityChildren = hidden ? @[] : nil;
}

UIKIT_COMPAT_BOOL_PROP(accessibilityIgnoresInvertColors, setAccessibilityIgnoresInvertColors)
UIKIT_COMPAT_BOOL_PROP(accessibilityViewIsModal, setAccessibilityViewIsModal)
UIKIT_COMPAT_BOOL_PROP(shouldGroupAccessibilityChildren, setShouldGroupAccessibilityChildren)
UIKIT_COMPAT_BOOL_PROP(isAccessibilityElementByDefault, setIsAccessibilityElementByDefault)
UIKIT_COMPAT_BOOL_PROP(multipleTouchEnabled, setMultipleTouchEnabled)
UIKIT_COMPAT_BOOL_PROP(exclusiveTouch, setExclusiveTouch)

@end

@implementation NSApplication (UIKitCompatOpenURL)

- (void)openURL:(NSURL *)url
              options:(__unused NSDictionary<NSString *, id> *)options
    completionHandler:(void (^)(BOOL))completion
{
  BOOL opened = [NSWorkspace.sharedWorkspace openURL:url];
  if (completion) {
    completion(opened);
  }
}

- (NSSet *)connectedScenes
{
  // No scene model on macOS.
  return [NSSet set];
}

@end

@implementation NSWindow (UIKitCompatConvertRect)

- (CGRect)convertRect:(CGRect)rect toView:(NSView *)view
{
  return view == nil ? rect : NSRectToCGRect([view convertRect:NSRectFromCGRect(rect) fromView:nil]);
}

- (CGRect)convertRect:(CGRect)rect fromView:(NSView *)view
{
  return view == nil ? rect : NSRectToCGRect([view convertRect:NSRectFromCGRect(rect) toView:nil]);
}

- (CGRect)convertRect:(CGRect)rect fromCoordinateSpace:(id)coordinateSpace
{
  if ([coordinateSpace isKindOfClass:[NSView class]]) {
    return [self convertRect:rect fromView:(NSView *)coordinateSpace];
  }
  // The screen is the only other coordinate space upstream uses.
  return NSRectToCGRect([self convertRectFromScreen:NSRectFromCGRect(rect)]);
}

- (CGRect)convertRect:(CGRect)rect toCoordinateSpace:(id)coordinateSpace
{
  if ([coordinateSpace isKindOfClass:[NSView class]]) {
    return [self convertRect:rect toView:(NSView *)coordinateSpace];
  }
  return NSRectToCGRect([self convertRectToScreen:NSRectFromCGRect(rect)]);
}

- (BOOL)isHidden
{
  return !self.isVisible;
}

- (void)setHidden:(BOOL)hidden
{
  if (hidden) {
    [self orderOut:nil];
  } else {
    [self orderFront:nil];
  }
}

@end

static NSAppearance *_Nullable UIKitCompatAppearanceForStyle(UIUserInterfaceStyle style)
{
  switch (style) {
    case UIUserInterfaceStyleLight:
      return [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    case UIUserInterfaceStyleDark:
      return [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    case UIUserInterfaceStyleUnspecified:
    default:
      return nil;  // inherit
  }
}

@implementation NSView (UIKitCompatCallbacks)

- (void)safeAreaInsetsDidChange
{
  // There is no safe area to change on macOS.
}

- (void)traitCollectionDidChange:(__unused id)previousTraitCollection
{
  // Driven by -viewDidChangeEffectiveAppearance on RCTUIView.
}

- (CGSize)sizeThatFits:(CGSize)size
{
  // UIKit's default is to answer the current size; AppKit's fittingSize is the
  // nearest thing when the view has constraints.
  NSSize fitting = self.fittingSize;
  return (fitting.width > 0 || fitting.height > 0) ? NSSizeToCGSize(fitting) : size;
}

- (BOOL)isOpaqueForUIKitCompat
{
  return [objc_getAssociatedObject(self, @selector(opaque)) boolValue];
}

- (void)setOpaque:(BOOL)opaque
{
  objc_setAssociatedObject(self, @selector(opaque), @(opaque), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  self.layer.opaque = opaque;
}

- (NSArray *)focusItemsInRect:(__unused CGRect)rect
{
  // The focus engine is a tvOS/iPadOS concept; AppKit uses the key view loop.
  return @[];
}

- (BOOL)endEditing:(__unused BOOL)force
{
  return [self.window makeFirstResponder:nil];
}

- (void)reloadInputViews
{
}

- (void)setContentHuggingPriority:(UILayoutPriority)priority forAxis:(NSInteger)axis
{
  [self setContentHuggingPriority:priority forOrientation:(NSLayoutConstraintOrientation)axis];
}

- (void)setContentCompressionResistancePriority:(UILayoutPriority)priority forAxis:(NSInteger)axis
{
  [self setContentCompressionResistancePriority:priority
                                 forOrientation:(NSLayoutConstraintOrientation)axis];
}

- (NSView *)snapshotViewAfterScreenUpdates:(__unused BOOL)afterUpdates
{
  NSBitmapImageRep *rep = [self bitmapImageRepForCachingDisplayInRect:self.bounds];
  if (rep == nil) {
    return nil;
  }
  [self cacheDisplayInRect:self.bounds toBitmapImageRep:rep];
  NSImageView *snapshot = [[NSImageView alloc] initWithFrame:self.bounds];
  NSImage *image = [[NSImage alloc] initWithSize:self.bounds.size];
  [image addRepresentation:rep];
  snapshot.image = image;
  return snapshot;
}

- (BOOL)drawViewHierarchyInRect:(CGRect)rect afterScreenUpdates:(__unused BOOL)afterUpdates
{
  NSBitmapImageRep *rep = [self bitmapImageRepForCachingDisplayInRect:NSRectFromCGRect(rect)];
  if (rep == nil) {
    return NO;
  }
  [self cacheDisplayInRect:NSRectFromCGRect(rect) toBitmapImageRep:rep];
  [rep drawInRect:NSRectFromCGRect(rect)];
  return YES;
}

UIKIT_COMPAT_BOOL_PROP(showsLargeContentViewer, setShowsLargeContentViewer)
UIKIT_COMPAT_BOOL_PROP(scalesLargeContentImage, setScalesLargeContentImage)

- (NSString *)largeContentTitle
{
  return objc_getAssociatedObject(self, @selector(largeContentTitle));
}

- (void)setLargeContentTitle:(NSString *)title
{
  objc_setAssociatedObject(self, @selector(largeContentTitle), title, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSImage *)largeContentImage
{
  return objc_getAssociatedObject(self, @selector(largeContentImage));
}

- (void)setLargeContentImage:(NSImage *)image
{
  objc_setAssociatedObject(self, @selector(largeContentImage), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation NSView (UIKitCompatUserInterfaceStyle)

- (UIUserInterfaceStyle)overrideUserInterfaceStyle
{
  NSNumber *stored = objc_getAssociatedObject(self, @selector(overrideUserInterfaceStyle));
  return stored == nil ? UIUserInterfaceStyleUnspecified : (UIUserInterfaceStyle)stored.integerValue;
}

- (void)setOverrideUserInterfaceStyle:(UIUserInterfaceStyle)style
{
  objc_setAssociatedObject(
      self, @selector(overrideUserInterfaceStyle), @(style), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  self.appearance = UIKitCompatAppearanceForStyle(style);
}

- (NSInteger)accessibilityTraits
{
  NSNumber *stored = objc_getAssociatedObject(self, @selector(accessibilityTraits));
  return stored == nil ? 0 : stored.integerValue;
}

- (void)setAccessibilityTraits:(NSInteger)traits
{
  // AppKit expresses these as a role and subrole, which the view layer maps.
  // Stored here so the value round-trips.
  objc_setAssociatedObject(self, @selector(accessibilityTraits), @(traits), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation NSViewController (UIKitCompatAppearance)

- (UIUserInterfaceStyle)overrideUserInterfaceStyle
{
  NSNumber *stored = objc_getAssociatedObject(self, @selector(overrideUserInterfaceStyle));
  return stored == nil ? UIUserInterfaceStyleUnspecified : (UIUserInterfaceStyle)stored.integerValue;
}

- (void)setOverrideUserInterfaceStyle:(UIUserInterfaceStyle)style
{
  objc_setAssociatedObject(
      self, @selector(overrideUserInterfaceStyle), @(style), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  self.view.appearance = UIKitCompatAppearanceForStyle(style);
}

- (NSInteger)modalTransitionStyle
{
  return [objc_getAssociatedObject(self, @selector(modalTransitionStyle)) integerValue];
}

- (void)setModalTransitionStyle:(NSInteger)style
{
  // AppKit sheets have one presentation animation; stored for round-tripping.
  objc_setAssociatedObject(self, @selector(modalTransitionStyle), @(style), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)modalInPresentation
{
  return [objc_getAssociatedObject(self, @selector(modalInPresentation)) boolValue];
}

- (void)setModalInPresentation:(BOOL)value
{
  objc_setAssociatedObject(self, @selector(modalInPresentation), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIPresentationController *)presentationController
{
  UIPresentationController *controller = objc_getAssociatedObject(self, @selector(presentationController));
  if (controller == nil) {
    controller = [UIPresentationController new];
    objc_setAssociatedObject(
        self, @selector(presentationController), controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return controller;
}

- (UIPresentationController *)popoverPresentationController
{
  return self.presentationController;
}

- (id)delegate
{
  return objc_getAssociatedObject(self, @selector(delegate));
}

- (void)setDelegate:(id)delegate
{
  objc_setAssociatedObject(self, @selector(delegate), delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (void)viewWillLayoutSubviews
{
}

@end

@implementation NSGestureRecognizer (UIKitCompatTouches)

- (void)touchesBegan:(__unused NSSet *)touches withEvent:(__unused UIEvent *)event
{
}

- (void)touchesMoved:(__unused NSSet *)touches withEvent:(__unused UIEvent *)event
{
}

- (void)touchesEnded:(__unused NSSet *)touches withEvent:(__unused UIEvent *)event
{
}

- (void)touchesCancelled:(__unused NSSet *)touches withEvent:(__unused UIEvent *)event
{
}

- (void)reset
{
}

@end

@implementation NSView (UIKitCompatSubviewOrdering)

- (void)insertSubview:(NSView *)view aboveSubview:(NSView *)siblingSubview
{
  [self addSubview:view positioned:NSWindowAbove relativeTo:siblingSubview];
}

- (void)insertSubview:(NSView *)view belowSubview:(NSView *)siblingSubview
{
  [self addSubview:view positioned:NSWindowBelow relativeTo:siblingSubview];
}

@end

@implementation NSStackView (UIKitCompatAxis)

- (NSInteger)axis
{
  return (NSInteger)self.orientation;
}

- (void)setAxis:(NSInteger)axis
{
  self.orientation = (NSUserInterfaceLayoutOrientation)axis;
}

@end

@implementation RCTUIKitCompatLargeContentViewerInteraction
@end

@implementation NSColor (UIKitCompatTraitResolution)

- (NSColor *)resolvedColorWithTraitCollection:(__unused id)traitCollection
{
  // The appearance-aware resolution already lives in the UIColor category.
  return [self resolvedColorWithAppearance:NSApp.effectiveAppearance];
}

@end

@implementation NSGestureRecognizer (UIKitCompatLocation)

- (NSUInteger)numberOfTouches
{
  // A mouse is one pointer.
  return 1;
}

- (CGPoint)locationOfTouch:(__unused NSUInteger)touchIndex inView:(NSView *)view
{
  return NSPointToCGPoint([self locationInView:view]);
}

@end

@implementation NSViewController (UIKitCompatModal)

- (void)presentViewController:(NSViewController *)viewController
                     animated:(__unused BOOL)animated
                   completion:(void (^)(void))completion
{
  // AppKit's nearest equivalent is a sheet.
  [self presentViewControllerAsSheet:viewController];
  objc_setAssociatedObject(
      self, @selector(presentedViewController), viewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  if (completion) {
    completion();
  }
}

- (void)dismissViewControllerAnimated:(__unused BOOL)animated completion:(void (^)(void))completion
{
  NSViewController *presented = objc_getAssociatedObject(self, @selector(presentedViewController));
  if (presented != nil) {
    [self dismissViewController:presented];
    objc_setAssociatedObject(self, @selector(presentedViewController), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  if (completion) {
    completion();
  }
}

- (NSViewController *)presentedViewController
{
  return objc_getAssociatedObject(self, @selector(presentedViewController));
}

@end

@implementation NSFont (UIKitCompatFamilies)

+ (NSArray<NSString *> *)fontNamesForFamilyName:(NSString *)familyName
{
  NSMutableArray<NSString *> *names = [NSMutableArray new];
  for (NSArray *member in [NSFontManager.sharedFontManager availableMembersOfFontFamily:familyName]) {
    if (member.firstObject != nil) {
      [names addObject:member.firstObject];
    }
  }
  return names;
}

+ (NSArray<NSString *> *)familyNames
{
  return NSFontManager.sharedFontManager.availableFontFamilies;
}

- (CGFloat)lineHeight
{
  return ceil(self.ascender + ABS(self.descender) + self.leading);
}

+ (NSFont *)preferredFontForTextStyle:(NSString *)textStyle
{
  // Sizes follow AppKit's own conventions rather than iOS's Dynamic Type ramp.
  CGFloat size = NSFont.systemFontSize;
  if ([textStyle containsString:@"LargeTitle"]) {
    size = 26;
  } else if ([textStyle containsString:@"Title1"]) {
    size = 22;
  } else if ([textStyle containsString:@"Title2"]) {
    size = 17;
  } else if ([textStyle containsString:@"Title3"]) {
    size = 15;
  } else if ([textStyle containsString:@"Headline"]) {
    size = NSFont.systemFontSize;
  } else if ([textStyle containsString:@"Caption"] || [textStyle containsString:@"Footnote"]) {
    size = NSFont.smallSystemFontSize;
  }
  BOOL bold = [textStyle containsString:@"Headline"] || [textStyle containsString:@"Title"];
  return bold ? [NSFont boldSystemFontOfSize:size] : [NSFont systemFontOfSize:size];
}

@end

@implementation NSView (UIKitCompatSemanticContent)

- (UISemanticContentAttribute)semanticContentAttribute
{
  switch (self.userInterfaceLayoutDirection) {
    case NSUserInterfaceLayoutDirectionRightToLeft:
      return UISemanticContentAttributeForceRightToLeft;
    case NSUserInterfaceLayoutDirectionLeftToRight:
    default:
      return UISemanticContentAttributeForceLeftToRight;
  }
}

- (void)setSemanticContentAttribute:(UISemanticContentAttribute)attribute
{
  switch (attribute) {
    case UISemanticContentAttributeForceRightToLeft:
      self.userInterfaceLayoutDirection = NSUserInterfaceLayoutDirectionRightToLeft;
      break;
    case UISemanticContentAttributeForceLeftToRight:
      self.userInterfaceLayoutDirection = NSUserInterfaceLayoutDirectionLeftToRight;
      break;
    default:
      // Unspecified means "inherit", which is AppKit's own default.
      break;
  }
}

@end

@implementation NSView (UIKitCompatCoordinateSpace)

- (CGPoint)convertPoint:(CGPoint)point toCoordinateSpace:(id)coordinateSpace
{
  if ([coordinateSpace isKindOfClass:[NSView class]]) {
    return NSPointToCGPoint([self convertPoint:NSPointFromCGPoint(point) toView:(NSView *)coordinateSpace]);
  }
  // The only non-view coordinate space upstream uses is the screen.
  NSPoint inWindow = [self convertPoint:NSPointFromCGPoint(point) toView:nil];
  return NSPointToCGPoint([self.window convertPointToScreen:inWindow]);
}

- (CGPoint)convertPoint:(CGPoint)point fromCoordinateSpace:(id)coordinateSpace
{
  if ([coordinateSpace isKindOfClass:[NSView class]]) {
    return NSPointToCGPoint([self convertPoint:NSPointFromCGPoint(point) fromView:(NSView *)coordinateSpace]);
  }
  NSPoint inWindow = [self.window convertPointFromScreen:NSPointFromCGPoint(point)];
  return NSPointToCGPoint([self convertPoint:inWindow fromView:nil]);
}

@end

@implementation NSViewController (UIKitCompat)

- (void)viewDidLayoutSubviews
{
  // Overridden by React Native's controllers. Bridged from -viewDidLayout by
  // those subclasses; a no-op here so any controller can be sent it.
}

- (void)viewWillAppear:(__unused BOOL)animated
{
  [self viewWillAppear];
}

- (void)viewDidAppear:(__unused BOOL)animated
{
  [self viewDidAppear];
}

- (void)viewWillDisappear:(__unused BOOL)animated
{
  [self viewWillDisappear];
}

- (void)viewDidDisappear:(__unused BOOL)animated
{
  [self viewDidDisappear];
}

@end

UIFontTextStyle const UIFontTextStyleBody = @"UICTFontTextStyleBody";
UIFontTextStyle const UIFontTextStyleCallout = @"UICTFontTextStyleCallout";
UIFontTextStyle const UIFontTextStyleCaption1 = @"UICTFontTextStyleCaption1";
UIFontTextStyle const UIFontTextStyleCaption2 = @"UICTFontTextStyleCaption2";
UIFontTextStyle const UIFontTextStyleFootnote = @"UICTFontTextStyleFootnote";
UIFontTextStyle const UIFontTextStyleHeadline = @"UICTFontTextStyleHeadline";
UIFontTextStyle const UIFontTextStyleSubheadline = @"UICTFontTextStyleSubhead";
UIFontTextStyle const UIFontTextStyleLargeTitle = @"UICTFontTextStyleLargeTitle";
UIFontTextStyle const UIFontTextStyleTitle1 = @"UICTFontTextStyleTitle1";
UIFontTextStyle const UIFontTextStyleTitle2 = @"UICTFontTextStyleTitle2";
UIFontTextStyle const UIFontTextStyleTitle3 = @"UICTFontTextStyleTitle3";

@implementation RCTUIKitCompatFontMetrics

+ (UIFontMetrics *)defaultMetrics
{
  return [UIFontMetrics new];
}

+ (instancetype)metricsForTextStyle:(__unused NSString *)textStyle
{
  return [UIFontMetrics new];
}

- (NSFont *)scaledFontForFont:(NSFont *)font
{
  // No Dynamic Type on macOS.
  return font;
}

- (CGFloat)scaledValueForValue:(CGFloat)value
{
  return value;
}

@end

// QuartzCore does declare +displayLinkWithTarget:selector:, but marks it
// API_UNAVAILABLE(macos), so calling it is a hard error. Redefining it in a
// category is the intent here, not an accident.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation CADisplayLink (UIKitCompat)

+ (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)selector
{
  if (@available(macOS 14.0, *)) {
    NSScreen *screen = NSScreen.mainScreen;
    if (screen != nil) {
      return [screen displayLinkWithTarget:target selector:selector];
    }
  }
  // Below macOS 14 there is no CADisplayLink to vend. Callers fall back to a
  // timer, which is the same path they take on iOS when a link is unavailable.
  return nil;
}

@end

#pragma clang diagnostic pop
