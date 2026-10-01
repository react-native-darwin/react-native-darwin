/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * The platform type vocabulary, naming no UIKit type.
 *
 * This is the half of the compatibility layer that is safe to make public.
 * The other half -- <UIKit/UIKit.h>, which declares `UIView` and forty-odd
 * more -- is not: `@compatibility_alias` is a hard error on redefinition, so
 * any library declaring the same names cannot coexist with it in one
 * translation unit. expo-modules-core declares exactly those names, for
 * exactly the same reason, and fails to compile.
 *
 * So the names an *installed* header is allowed to use live here. They are the
 * same names react-native-macos uses, so third-party code written against that
 * fork compiles unchanged -- and because nothing below mentions UIKit, this
 * header can go on every pod's search path without claiming anything.
 *
 * See macos/PLAN-drop-uikit-aliases.md.
 */

#pragma once

#import <TargetConditionals.h>

#if TARGET_OS_OSX

#import <AppKit/AppKit.h>

// The declarations below came from headers that were inside this region.
// Imports must stay above it: clang rejects an #include inside one.
NS_ASSUME_NONNULL_BEGIN

@compatibility_alias RCTUIColor NSColor;
@compatibility_alias RCTPlatformColor NSColor;
@compatibility_alias RCTUIImage NSImage;
@compatibility_alias RCTPlatformImage NSImage;
@compatibility_alias RCTPlatformView NSView;
@compatibility_alias RCTPlatformWindow NSWindow;
@compatibility_alias RCTPlatformViewController NSViewController;

// Forward declarations are enough here. An installed header only needs the
// type to exist, never to be complete -- it spells pointers and nothing
// else. The interfaces stay in the private shim.
@class RCTUIKitCompatAccessibilityElement;
@class RCTUIKitCompatActivityIndicatorView;
@class RCTUIKitCompatAlertController;
@class RCTUIKitCompatFontMetrics;
@class RCTUIKitCompatGraphicsImageRenderer;
@class RCTUIKitCompatGraphicsImageRendererContext;
@class RCTUIKitCompatGraphicsImageRendererFormat;
@class RCTUIKitCompatImageView;
@class RCTUIKitCompatKeyCommand;
@class RCTUIKitCompatLabel;
@class RCTUIKitCompatScrollView;
@class RCTUIKitCompatSlider;
@class RCTUIKitCompatStatusBarManager;
@class RCTUIKitCompatSwitch;
@class RCTUIKitCompatTextField;
@class RCTUIKitCompatTextInputPasswordRules;
@class RCTUIKitCompatTextRange;
@class RCTUIKitCompatTextView;
@class RCTUIKitCompatTouch;
@class RCTUIKitCompatTraitCollection;

@compatibility_alias RCTPlatformAccessibilityElement RCTUIKitCompatAccessibilityElement;
@compatibility_alias RCTPlatformActivityIndicatorView RCTUIKitCompatActivityIndicatorView;
@compatibility_alias RCTPlatformAlertController RCTUIKitCompatAlertController;
@compatibility_alias RCTPlatformApplication NSApplication;
@compatibility_alias RCTPlatformBezierPath NSBezierPath;
@compatibility_alias RCTPlatformEvent NSEvent;
@compatibility_alias RCTPlatformFont NSFont;
@compatibility_alias RCTPlatformFontMetrics RCTUIKitCompatFontMetrics;
@compatibility_alias RCTPlatformGestureRecognizer NSGestureRecognizer;
@compatibility_alias RCTPlatformGraphicsImageRenderer RCTUIKitCompatGraphicsImageRenderer;
@compatibility_alias RCTPlatformGraphicsImageRendererContext RCTUIKitCompatGraphicsImageRendererContext;
@compatibility_alias RCTPlatformGraphicsImageRendererFormat RCTUIKitCompatGraphicsImageRendererFormat;
@compatibility_alias RCTPlatformImageView RCTUIKitCompatImageView;
@compatibility_alias RCTPlatformKeyCommand RCTUIKitCompatKeyCommand;
@compatibility_alias RCTPlatformLabel RCTUIKitCompatLabel;
@compatibility_alias RCTPlatformPanGestureRecognizer NSPanGestureRecognizer;
@compatibility_alias RCTPlatformResponder NSResponder;
@compatibility_alias RCTPlatformScrollView RCTUIKitCompatScrollView;
@compatibility_alias RCTPlatformSlider RCTUIKitCompatSlider;
@compatibility_alias RCTPlatformStatusBarManager RCTUIKitCompatStatusBarManager;
@compatibility_alias RCTPlatformSwitch RCTUIKitCompatSwitch;
@compatibility_alias RCTPlatformTextField RCTUIKitCompatTextField;
@compatibility_alias RCTPlatformTextInputPasswordRules RCTUIKitCompatTextInputPasswordRules;
@compatibility_alias RCTPlatformTextRange RCTUIKitCompatTextRange;
@compatibility_alias RCTPlatformTextView RCTUIKitCompatTextView;
@compatibility_alias RCTPlatformTouch RCTUIKitCompatTouch;
@compatibility_alias RCTPlatformTraitCollection RCTUIKitCompatTraitCollection;

