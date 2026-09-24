/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>

#import "UIImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIGraphicsImageRendererFormat : NSObject
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) BOOL opaque;
+ (instancetype)defaultFormat;
@end

/**
 * AppKit's NSGraphicsContext equivalent of UIGraphicsImageRenderer.
 *
 * Used by React Native for border and shadow rasterisation. Backed by
 * NSBitmapImageRep so the result carries a correct pixel scale, which
 * -lockFocus based drawing does not reliably give you.
 */
/**
 * The object UIKit hands to a renderer block.
 *
 * UIKit's carries a CGContext plus drawing helpers. AppKit's current context is
 * an NSGraphicsContext, so that is what the block receives; -CGContext gets you
 * the same CGContextRef UIKit would have given you.
 */
@interface UIGraphicsImageRendererContext : NSObject
@property (nonatomic, readonly) CGContextRef CGContext;
- (instancetype)initWithGraphicsContext:(NSGraphicsContext *)context;
- (void)fillRect:(CGRect)rect;
- (void)strokeRect:(CGRect)rect;
@end

@interface UIGraphicsImageRenderer : NSObject

- (instancetype)initWithSize:(CGSize)size;
- (instancetype)initWithSize:(CGSize)size format:(UIGraphicsImageRendererFormat *)format;

- (NSImage *)imageWithActions:(NS_NOESCAPE void (^)(UIGraphicsImageRendererContext *context))actions;

@end

#ifdef __cplusplus
extern "C" {
#endif

void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale);
void UIGraphicsEndImageContext(void);
NSImage *_Nullable UIGraphicsGetImageFromCurrentImageContext(void);
CGContextRef _Nullable UIGraphicsGetCurrentContext(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
