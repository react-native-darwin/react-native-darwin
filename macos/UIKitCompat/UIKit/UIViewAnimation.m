/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIViewAnimation.h"

#import "UIApplicationDelegate.h"
#import "UIImage.h"

NSNotificationName const UIAccessibilityAnnouncementDidFinishNotification = @"UIAccessibilityAnnouncementDidFinishNotification";
NSNotificationName const UIAccessibilityVoiceOverStatusDidChangeNotification = @"UIAccessibilityVoiceOverStatusDidChangeNotification";
NSNotificationName const UIAccessibilityReduceMotionStatusDidChangeNotification = @"UIAccessibilityReduceMotionStatusDidChangeNotification";
NSNotificationName const UIAccessibilityInvertColorsStatusDidChangeNotification = @"UIAccessibilityInvertColorsStatusDidChangeNotification";
NSNotificationName const UIAccessibilityReduceTransparencyStatusDidChangeNotification = @"UIAccessibilityReduceTransparencyStatusDidChangeNotification";
NSNotificationName const UIAccessibilityBoldTextStatusDidChangeNotification = @"UIAccessibilityBoldTextStatusDidChangeNotification";
NSNotificationName const UIAccessibilityGrayscaleStatusDidChangeNotification = @"UIAccessibilityGrayscaleStatusDidChangeNotification";
NSNotificationName const UIAccessibilityDarkerSystemColorsStatusDidChangeNotification = @"UIAccessibilityDarkerSystemColorsStatusDidChangeNotification";

UITextContentType const UITextContentTypeURL = @"UITextContentTypeURL";
UITextContentType const UITextContentTypeEmailAddress = @"UITextContentTypeEmailAddress";
UITextContentType const UITextContentTypeTelephoneNumber = @"UITextContentTypeTelephoneNumber";
UITextContentType const UITextContentTypeName = @"UITextContentTypeName";
UITextContentType const UITextContentTypeUsername = @"UITextContentTypeUsername";
UITextContentType const UITextContentTypePassword = @"UITextContentTypePassword";
UITextContentType const UITextContentTypeNewPassword = @"UITextContentTypeNewPassword";
UITextContentType const UITextContentTypeOneTimeCode = @"UITextContentTypeOneTimeCode";
UITextContentType const UITextContentTypeFullStreetAddress = @"UITextContentTypeFullStreetAddress";
UITextContentType const UITextContentTypePostalCode = @"UITextContentTypePostalCode";
UITextContentType const UITextContentTypeCreditCardNumber = @"UITextContentTypeCreditCardNumber";

UITextContentType const UITextContentTypeAddressCity = @"UITextContentTypeAddressCity";
UITextContentType const UITextContentTypeAddressState = @"UITextContentTypeAddressState";
UITextContentType const UITextContentTypeAddressCityAndState = @"UITextContentTypeAddressCityAndState";
UITextContentType const UITextContentTypeCountryName = @"UITextContentTypeCountryName";
UITextContentType const UITextContentTypeStreetAddressLine1 = @"UITextContentTypeStreetAddressLine1";
UITextContentType const UITextContentTypeStreetAddressLine2 = @"UITextContentTypeStreetAddressLine2";
UITextContentType const UITextContentTypeSublocality = @"UITextContentTypeSublocality";
UITextContentType const UITextContentTypeGivenName = @"UITextContentTypeGivenName";
UITextContentType const UITextContentTypeMiddleName = @"UITextContentTypeMiddleName";
UITextContentType const UITextContentTypeFamilyName = @"UITextContentTypeFamilyName";
UITextContentType const UITextContentTypeNamePrefix = @"UITextContentTypeNamePrefix";
UITextContentType const UITextContentTypeNameSuffix = @"UITextContentTypeNameSuffix";
UITextContentType const UITextContentTypeNickname = @"UITextContentTypeNickname";
UITextContentType const UITextContentTypeJobTitle = @"UITextContentTypeJobTitle";
UITextContentType const UITextContentTypeOrganizationName = @"UITextContentTypeOrganizationName";
UITextContentType const UITextContentTypeLocation = @"UITextContentTypeLocation";