typedef uint64_t RCTPlatformAccessibilityTraits;
typedef NSEdgeInsets RCTPlatformEdgeInsets;
// Not every UIKit name in an installed header is a type. This one is a
// function, and a third-party pod compiling our headers has no more access to
// it than to UIView.
#define RCTPlatformEdgeInsetsEqualToEdgeInsets NSEdgeInsetsEqual

// The UIKit geometry vocabulary, given to everybody.
//
// Only @compatibility_alias and @protocol cannot be declared twice; a typedef,
// a macro and an inline function all can, as long as the declarations match.
// So the names below are safe to put on every pod's search path even though
// they are UIKit's, and third-party code written against react-native-macos --
// which expects React Native to provide them -- compiles unchanged.
typedef NSEdgeInsets UIEdgeInsets;

#define UIEdgeInsetsZero NSEdgeInsetsZero
#define UIViewNoIntrinsicMetric NSViewNoIntrinsicMetric

NS_INLINE UIEdgeInsets UIEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right)
{
  return NSEdgeInsetsMake(top, left, bottom, right);
}

NS_INLINE CGRect UIEdgeInsetsInsetRect(CGRect rect, UIEdgeInsets insets)
{
  rect.origin.x += insets.left;
  rect.origin.y += insets.top;
  rect.size.width -= (insets.left + insets.right);
  rect.size.height -= (insets.top + insets.bottom);
  return rect;
}

NS_INLINE BOOL UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsets a, UIEdgeInsets b)
{
  return NSEdgeInsetsEqual(a, b);
}
typedef NSFontWeight RCTPlatformFontWeight;
typedef NSEventModifierFlags RCTPlatformKeyModifierFlags;
typedef NSUserInterfaceLayoutDirection RCTPlatformUserInterfaceLayoutDirection;

// Enumerations. The definition lives here, under the neutral names, and the
// private shim derives the UIKit spelling from it -- the reverse of the
// iOS branch, where UIKit owns the definition.

typedef NS_ENUM(NSInteger, RCTPlatformTextFieldViewMode) {
  RCTPlatformTextFieldViewModeNever = 0,
  RCTPlatformTextFieldViewModeWhileEditing,
  RCTPlatformTextFieldViewModeUnlessEditing,
  RCTPlatformTextFieldViewModeAlways,
};

typedef NS_ENUM(NSInteger, RCTPlatformViewContentMode) {
  RCTPlatformViewContentModeScaleToFill = 0,
  RCTPlatformViewContentModeScaleAspectFit = 1,
  RCTPlatformViewContentModeScaleAspectFill = 2,
  RCTPlatformViewContentModeRedraw = 3,
  RCTPlatformViewContentModeCenter = 4,
  RCTPlatformViewContentModeTop = 5,
  RCTPlatformViewContentModeBottom = 6,
  RCTPlatformViewContentModeLeft = 7,
  RCTPlatformViewContentModeRight = 8,
  RCTPlatformViewContentModeTopLeft = 9,
  RCTPlatformViewContentModeTopRight = 10,
  RCTPlatformViewContentModeBottomLeft = 11,
  RCTPlatformViewContentModeBottomRight = 12,
};

typedef NS_OPTIONS(NSUInteger, RCTPlatformDataDetectorTypes) {
  RCTPlatformDataDetectorTypeNone = 0,
  RCTPlatformDataDetectorTypePhoneNumber = 1 << 0,
  RCTPlatformDataDetectorTypeLink = 1 << 1,
  RCTPlatformDataDetectorTypeAddress = 1 << 2,
  RCTPlatformDataDetectorTypeCalendarEvent = 1 << 3,
  RCTPlatformDataDetectorTypeShipmentTrackingNumber = 1 << 4,
  RCTPlatformDataDetectorTypeFlightNumber = 1 << 5,
  RCTPlatformDataDetectorTypeLookupSuggestion = 1 << 6,
  RCTPlatformDataDetectorTypeMoney = 1 << 7,
  RCTPlatformDataDetectorTypePhysicalValue = 1 << 8,
  RCTPlatformDataDetectorTypeAll = NSUIntegerMax,
};

typedef NS_OPTIONS(NSUInteger, RCTPlatformInterfaceOrientationMask) {
  RCTPlatformInterfaceOrientationMaskPortrait = 1 << 1,
  RCTPlatformInterfaceOrientationMaskLandscapeLeft = 1 << 4,
  RCTPlatformInterfaceOrientationMaskLandscapeRight = 1 << 3,
  RCTPlatformInterfaceOrientationMaskPortraitUpsideDown = 1 << 2,
  RCTPlatformInterfaceOrientationMaskLandscape = (1 << 3) | (1 << 4),
  RCTPlatformInterfaceOrientationMaskAllButUpsideDown = 0,
  RCTPlatformInterfaceOrientationMaskAll = 0,
};

typedef NS_ENUM(NSInteger, RCTPlatformKeyboardAppearance) {
  RCTPlatformKeyboardAppearanceDefault = 0,
  RCTPlatformKeyboardAppearanceDark,
  RCTPlatformKeyboardAppearanceLight,
};

