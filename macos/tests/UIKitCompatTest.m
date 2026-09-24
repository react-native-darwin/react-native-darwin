/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * Compile-and-run check for the UIKit compatibility layer.
 *
 * Everything below is written the way upstream React Native writes it, with an
 * unmodified `#import <UIKit/UIKit.h>`. If this file compiles, upstream source
 * of the same shape compiles.
 */

#import <UIKit/UIKit.h>

#include <stdio.h>

static int gFailures = 0;

#define CHECK(cond, label)                          \
  do {                                              \
    if (!(cond)) {                                  \
      printf("FAIL  %s\n", (label));                \
      gFailures++;                                  \
    } else {                                        \
      printf("ok    %s\n", (label));                \
    }                                               \
  } while (0)

#pragma mark - Upstream-shaped code

// React Native attaches categories to UIView in dozens of files.
@interface UIView (React)
@property (nonatomic, copy, nullable) NSNumber *reactTag;
- (void)reactSetFrame:(CGRect)frame;
@end

@implementation UIView (React)
- (NSNumber *)reactTag
{
  return nil;
}
- (void)setReactTag:(__unused NSNumber *)reactTag
{
}
- (void)reactSetFrame:(CGRect)frame
{
  self.frame = frame;
}
@end

// A typical React Native view subclass.
@interface RCTView : RCTPlatformView
@property (nonatomic, assign) CGFloat borderRadius;
@end

@implementation RCTView
- (void)layoutSubviews
{
  [super layoutSubviews];
}
@end

