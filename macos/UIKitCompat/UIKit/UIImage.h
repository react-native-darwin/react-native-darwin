/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

// UIImage is an alias rather than an NSImage subclass on purpose.
//
// AppKit hands NSImage instances back from dozens of call sites (+imageNamed:,
// pasteboard reads, NSImageRep conversions). If UIImage were a subclass, every
// one of those would be statically typed as UIImage * while actually being an
// NSImage, and the first -scale call would hit an unrecognised selector. An
// alias plus a category means any NSImage from anywhere answers the whole
// interface.
@compatibility_alias UIImage NSImage;

// NSImage has no orientation concept: it stores whatever the representation
// decoded to, already upright. Declared so EXIF-aware upstream code compiles;
// -imageOrientation always reports Up.
typedef NS_ENUM(NSInteger, UIImageOrientation) {
  UIImageOrientationUp = 0,
  UIImageOrientationDown,
  UIImageOrientationLeft,
  UIImageOrientationRight,
  UIImageOrientationUpMirrored,
  UIImageOrientationDownMirrored,
  UIImageOrientationLeftMirrored,
  UIImageOrientationRightMirrored,
};

typedef NS_ENUM(NSInteger, UIImageRenderingMode) {
  UIImageRenderingModeAutomatic = 0,
  UIImageRenderingModeAlwaysOriginal,
  UIImageRenderingModeAlwaysTemplate,
};

@interface NSImage (UIKitCompat)

// UIKit's scale factor. NSImage has no such concept: its -size is already in
// points. Derived from the largest bitmap representation, defaulting to 1.
@property (nonatomic, assign) CGFloat scale;

// UIImage exposes -CGImage as a stable property.
//
// NSImage's -CGImageForProposedRect: returns a fresh autoreleased CGImage on
// every call. Assigning one of those to CALayer.contents leaves the layer
// holding a reference that dies with the pool, which shows up as missing
// borders and shadows. This caches, so the returned image outlives the pool.
@property (nonatomic, readonly, nullable) CGImageRef CGImage;

@property (nonatomic, readonly) UIImageOrientation imageOrientation;

+ (nullable NSImage *)imageWithData:(NSData *)data;
+ (nullable NSImage *)imageWithContentsOfFile:(NSString *)path;
+ (nullable NSImage *)imageNamed:(NSString *)name
                        inBundle:(nullable NSBundle *)bundle
   compatibleWithTraitCollection:(nullable id)traitCollection;
+ (nullable NSImage *)imageWithCGImage:(CGImageRef)cgImage;
+ (nullable NSImage *)imageWithCGImage:(CGImageRef)cgImage
                                 scale:(CGFloat)scale
                           orientation:(NSInteger)orientation;

- (NSImage *)imageWithRenderingMode:(UIImageRenderingMode)renderingMode;

- (nullable instancetype)initWithData:(NSData *)data scale:(CGFloat)scale;

@end

#ifdef __cplusplus
extern "C" {
#endif

CGFloat UIImageGetScale(NSImage *image);
CGImageRef _Nullable UIImageGetCGImageRef(NSImage *image);
NSImage *_Nullable UIImageWithData(NSData *data);
NSImage *_Nullable UIImageWithContentsOfFile(NSString *path);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