typedef NS_ENUM(NSInteger, RCTPlatformKeyboardType) {
  RCTPlatformKeyboardTypeDefault = 0,
  RCTPlatformKeyboardTypeASCIICapable,
  RCTPlatformKeyboardTypeNumbersAndPunctuation,
  RCTPlatformKeyboardTypeURL,
  RCTPlatformKeyboardTypeNumberPad,
  RCTPlatformKeyboardTypePhonePad,
  RCTPlatformKeyboardTypeNamePhonePad,
  RCTPlatformKeyboardTypeEmailAddress,
  RCTPlatformKeyboardTypeDecimalPad,
  RCTPlatformKeyboardTypeTwitter,
  RCTPlatformKeyboardTypeWebSearch,
  RCTPlatformKeyboardTypeASCIICapableNumberPad,
};

typedef NS_ENUM(NSInteger, RCTPlatformReturnKeyType) {
  RCTPlatformReturnKeyDefault = 0,
  RCTPlatformReturnKeyGo,
  RCTPlatformReturnKeyGoogle,
  RCTPlatformReturnKeyJoin,
  RCTPlatformReturnKeyNext,
  RCTPlatformReturnKeyRoute,
  RCTPlatformReturnKeySearch,
  RCTPlatformReturnKeySend,
  RCTPlatformReturnKeyYahoo,
  RCTPlatformReturnKeyDone,
  RCTPlatformReturnKeyEmergencyCall,
  RCTPlatformReturnKeyContinue,
};

typedef NS_ENUM(NSInteger, RCTPlatformTextAutocapitalizationType) {
  RCTPlatformTextAutocapitalizationTypeNone = 0,
  RCTPlatformTextAutocapitalizationTypeWords,
  RCTPlatformTextAutocapitalizationTypeSentences,
  RCTPlatformTextAutocapitalizationTypeAllCharacters,
};

typedef NS_ENUM(NSInteger, RCTPlatformTextAutocorrectionType) {
  RCTPlatformTextAutocorrectionTypeDefault = 0,
  RCTPlatformTextAutocorrectionTypeNo,
  RCTPlatformTextAutocorrectionTypeYes,
};

typedef NS_ENUM(NSInteger, RCTPlatformTextSmartInsertDeleteType) {
  RCTPlatformTextSmartInsertDeleteTypeDefault = 0,
  RCTPlatformTextSmartInsertDeleteTypeNo,
  RCTPlatformTextSmartInsertDeleteTypeYes,
};

typedef NS_ENUM(NSInteger, RCTPlatformTextSpellCheckingType) {
  RCTPlatformTextSpellCheckingTypeDefault = 0,
  RCTPlatformTextSpellCheckingTypeNo,
  RCTPlatformTextSpellCheckingTypeYes,
};

typedef NS_ENUM(NSInteger, RCTPlatformModalPresentationStyle) {
  RCTPlatformModalPresentationFullScreen = 0,
  RCTPlatformModalPresentationPageSheet = 1,
  RCTPlatformModalPresentationFormSheet = 2,
  RCTPlatformModalPresentationOverFullScreen = 5,
  RCTPlatformModalPresentationPopover = 7,
};

typedef NS_ENUM(NSInteger, RCTPlatformUserInterfaceStyle) {
  RCTPlatformUserInterfaceStyleUnspecified = 0,
  RCTPlatformUserInterfaceStyleLight = 1,
  RCTPlatformUserInterfaceStyleDark = 2,
};

typedef NS_ENUM(NSInteger, RCTPlatformStatusBarAnimation) {
  RCTPlatformStatusBarAnimationNone = 0,
  RCTPlatformStatusBarAnimationFade,
  RCTPlatformStatusBarAnimationSlide,
};

typedef NS_ENUM(NSInteger, RCTPlatformStatusBarStyle) {
  RCTPlatformStatusBarStyleDefault = 0,
  RCTPlatformStatusBarStyleLightContent = 1,
  RCTPlatformStatusBarStyleDarkContent = 3,
};


// Protocols and the types their members mention. A protocol cannot be
// aliased, so the definition lives here under the neutral name and the
// private shim reaches it through a macro.

@class RCTUIKitCompatTableView;
@compatibility_alias RCTPlatformTableView RCTUIKitCompatTableView;

@class RCTUIKitCompatTextPosition;
@compatibility_alias RCTPlatformTextPosition RCTUIKitCompatTextPosition;

@class RCTUIKitCompatTextSelectionRect;
@compatibility_alias RCTPlatformTextSelectionRect RCTUIKitCompatTextSelectionRect;

@class RCTUIKitCompatTextInputMode;
@compatibility_alias RCTPlatformTextInputMode RCTUIKitCompatTextInputMode;

// 0.88 routes deep links and launch options through the UIScene lifecycle.
// macOS has no scenes, so these types exist only so the scene entry points
// have a signature; they are never instantiated. See RCTIsSceneDelegateApp(),
// which is always NO here.
@class RCTUIKitCompatScene;
@compatibility_alias RCTPlatformScene RCTUIKitCompatScene;

@class RCTUIKitCompatOpenURLContext;
@compatibility_alias RCTPlatformOpenURLContext RCTUIKitCompatOpenURLContext;

@class RCTUIKitCompatSceneConnectionOptions;
@compatibility_alias RCTPlatformSceneConnectionOptions RCTUIKitCompatSceneConnectionOptions;