int main(void)
{
  @autoreleasepool {
    // Tier 3: a real class named UIView.
    RCTView *view = [[RCTView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    CHECK(view != nil, "RCTPlatformView subclass allocates");
    CHECK(view.isFlipped, "RCTPlatformView uses a top-left origin");
    CHECK(view.wantsLayer, "RCTPlatformView is layer-backed");

    view.backgroundColor = [UIColor colorWithSRGBRed:1 green:0 blue:0 alpha:1];
    CHECK(view.backgroundColor != nil, "UIView.backgroundColor round-trips");

    [view reactSetFrame:CGRectMake(1, 2, 3, 4)];
    CHECK(view.frame.origin.x == 1 && view.frame.origin.y == 2, "UIView (React) category applies");

    view.alpha = 0.5;
    CHECK(fabs(view.alpha - 0.5) < 0.001, "UIView.alpha maps to alphaValue");

    view.transform = CGAffineTransformMakeScale(2, 2);
    CHECK(!CATransform3DIsIdentity(view.transform3D), "UIView.transform stores a transform");

    // The hierarchy fix: a UIScrollView must be usable wherever a UIView * is
    // expected. This is the assignment that did not compile before UIView
    // became an alias for NSView.
    UIScrollView *hierarchyCheck = [[UIScrollView alloc] initWithFrame:CGRectZero];
    UIView *asPlainView = hierarchyCheck;
    CHECK(asPlainView == hierarchyCheck, "UIScrollView is assignable to UIView *");
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    UIView *imageAsView = imageView;
    CHECK(imageAsView == imageView, "UIImageView is assignable to UIView *");

    // The category surface must also work on a plain NSView, because that is
    // what AppKit hands back from -subviews.
    NSView *plain = [[NSView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    CHECK(plain.isUserInteractionEnabled, "plain NSView answers userInteractionEnabled");
    [plain layoutSubviews];
    [plain setNeedsLayout];
    CHECK(![plain isDescendantOfView:view], "plain NSView answers isDescendantOfView:");

    [view addSubview:plain];
    CHECK([plain isDescendantOfView:view], "isDescendantOfView: tracks the hierarchy");

    NSView *second = [[NSView alloc] initWithFrame:CGRectZero];
    [view insertSubview:second atIndex:0];
    CHECK(view.subviews.count == 2, "insertSubview:atIndex: inserts");

    // Iterating subviews as UIView * is the upstream idiom. It must not crash.
    for (UIView *subview in view.subviews) {
      [subview layoutSubviews];
      subview.userInteractionEnabled = YES;
    }
    CHECK(1, "iterating subviews as UIView * is safe");

    // Tier 1: aliases.
    UIFont *font = [UIFont systemFontOfSize:12];
    CHECK(font != nil, "UIFont aliases NSFont");
    CHECK(UIFontLineHeight(font) > 0, "UIFontLineHeight computes");

    UIImage *image = [UIImage imageWithData:[NSData data]];
    CHECK(image == nil, "UIImage.imageWithData: rejects empty data");

    NSImage *drawn = [[NSImage alloc] initWithSize:NSMakeSize(4, 4)];
    [drawn lockFocus];
    [[NSColor redColor] set];
    NSRectFill(NSMakeRect(0, 0, 4, 4));
    [drawn unlockFocus];
    CHECK(UIImageGetScale(drawn) > 0, "UIImageGetScale works on any NSImage");
    CHECK(UIImageGetCGImageRef(drawn) != NULL, "UIImageGetCGImageRef works on any NSImage");

    // Tier 2: constants, enums, geometry.
    UIEdgeInsets insets = UIEdgeInsetsMake(1, 2, 3, 4);
    CGRect inset = UIEdgeInsetsInsetRect(CGRectMake(0, 0, 100, 100), insets);
    CHECK(inset.origin.x == 2 && inset.size.width == 94, "UIEdgeInsetsInsetRect insets");
    CHECK(UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, NSEdgeInsetsMake(0, 0, 0, 0)), "UIEdgeInsetsZero");
    CHECK(UIAccessibilityTraitButton != UIAccessibilityTraitNone, "accessibility traits are distinct");
    CHECK(UIViewContentModeScaleAspectFit != UIViewContentModeScaleToFill, "UIViewContentMode is populated");
    // Regression: mapping these onto NSViewLayerContentsPlacement made
    // ScaleAspectFit and Redraw both equal 1, which broke every switch over
    // the enum in upstream code.
    CHECK(UIViewContentModeScaleAspectFit != UIViewContentModeRedraw, "UIViewContentMode values are distinct");
    view.contentMode = UIViewContentModeScaleAspectFill;
    CHECK(view.contentMode == UIViewContentModeScaleAspectFill, "contentMode round-trips");
    CHECK(
        view.layerContentsPlacement == NSViewLayerContentsPlacementScaleProportionallyToFill,
        "contentMode maps onto the AppKit placement");
    CHECK(UIKeyModifierCommand == NSEventModifierFlagCommand, "key modifiers map to AppKit");

    // Graphics.
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(8, 8)];
    NSImage *rendered = [renderer imageWithActions:^(__unused id context) {
      [[UIColor greenColor] set];
      NSRectFill(NSMakeRect(0, 0, 8, 8));
    }];
    CHECK(rendered != nil && rendered.size.width == 8, "UIGraphicsImageRenderer renders");

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(6, 6), NO, 2);
    CHECK(UIGraphicsGetCurrentContext() != NULL, "legacy image context stack pushes");
    NSImage *legacy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CHECK(legacy != nil, "legacy image context produces an image");

    // Scroll view.
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    scrollView.contentSize = CGSizeMake(500, 500);
    CHECK(scrollView.contentSize.width == 500, "UIScrollView.contentSize round-trips");
    scrollView.contentOffset = CGPointMake(10, 20);
    CHECK(fabs(scrollView.contentOffset.y - 20) < 0.001, "UIScrollView.contentOffset round-trips");
    scrollView.contentInset = UIEdgeInsetsMake(5, 0, 0, 0);
    CHECK(fabs(scrollView.contentInset.top - 5) < 0.001, "UIScrollView.contentInset round-trips");

    // Application.
    CHECK(NSApplication.sharedApplication.applicationState == UIApplicationStateInactive, "UIApplicationState maps");

    // Touch synthesis.
    NSEvent *event = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
                                        location:NSMakePoint(5, 5)
                                   modifierFlags:0
                                       timestamp:0
                                    windowNumber:0
                                         context:nil
                                     eventNumber:0
                                      clickCount:1
                                        pressure:1];
    UITouch *touch = [[UITouch alloc] initWithEvent:event phase:UITouchPhaseBegan view:view];
    CHECK(touch.phase == UITouchPhaseBegan, "UITouch carries a phase");
    CHECK(touch.tapCount == 1, "UITouch carries a tap count");

    // Exercise the category-on-AppKit-class additions at runtime. A category
    // that accidentally overrides the method it means to call recurses until
    // the stack dies, and only running it catches that.
    NSPasteboard *pasteboard = NSPasteboard.generalPasteboard;
    CHECK(pasteboard != nil, "NSPasteboard.generalPasteboard still resolves");
    NSWindow *window = [[NSWindow alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    CHECK(window != nil, "NSWindow.initWithFrame: builds a window");
    CHECK(window.windowLevel == (CGFloat)window.level, "NSWindow.windowLevel maps to level");
    CHECK(window.rootViewController == nil, "NSWindow.rootViewController reads");
    CHECK(window.traitCollection != nil, "NSWindow.traitCollection resolves");
    CHECK(NSScreen.mainScreen.scale > 0, "NSScreen.scale maps to backingScaleFactor");
    CHECK([UIDevice.currentDevice.systemName isEqualToString:@"macOS"], "UIDevice reports macOS");
    CHECK(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomMac, "UIDevice idiom is Mac");
    CHECK(UIDevice.currentDevice.model.length > 0, "UIDevice.model reads hw.model");
    view.tag = 42;
    CHECK(view.tag == 42, "NSView.tag is writable");
    UIView *plainForTint = [[RCTPlatformView alloc] initWithFrame:CGRectZero];
    plainForTint.tintColor = [UIColor blueColor];
    CHECK(plainForTint.tintColor != nil, "NSView.tintColor round-trips");

    // Fabric lays every view out by assigning `center` and then `bounds`, never
    // `frame` -- assigning `frame` is undefined once a layer transform is set.
    // That only works if `bounds.size` resizes the view the way UIKit does.
    // AppKit's own `setBounds:` would leave the frame at its old size, which
    // renders the whole tree correctly positioned and 0x0.
    UIView *laidOut = [[RCTPlatformView alloc] initWithFrame:CGRectZero];
    laidOut.center = CGPointMake(150, 100);
    laidOut.bounds = CGRectMake(0, 0, 200, 80);
    CHECK(CGRectEqualToRect(laidOut.frame, CGRectMake(50, 60, 200, 80)),
          "bounds.size resizes the frame around the centre");
    CHECK(CGPointEqualToPoint(laidOut.center, CGPointMake(150, 100)),
          "centre survives the resize");
    CHECK(CGSizeEqualToSize(laidOut.bounds.size, CGSizeMake(200, 80)),
          "bounds reads back the assigned size");

    // A bounds origin is a content offset in both frameworks, and must not move
    // the frame.
    laidOut.bounds = CGRectMake(10, 5, 200, 80);
    CHECK(CGRectEqualToRect(laidOut.frame, CGRectMake(50, 60, 200, 80)),
          "bounds.origin leaves the frame alone");
    CHECK(CGPointEqualToPoint(laidOut.bounds.origin, CGPointMake(10, 5)),
          "bounds.origin round-trips");

    printf("\n%s (%d failure%s)\n", gFailures == 0 ? "PASS" : "FAIL", gFailures, gFailures == 1 ? "" : "s");
  }
  return gFailures == 0 ? 0 : 1;
}