UITextContentType const UITextContentTypeDateTime = @"UITextContentTypeDateTime";
UITextContentType const UITextContentTypeFlightNumber = @"UITextContentTypeFlightNumber";
UITextContentType const UITextContentTypeShipmentTrackingNumber = @"UITextContentTypeShipmentTrackingNumber";
UITextContentType const UITextContentTypeCreditCardExpiration = @"UITextContentTypeCreditCardExpiration";
UITextContentType const UITextContentTypeCreditCardSecurityCode = @"UITextContentTypeCreditCardSecurityCode";
UITextContentType const UITextContentTypeCellularEID = @"UITextContentTypeCellularEID";
UITextContentType const UITextContentTypeCellularIMEI = @"UITextContentTypeCellularIMEI";

@implementation UIPresentationController
@end

@implementation UIEditMenuInteraction

- (instancetype)initWithDelegate:(__unused id)delegate
{
  return [super init];
}

@end

@implementation NSStackView (UIKitCompatDistribution)

- (UIStackViewDistribution)distributionForUIKitCompat
{
  return (UIStackViewDistribution)self.distribution;
}

- (void)setDistributionForUIKitCompat:(UIStackViewDistribution)distribution
{
  self.distribution = (NSStackViewDistribution)distribution;
}

@end

@implementation NSView (UIKitCompatInteraction)

- (void)addInteraction:(__unused id)interaction
{
}

- (void)removeInteraction:(__unused id)interaction
{
}

- (NSInteger)accessibilityElementCount
{
  return (NSInteger)self.accessibilityChildren.count;
}

@end

@implementation NSViewController (UIKitCompatContainment)

- (void)didMoveToParentViewController:(__unused NSViewController *)parent
{
}

- (void)willMoveToParentViewController:(__unused NSViewController *)parent
{
}

@end

@implementation NSWindow (UIKitCompatFrame)

- (void)setFrame:(CGRect)frame
{
  [self setFrame:NSRectFromCGRect(frame) display:YES];
}

@end

UIContentSizeCategory const UIContentSizeCategoryExtraSmall = @"UICTContentSizeCategoryXS";
UIContentSizeCategory const UIContentSizeCategorySmall = @"UICTContentSizeCategoryS";
UIContentSizeCategory const UIContentSizeCategoryMedium = @"UICTContentSizeCategoryM";
UIContentSizeCategory const UIContentSizeCategoryLarge = @"UICTContentSizeCategoryL";
UIContentSizeCategory const UIContentSizeCategoryExtraLarge = @"UICTContentSizeCategoryXL";
UIContentSizeCategory const UIContentSizeCategoryExtraExtraLarge = @"UICTContentSizeCategoryXXL";
UIContentSizeCategory const UIContentSizeCategoryExtraExtraExtraLarge = @"UICTContentSizeCategoryXXXL";
UIContentSizeCategory const UIContentSizeCategoryAccessibilityMedium = @"UICTContentSizeCategoryAccessibilityM";
UIContentSizeCategory const UIContentSizeCategoryAccessibilityLarge = @"UICTContentSizeCategoryAccessibilityL";
UIContentSizeCategory const UIContentSizeCategoryAccessibilityExtraLarge = @"UICTContentSizeCategoryAccessibilityXL";
UIContentSizeCategory const UIContentSizeCategoryAccessibilityExtraExtraLarge = @"UICTContentSizeCategoryAccessibilityXXL";
UIContentSizeCategory const UIContentSizeCategoryAccessibilityExtraExtraExtraLarge = @"UICTContentSizeCategoryAccessibilityXXXL";

@implementation NSApplication (UIKitCompatContentSize)
- (UIContentSizeCategory)preferredContentSizeCategory
{
  return UIContentSizeCategoryLarge;
}
@end

@implementation NSView (UIKitCompatContentSize)
- (UIContentSizeCategory)preferredContentSizeCategory
{
  return UIContentSizeCategoryLarge;
}
@end

NSNotificationName const UIDeviceProximityStateDidChangeNotification = @"UIDeviceProximityStateDidChangeNotification";
NSNotificationName const UIDeviceBatteryLevelDidChangeNotification = @"UIDeviceBatteryLevelDidChangeNotification";
NSNotificationName const UIDeviceOrientationDidChangeNotification = @"UIDeviceOrientationDidChangeNotification";

@implementation NSStackView (UIKitCompat)

- (instancetype)initWithArrangedSubviews:(NSArray<NSView *> *)views
{
  self = [self initWithFrame:NSZeroRect];
  for (NSView *view in views) {
    [self addArrangedSubview:view];
  }
  return self;
}

@end

@implementation NSApplication (UIKitCompatCanOpen)

- (BOOL)canOpenURL:(NSURL *)url
{
  return [NSWorkspace.sharedWorkspace URLForApplicationToOpenURL:url] != nil;
}