typedef NSString *RCTPlatformApplicationLaunchOptionsKey NS_TYPED_ENUM;

typedef NSString *RCTPlatformApplicationOpenURLOptionsKey NS_TYPED_ENUM;

typedef NS_ENUM(NSInteger, RCTPlatformTextSmartQuotesType) {
  RCTPlatformTextSmartQuotesTypeDefault = 0,
  RCTPlatformTextSmartQuotesTypeNo,
  RCTPlatformTextSmartQuotesTypeYes,
};

typedef NS_ENUM(NSInteger, RCTPlatformTextSmartDashesType) {
  RCTPlatformTextSmartDashesTypeDefault = 0,
  RCTPlatformTextSmartDashesTypeNo,
  RCTPlatformTextSmartDashesTypeYes,
};

@protocol RCTPlatformTextInputTraits <NSObject>
@optional
@property (nonatomic, assign) RCTPlatformKeyboardType keyboardType;
@property (nonatomic, assign) RCTPlatformReturnKeyType returnKeyType;
@property (nonatomic, assign) RCTPlatformTextAutocapitalizationType autocapitalizationType;
@property (nonatomic, assign) RCTPlatformTextAutocorrectionType autocorrectionType;
@property (nonatomic, assign) RCTPlatformTextSpellCheckingType spellCheckingType;
@property (nonatomic, assign) RCTPlatformKeyboardAppearance keyboardAppearance;
@property (nonatomic, assign) RCTPlatformTextSmartInsertDeleteType smartInsertDeleteType;
@property (nonatomic, assign) RCTPlatformTextSmartQuotesType smartQuotesType;
@property (nonatomic, assign) RCTPlatformTextSmartDashesType smartDashesType;
@property (nonatomic, assign, getter=isSecureTextEntry) BOOL secureTextEntry;
@property (nonatomic, assign) BOOL enablesReturnKeyAutomatically;
@property (nonatomic, copy, nullable) NSString *textContentType;
@property (nonatomic, strong, nullable) id passwordRules;
@end

@protocol RCTPlatformTextInput <RCTPlatformTextInputTraits>
@optional
@property (nonatomic, copy, nullable) RCTPlatformTextRange *selectedTextRange;
@property (nonatomic, readonly) RCTPlatformTextPosition *beginningOfDocument;
@property (nonatomic, readonly) RCTPlatformTextPosition *endOfDocument;
- (nullable NSString *)textInRange:(RCTPlatformTextRange *)range;
- (void)replaceRange:(RCTPlatformTextRange *)range withText:(NSString *)text;
- (NSInteger)offsetFromPosition:(RCTPlatformTextPosition *)from toPosition:(RCTPlatformTextPosition *)toPosition;
- (nullable RCTPlatformTextRange *)textRangeFromPosition:(RCTPlatformTextPosition *)from toPosition:(RCTPlatformTextPosition *)toPosition;
- (nullable RCTPlatformTextPosition *)positionFromPosition:(RCTPlatformTextPosition *)position offset:(NSInteger)offset;
// Caret and selection geometry. NSTextView exposes this through its layout
// manager, so the concrete classes compute it there.
- (CGRect)caretRectForPosition:(RCTPlatformTextPosition *)position;
- (CGRect)firstRectForRange:(RCTPlatformTextRange *)range;
- (NSArray<RCTPlatformTextSelectionRect *> *)selectionRectsForRange:(RCTPlatformTextRange *)range;
// Marked text is the in-progress IME composition. AppKit tracks it on the text
// view itself, so this is nil unless a concrete class overrides it.
@property (nonatomic, readonly, nullable) RCTPlatformTextRange *markedTextRange;
// The active input source. There is no software keyboard on macOS, but the
// current input source still tells you the composition language.
@property (nonatomic, readonly, nullable) RCTPlatformTextInputMode *textInputMode;
@end

