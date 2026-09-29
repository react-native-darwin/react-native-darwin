/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <Foundation/Foundation.h>

#import <React/RCTConvert.h>

typedef RCTPlatformFont * (^RCTFontHandler)(CGFloat fontSize, NSString *fontWeightDescription);
typedef CGFloat RCTFontWeight;

/**
 * React Native will use the System font for rendering by default. If you want to
 * provide a different base font, use this override. The font weight supplied to your
 * handler will be one of "ultralight", "thin", "light", "regular", "medium",
 * "semibold", "extrabold", "bold", "heavy", or "black".
 *
 * @deprecated Use RCTSetDefaultFontResolver
 */
RCT_EXTERN void RCTSetDefaultFontHandler(RCTFontHandler handler) __attribute__((deprecated));
RCT_EXTERN BOOL RCTHasFontHandlerSet(void);
RCT_EXTERN RCTFontWeight RCTGetFontWeight(RCTPlatformFont *font);

@interface RCTFont : NSObject

/**
 * Update a font with a given font-family, size, weight and style.
 * If parameters are not specified, they'll be kept as-is.
 * If font is nil, the default system font of size 14 will be used.
 */
+ (RCTPlatformFont *)updateFont:(RCTPlatformFont *)font
            withFamily:(NSString *)family
                  size:(NSNumber *)size
                weight:(NSString *)weight
                 style:(NSString *)style
               variant:(NSArray<NSString *> *)variant
       scaleMultiplier:(CGFloat)scaleMultiplier;

+ (RCTPlatformFont *)updateFont:(RCTPlatformFont *)font withFamily:(NSString *)family;
+ (RCTPlatformFont *)updateFont:(RCTPlatformFont *)font withSize:(NSNumber *)size;
+ (RCTPlatformFont *)updateFont:(RCTPlatformFont *)font withWeight:(NSString *)weight;
+ (RCTPlatformFont *)updateFont:(RCTPlatformFont *)font withStyle:(NSString *)style;

@end

@interface RCTConvert (RCTFont)

+ (RCTPlatformFont *)UIFont:(id)json;

@end