@end

@implementation RCTPlatformViewAnimator
@end

@implementation NSView (UIKitCompatAnimation)

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations
{
  [self animateWithDuration:duration animations:animations completion:nil];
}

+ (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(void (^)(void))animations
                 completion:(void (^)(BOOL))completion
{
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
    context.duration = duration;
    context.allowsImplicitAnimation = YES;
    if (animations) {
      animations();
    }
  }
      completionHandler:^{
        if (completion) {
          completion(YES);
        }
      }];
}

+ (void)animateWithDuration:(NSTimeInterval)duration
                      delay:(NSTimeInterval)delay
                    options:(__unused UIViewAnimationOptions)options
                 animations:(void (^)(void))animations
                 completion:(void (^)(BOOL))completion
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self animateWithDuration:duration animations:animations completion:completion];
  });
}

+ (void)animateWithDuration:(NSTimeInterval)duration
                      delay:(NSTimeInterval)delay
     usingSpringWithDamping:(__unused CGFloat)dampingRatio
      initialSpringVelocity:(__unused CGFloat)velocity
                    options:(UIViewAnimationOptions)options
                 animations:(void (^)(void))animations
                 completion:(void (^)(BOOL))completion
{
  // NSAnimationContext has no spring timing. Running the same duration without
  // the spring is visibly different but correct in endpoint and timing, which
  // is better than silently not animating.
  [self animateWithDuration:duration delay:delay options:options animations:animations completion:completion];
}

+ (NSUserInterfaceLayoutDirection)userInterfaceLayoutDirectionForSemanticContentAttribute:(NSInteger)attribute
{
  // 4 is UISemanticContentAttributeForceRightToLeft.
  return attribute == 4 ? NSUserInterfaceLayoutDirectionRightToLeft : NSUserInterfaceLayoutDirectionLeftToRight;
}

@end

static NSData *UIKitCompatRepresentation(NSImage *image, NSBitmapImageFileType type, NSDictionary *properties)
{
  CGImageRef cgImage = image.CGImage;
  if (cgImage == NULL) {
    return nil;
  }
  NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
  rep.size = image.size;
  return [rep representationUsingType:type properties:properties];
}

NSData *UIImagePNGRepresentation(NSImage *image)
{
  return UIKitCompatRepresentation(image, NSBitmapImageFileTypePNG, @{});
}

NSData *UIImageJPEGRepresentation(NSImage *image, CGFloat compressionQuality)
{
  return UIKitCompatRepresentation(
      image, NSBitmapImageFileTypeJPEG, @{NSImageCompressionFactor : @(compressionQuality)});
}

void UIAccessibilityPostNotification(NSNotificationName notification, id argument)
{
  if ([notification isEqualToString:UIAccessibilityAnnouncementNotification]) {
    NSString *message = [argument isKindOfClass:[NSString class]] ? argument : [argument description];
    if (message.length > 0) {
      NSAccessibilityPostNotificationWithUserInfo(
          NSApp,
          NSAccessibilityAnnouncementRequestedNotification,
          @{NSAccessibilityAnnouncementKey : message, NSAccessibilityPriorityKey : @(NSAccessibilityPriorityHigh)});
    }
    return;
  }
  if ([notification isEqualToString:UIAccessibilityLayoutChangedNotification] ||
      [notification isEqualToString:UIAccessibilityScreenChangedNotification]) {
    id target = argument ?: NSApp;
    NSAccessibilityPostNotification(target, NSAccessibilityLayoutChangedNotification);
    return;
  }
  // Anything else has no AppKit counterpart; dropping it is the honest answer.
}

BOOL UIAccessibilityIsVoiceOverRunning(void)
{
  return NSWorkspace.sharedWorkspace.isVoiceOverEnabled;
}

BOOL UIAccessibilityIsReduceMotionEnabled(void)
{
  return NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
}

BOOL UIAccessibilityIsReduceTransparencyEnabled(void)
{
  return NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceTransparency;
}

BOOL UIAccessibilityIsInvertColorsEnabled(void)
{
  return NSWorkspace.sharedWorkspace.accessibilityDisplayShouldInvertColors;
}

BOOL UIAccessibilityIsBoldTextEnabled(void)
{
  // No macOS setting corresponds to this.
  return NO;
}

BOOL UIAccessibilityIsGrayscaleEnabled(void)
{
  return NO;
}

BOOL UIAccessibilityDarkerSystemColorsEnabled(void)
{
  return NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast;
}