@protocol RCTPlatformScrollViewDelegate <NSObject>
@optional
- (void)scrollViewDidScroll:(RCTPlatformScrollView *)scrollView;
- (void)scrollViewWillBeginDragging:(RCTPlatformScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(RCTPlatformScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)scrollViewDidEndDecelerating:(RCTPlatformScrollView *)scrollView;
- (void)scrollViewDidZoom:(RCTPlatformScrollView *)scrollView;
@end

@protocol RCTPlatformTableViewDataSource <NSObject>
@optional
- (NSInteger)tableView:(RCTPlatformTableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (NSInteger)numberOfSectionsInTableView:(RCTPlatformTableView *)tableView;
@end

@protocol RCTPlatformTableViewDelegate <NSObject>
@optional
- (CGFloat)tableView:(RCTPlatformTableView *)tableView heightForRowAtIndexPath:(id)indexPath;
- (void)tableView:(RCTPlatformTableView *)tableView didSelectRowAtIndexPath:(id)indexPath;
@end

@protocol RCTPlatformApplicationDelegate <NSApplicationDelegate>
@optional
@property (nonatomic, strong, nullable) NSWindow *window;
- (BOOL)application:(RCTPlatformApplication *)application
    didFinishLaunchingWithOptions:(nullable NSDictionary<RCTPlatformApplicationLaunchOptionsKey, id> *)launchOptions;
- (BOOL)application:(RCTPlatformApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<RCTPlatformApplicationOpenURLOptionsKey, id> *)options;
- (BOOL)application:(RCTPlatformApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler;
- (void)applicationDidBecomeActive:(RCTPlatformApplication *)application;
- (void)applicationWillResignActive:(RCTPlatformApplication *)application;
- (void)applicationWillTerminate:(RCTPlatformApplication *)application;
@end

@protocol RCTPlatformUserActivityRestoring <NSObject>
@optional
- (void)restoreUserActivityState:(NSUserActivity *)activity;
@end

@protocol RCTPlatformAdaptivePresentationControllerDelegate <NSObject>
@optional
- (void)presentationControllerDidDismiss:(id)presentationController;
@end


// Accessibility traits.
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitNone = 0;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitButton = 1 << 0;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitLink = 1 << 1;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitImage = 1 << 2;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitSelected = 1 << 3;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitPlaysSound = 1 << 4;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitKeyboardKey = 1 << 5;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitStaticText = 1 << 6;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitSummaryElement = 1 << 7;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitNotEnabled = 1 << 8;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitUpdatesFrequently = 1 << 9;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitSearchField = 1 << 10;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitStartsMediaSession = 1 << 11;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitAdjustable = 1 << 12;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitAllowsDirectInteraction = 1 << 13;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitCausesPageTurn = 1 << 14;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitHeader = 1 << 16;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitTabBar = 1 << 21;
static const RCTPlatformAccessibilityTraits RCTPlatformAccessibilityTraitSwitch = 0x20000000000001;


@interface RCTUIView : NSView

// NSView already provides -clipsToBounds (10.9+), so it is not redeclared here.

// UIKit subclasses override -canBecomeFirstResponder and expect the framework
// to honour it. RCTUIView bridges that to AppKit's
// -acceptsFirstResponder, and terminates the chain at NSView's own
// implementation rather than bouncing back through the category.
@property (nonatomic, readonly) BOOL canBecomeFirstResponder;

// Draw the focus ring when this view is first responder.
@property (nonatomic, assign) BOOL enableFocusRing;

// Receive the mouse-down that activates a background window, rather than
// swallowing it to raise the window. UIKit has no equivalent; AppKit needs it.
@property (nonatomic, assign) BOOL acceptsFirstMouse;

@end


// The UIKit-shaped surface React Native's own code -- and code written against
// react-native-macos -- calls on a view. Public for the same reason the
// geometry above is: a category is not an alias, so a second library
// declaring these is not a conflict. The implementation ships in the shim.
@interface NSView (RCTPlatformCompat)

@property (nonatomic, assign, getter=isUserInteractionEnabled) BOOL userInteractionEnabled;
@property (nonatomic, assign) CGFloat alpha;
@property (nonatomic, copy, nullable) RCTUIColor *backgroundColor;
@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, assign) CATransform3D transform3D;
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) RCTPlatformViewContentMode contentMode;
@property (nonatomic, readonly) RCTPlatformEdgeInsets safeAreaInsets;
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

- (nullable NSView *)hitTest:(CGPoint)point withEvent:(nullable RCTPlatformEvent *)event;
- (BOOL)pointInside:(CGPoint)point withEvent:(nullable RCTPlatformEvent *)event;

- (void)didMoveToWindow;
- (void)didMoveToSuperview;

@end


// A vsync-bound timer. CADisplayLink exists on macOS only from 14.0 and with a
// different initialiser, so the compatibility layer supplies one under the name
// react-native-macos uses. Public because a library that imports
// <React/RCTPlatformDisplayLink.h> expects the type, not a forward reference:
// react-native-worklets does exactly that.
@interface RCTPlatformDisplayLink : NSObject

+ (instancetype)displayLinkWithTarget:(id)target selector:(SEL)selector;

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode;
- (void)removeFromRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode;
- (void)invalidate;

@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic, readonly) CFTimeInterval timestamp;
@property (nonatomic, readonly) CFTimeInterval duration;
@property (nonatomic, readonly) CFTimeInterval targetTimestamp;
@property (nonatomic, assign) NSInteger preferredFramesPerSecond;

@end

NS_ASSUME_NONNULL_END

#else

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@compatibility_alias RCTUIColor UIColor;
@compatibility_alias RCTPlatformColor UIColor;
@compatibility_alias RCTUIImage UIImage;
@compatibility_alias RCTPlatformImage UIImage;
@compatibility_alias RCTPlatformView UIView;
@compatibility_alias RCTPlatformWindow UIWindow;
@compatibility_alias RCTPlatformViewController UIViewController;

