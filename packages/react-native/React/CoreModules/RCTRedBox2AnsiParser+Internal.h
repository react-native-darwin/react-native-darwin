/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <UIKit/UIKit.h>

/**
 * Parses ANSI escape sequences in text and produces an NSAttributedString
 * with the corresponding foreground/background colors applied.
 *
 * Uses the Afterglow color theme (matching LogBox's AnsiHighlight.js).
 */
@interface RCTRedBox2AnsiParser : NSObject

+ (NSAttributedString *)attributedStringFromAnsiText:(NSString *)text
                                            baseFont:(RCTPlatformFont *)font
                                           baseColor:(RCTUIColor *)color;

@end