@compatibility_alias RCTPlatformAccessibilityElement UIAccessibilityElement;
@compatibility_alias RCTPlatformActivityIndicatorView UIActivityIndicatorView;
@compatibility_alias RCTPlatformAlertController UIAlertController;
@compatibility_alias RCTPlatformApplication UIApplication;
@compatibility_alias RCTPlatformBezierPath UIBezierPath;
@compatibility_alias RCTPlatformEvent UIEvent;
@compatibility_alias RCTPlatformFont UIFont;
@compatibility_alias RCTPlatformFontMetrics UIFontMetrics;
@compatibility_alias RCTPlatformGestureRecognizer UIGestureRecognizer;
@compatibility_alias RCTPlatformGraphicsImageRenderer UIGraphicsImageRenderer;
@compatibility_alias RCTPlatformGraphicsImageRendererContext UIGraphicsImageRendererContext;
@compatibility_alias RCTPlatformGraphicsImageRendererFormat UIGraphicsImageRendererFormat;
@compatibility_alias RCTPlatformImageView UIImageView;
@compatibility_alias RCTPlatformKeyCommand UIKeyCommand;
@compatibility_alias RCTPlatformLabel UILabel;
@compatibility_alias RCTPlatformPanGestureRecognizer UIPanGestureRecognizer;
@compatibility_alias RCTPlatformResponder UIResponder;
@compatibility_alias RCTPlatformScrollView UIScrollView;
@compatibility_alias RCTPlatformSlider UISlider;
@compatibility_alias RCTPlatformStatusBarManager UIStatusBarManager;
@compatibility_alias RCTPlatformSwitch UISwitch;
@compatibility_alias RCTPlatformTextField UITextField;
@compatibility_alias RCTPlatformTextInputPasswordRules UITextInputPasswordRules;
@compatibility_alias RCTPlatformTextRange UITextRange;
@compatibility_alias RCTPlatformTextView UITextView;
@compatibility_alias RCTPlatformTouch UITouch;
@compatibility_alias RCTPlatformTraitCollection UITraitCollection;

typedef uint64_t RCTPlatformAccessibilityTraits;
typedef UIEdgeInsets RCTPlatformEdgeInsets;
#define RCTPlatformEdgeInsetsEqualToEdgeInsets UIEdgeInsetsEqualToEdgeInsets
typedef UIFontWeight RCTPlatformFontWeight;
typedef UIKeyModifierFlags RCTPlatformKeyModifierFlags;
typedef UIUserInterfaceLayoutDirection RCTPlatformUserInterfaceLayoutDirection;

typedef UITextFieldViewMode RCTPlatformTextFieldViewMode;
#define RCTPlatformTextFieldViewModeNever UITextFieldViewModeNever
#define RCTPlatformTextFieldViewModeWhileEditing UITextFieldViewModeWhileEditing
#define RCTPlatformTextFieldViewModeUnlessEditing UITextFieldViewModeUnlessEditing
#define RCTPlatformTextFieldViewModeAlways UITextFieldViewModeAlways

typedef UIViewContentMode RCTPlatformViewContentMode;
#define RCTPlatformViewContentModeScaleToFill UIViewContentModeScaleToFill
#define RCTPlatformViewContentModeScaleAspectFit UIViewContentModeScaleAspectFit
#define RCTPlatformViewContentModeScaleAspectFill UIViewContentModeScaleAspectFill
#define RCTPlatformViewContentModeRedraw UIViewContentModeRedraw
#define RCTPlatformViewContentModeCenter UIViewContentModeCenter
#define RCTPlatformViewContentModeTop UIViewContentModeTop
#define RCTPlatformViewContentModeBottom UIViewContentModeBottom
#define RCTPlatformViewContentModeLeft UIViewContentModeLeft
#define RCTPlatformViewContentModeRight UIViewContentModeRight
#define RCTPlatformViewContentModeTopLeft UIViewContentModeTopLeft
#define RCTPlatformViewContentModeTopRight UIViewContentModeTopRight
#define RCTPlatformViewContentModeBottomLeft UIViewContentModeBottomLeft
#define RCTPlatformViewContentModeBottomRight UIViewContentModeBottomRight

typedef UIDataDetectorTypes RCTPlatformDataDetectorTypes;
#define RCTPlatformDataDetectorTypeNone UIDataDetectorTypeNone
#define RCTPlatformDataDetectorTypePhoneNumber UIDataDetectorTypePhoneNumber
#define RCTPlatformDataDetectorTypeLink UIDataDetectorTypeLink
#define RCTPlatformDataDetectorTypeAddress UIDataDetectorTypeAddress
#define RCTPlatformDataDetectorTypeCalendarEvent UIDataDetectorTypeCalendarEvent
#define RCTPlatformDataDetectorTypeShipmentTrackingNumber UIDataDetectorTypeShipmentTrackingNumber
#define RCTPlatformDataDetectorTypeFlightNumber UIDataDetectorTypeFlightNumber
#define RCTPlatformDataDetectorTypeLookupSuggestion UIDataDetectorTypeLookupSuggestion
#define RCTPlatformDataDetectorTypeMoney UIDataDetectorTypeMoney
#define RCTPlatformDataDetectorTypePhysicalValue UIDataDetectorTypePhysicalValue
#define RCTPlatformDataDetectorTypeAll UIDataDetectorTypeAll

typedef UIInterfaceOrientationMask RCTPlatformInterfaceOrientationMask;
#define RCTPlatformInterfaceOrientationMaskPortrait UIInterfaceOrientationMaskPortrait
#define RCTPlatformInterfaceOrientationMaskLandscapeLeft UIInterfaceOrientationMaskLandscapeLeft
#define RCTPlatformInterfaceOrientationMaskLandscapeRight UIInterfaceOrientationMaskLandscapeRight
#define RCTPlatformInterfaceOrientationMaskPortraitUpsideDown UIInterfaceOrientationMaskPortraitUpsideDown
#define RCTPlatformInterfaceOrientationMaskLandscape UIInterfaceOrientationMaskLandscape
#define RCTPlatformInterfaceOrientationMaskAllButUpsideDown UIInterfaceOrientationMaskAllButUpsideDown
#define RCTPlatformInterfaceOrientationMaskAll UIInterfaceOrientationMaskAll

typedef UIKeyboardAppearance RCTPlatformKeyboardAppearance;
#define RCTPlatformKeyboardAppearanceDefault UIKeyboardAppearanceDefault
#define RCTPlatformKeyboardAppearanceDark UIKeyboardAppearanceDark
#define RCTPlatformKeyboardAppearanceLight UIKeyboardAppearanceLight

typedef UIKeyboardType RCTPlatformKeyboardType;
#define RCTPlatformKeyboardTypeDefault UIKeyboardTypeDefault
#define RCTPlatformKeyboardTypeASCIICapable UIKeyboardTypeASCIICapable
#define RCTPlatformKeyboardTypeNumbersAndPunctuation UIKeyboardTypeNumbersAndPunctuation
#define RCTPlatformKeyboardTypeURL UIKeyboardTypeURL
#define RCTPlatformKeyboardTypeNumberPad UIKeyboardTypeNumberPad
#define RCTPlatformKeyboardTypePhonePad UIKeyboardTypePhonePad
#define RCTPlatformKeyboardTypeNamePhonePad UIKeyboardTypeNamePhonePad
#define RCTPlatformKeyboardTypeEmailAddress UIKeyboardTypeEmailAddress
#define RCTPlatformKeyboardTypeDecimalPad UIKeyboardTypeDecimalPad
#define RCTPlatformKeyboardTypeTwitter UIKeyboardTypeTwitter
#define RCTPlatformKeyboardTypeWebSearch UIKeyboardTypeWebSearch
#define RCTPlatformKeyboardTypeASCIICapableNumberPad UIKeyboardTypeASCIICapableNumberPad

typedef UIReturnKeyType RCTPlatformReturnKeyType;
#define RCTPlatformReturnKeyDefault UIReturnKeyDefault
#define RCTPlatformReturnKeyGo UIReturnKeyGo
#define RCTPlatformReturnKeyGoogle UIReturnKeyGoogle
#define RCTPlatformReturnKeyJoin UIReturnKeyJoin
#define RCTPlatformReturnKeyNext UIReturnKeyNext
#define RCTPlatformReturnKeyRoute UIReturnKeyRoute
#define RCTPlatformReturnKeySearch UIReturnKeySearch
#define RCTPlatformReturnKeySend UIReturnKeySend
#define RCTPlatformReturnKeyYahoo UIReturnKeyYahoo
#define RCTPlatformReturnKeyDone UIReturnKeyDone
#define RCTPlatformReturnKeyEmergencyCall UIReturnKeyEmergencyCall
#define RCTPlatformReturnKeyContinue UIReturnKeyContinue

typedef UITextAutocapitalizationType RCTPlatformTextAutocapitalizationType;
#define RCTPlatformTextAutocapitalizationTypeNone UITextAutocapitalizationTypeNone
#define RCTPlatformTextAutocapitalizationTypeWords UITextAutocapitalizationTypeWords
#define RCTPlatformTextAutocapitalizationTypeSentences UITextAutocapitalizationTypeSentences
#define RCTPlatformTextAutocapitalizationTypeAllCharacters UITextAutocapitalizationTypeAllCharacters

typedef UITextAutocorrectionType RCTPlatformTextAutocorrectionType;
#define RCTPlatformTextAutocorrectionTypeDefault UITextAutocorrectionTypeDefault
#define RCTPlatformTextAutocorrectionTypeNo UITextAutocorrectionTypeNo
#define RCTPlatformTextAutocorrectionTypeYes UITextAutocorrectionTypeYes

typedef UITextSmartInsertDeleteType RCTPlatformTextSmartInsertDeleteType;
#define RCTPlatformTextSmartInsertDeleteTypeDefault UITextSmartInsertDeleteTypeDefault
#define RCTPlatformTextSmartInsertDeleteTypeNo UITextSmartInsertDeleteTypeNo
#define RCTPlatformTextSmartInsertDeleteTypeYes UITextSmartInsertDeleteTypeYes

typedef UITextSpellCheckingType RCTPlatformTextSpellCheckingType;
#define RCTPlatformTextSpellCheckingTypeDefault UITextSpellCheckingTypeDefault
#define RCTPlatformTextSpellCheckingTypeNo UITextSpellCheckingTypeNo
#define RCTPlatformTextSpellCheckingTypeYes UITextSpellCheckingTypeYes

typedef UIModalPresentationStyle RCTPlatformModalPresentationStyle;
#define RCTPlatformModalPresentationFullScreen UIModalPresentationFullScreen
#define RCTPlatformModalPresentationPageSheet UIModalPresentationPageSheet
#define RCTPlatformModalPresentationFormSheet UIModalPresentationFormSheet
#define RCTPlatformModalPresentationOverFullScreen UIModalPresentationOverFullScreen
#define RCTPlatformModalPresentationPopover UIModalPresentationPopover

typedef UIUserInterfaceStyle RCTPlatformUserInterfaceStyle;
#define RCTPlatformUserInterfaceStyleUnspecified UIUserInterfaceStyleUnspecified
#define RCTPlatformUserInterfaceStyleLight UIUserInterfaceStyleLight
#define RCTPlatformUserInterfaceStyleDark UIUserInterfaceStyleDark

typedef UIStatusBarAnimation RCTPlatformStatusBarAnimation;
#define RCTPlatformStatusBarAnimationNone UIStatusBarAnimationNone
#define RCTPlatformStatusBarAnimationFade UIStatusBarAnimationFade
#define RCTPlatformStatusBarAnimationSlide UIStatusBarAnimationSlide

typedef UIStatusBarStyle RCTPlatformStatusBarStyle;
#define RCTPlatformStatusBarStyleDefault UIStatusBarStyleDefault
#define RCTPlatformStatusBarStyleLightContent UIStatusBarStyleLightContent
#define RCTPlatformStatusBarStyleDarkContent UIStatusBarStyleDarkContent


@compatibility_alias RCTPlatformTableView UITableView;

@compatibility_alias RCTPlatformTextPosition UITextPosition;

@compatibility_alias RCTPlatformScene UIScene;
@compatibility_alias RCTPlatformOpenURLContext UIOpenURLContext;
@compatibility_alias RCTPlatformSceneConnectionOptions UISceneConnectionOptions;

@compatibility_alias RCTPlatformTextSelectionRect UITextSelectionRect;

@compatibility_alias RCTPlatformTextInputMode UITextInputMode;

typedef UIApplicationLaunchOptionsKey RCTPlatformApplicationLaunchOptionsKey;

typedef UIApplicationOpenURLOptionsKey RCTPlatformApplicationOpenURLOptionsKey;

typedef UITextSmartQuotesType RCTPlatformTextSmartQuotesType;
#define RCTPlatformTextSmartQuotesTypeDefault UITextSmartQuotesTypeDefault
#define RCTPlatformTextSmartQuotesTypeNo UITextSmartQuotesTypeNo
#define RCTPlatformTextSmartQuotesTypeYes UITextSmartQuotesTypeYes

typedef UITextSmartDashesType RCTPlatformTextSmartDashesType;
#define RCTPlatformTextSmartDashesTypeDefault UITextSmartDashesTypeDefault
#define RCTPlatformTextSmartDashesTypeNo UITextSmartDashesTypeNo
#define RCTPlatformTextSmartDashesTypeYes UITextSmartDashesTypeYes

#define RCTPlatformTextInputTraits UITextInputTraits

#define RCTPlatformTextInput UITextInput

#define RCTPlatformScrollViewDelegate UIScrollViewDelegate

#define RCTPlatformTableViewDataSource UITableViewDataSource

#define RCTPlatformTableViewDelegate UITableViewDelegate

#define RCTPlatformApplicationDelegate UIApplicationDelegate

#define RCTPlatformUserActivityRestoring UIUserActivityRestoring

#define RCTPlatformAdaptivePresentationControllerDelegate UIAdaptivePresentationControllerDelegate


#define RCTPlatformAccessibilityTraitNone UIAccessibilityTraitNone
#define RCTPlatformAccessibilityTraitButton UIAccessibilityTraitButton
#define RCTPlatformAccessibilityTraitLink UIAccessibilityTraitLink
#define RCTPlatformAccessibilityTraitImage UIAccessibilityTraitImage
#define RCTPlatformAccessibilityTraitSelected UIAccessibilityTraitSelected
#define RCTPlatformAccessibilityTraitPlaysSound UIAccessibilityTraitPlaysSound
#define RCTPlatformAccessibilityTraitKeyboardKey UIAccessibilityTraitKeyboardKey
#define RCTPlatformAccessibilityTraitStaticText UIAccessibilityTraitStaticText
#define RCTPlatformAccessibilityTraitSummaryElement UIAccessibilityTraitSummaryElement
#define RCTPlatformAccessibilityTraitNotEnabled UIAccessibilityTraitNotEnabled
#define RCTPlatformAccessibilityTraitUpdatesFrequently UIAccessibilityTraitUpdatesFrequently
#define RCTPlatformAccessibilityTraitSearchField UIAccessibilityTraitSearchField
#define RCTPlatformAccessibilityTraitStartsMediaSession UIAccessibilityTraitStartsMediaSession
#define RCTPlatformAccessibilityTraitAdjustable UIAccessibilityTraitAdjustable
#define RCTPlatformAccessibilityTraitAllowsDirectInteraction UIAccessibilityTraitAllowsDirectInteraction
#define RCTPlatformAccessibilityTraitCausesPageTurn UIAccessibilityTraitCausesPageTurn
#define RCTPlatformAccessibilityTraitHeader UIAccessibilityTraitHeader
#define RCTPlatformAccessibilityTraitTabBar UIAccessibilityTraitTabBar
#define RCTPlatformAccessibilityTraitSwitch UIAccessibilityTraitSwitch

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_OSX
