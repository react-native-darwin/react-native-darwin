/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIImage.h"

#import <objc/runtime.h>

static const void *kUIKitCompatScaleKey = &kUIKitCompatScaleKey;
static const void *kUIKitCompatCGImageKey = &kUIKitCompatCGImageKey;

// Boxes a CGImageRef so it can live in an associated object and be released
// with the image rather than with the autorelease pool.
@interface UIKitCompatCGImageBox : NSObject
@property (nonatomic, readonly, nullable) CGImageRef image;
@end

@implementation UIKitCompatCGImageBox {
  CGImageRef _image;
}

- (instancetype)initWithCGImage:(CGImageRef)image
{
  if ((self = [super init])) {
    _image = CGImageRetain(image);
  }
  return self;
}

- (CGImageRef)image
{
  return _image;
}

- (void)dealloc
{
  CGImageRelease(_image);
}

@end

@implementation NSImage (UIKitCompat)

- (CGFloat)scale
{
  NSNumber *stored = objc_getAssociatedObject(self, kUIKitCompatScaleKey);
  if (stored != nil) {
    return stored.doubleValue;
  }

  // Infer from the largest bitmap representation. A 200pt-wide bitmap backing a
  // 100pt image is a @2x asset.
  NSSize size = self.size;
  if (size.width <= 0) {
    return 1.0;
  }
  NSInteger widestPixels = 0;
  for (NSImageRep *rep in self.representations) {
    widestPixels = MAX(widestPixels, rep.pixelsWide);
  }
  if (widestPixels <= 0) {
    return 1.0;
  }
  return (CGFloat)widestPixels / size.width;
}

- (void)setScale:(CGFloat)scale
{
  objc_setAssociatedObject(self, kUIKitCompatScaleKey, @(scale), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGImageRef)CGImage
{
  UIKitCompatCGImageBox *cached = objc_getAssociatedObject(self, kUIKitCompatCGImageKey);
  if (cached != nil) {
    return cached.image;
  }

  NSRect proposed = NSMakeRect(0, 0, self.size.width, self.size.height);
  CGImageRef image = [self CGImageForProposedRect:&proposed context:nil hints:nil];
  if (image == NULL) {
    return NULL;
  }

  UIKitCompatCGImageBox *box = [[UIKitCompatCGImageBox alloc] initWithCGImage:image];
  objc_setAssociatedObject(self, kUIKitCompatCGImageKey, box, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  return box.image;
}

- (UIImageOrientation)imageOrientation
{
  // NSImage representations are already decoded upright.
  return UIImageOrientationUp;
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale
{
  NSImage *image = [self initWithData:data];
  if (image != nil && scale > 0) {
    image.scale = scale;
    image.size = NSMakeSize(image.size.width / scale, image.size.height / scale);
  }
  return image;
}

+ (NSImage *)imageWithData:(NSData *)data
{
  return [[NSImage alloc] initWithData:data];
}

+ (NSImage *)imageWithContentsOfFile:(NSString *)path
{
  return [[NSImage alloc] initWithContentsOfFile:path];
}

+ (NSImage *)imageNamed:(NSString *)name
               inBundle:(NSBundle *)bundle
    compatibleWithTraitCollection:(__unused id)traitCollection
{
  // NSImage has no trait-aware lookup; appearance is resolved at draw time.
  NSBundle *target = bundle ?: NSBundle.mainBundle;
  return [target imageForResource:name] ?: [NSImage imageNamed:name];
}

+ (NSImage *)imageWithCGImage:(CGImageRef)cgImage
{
  if (cgImage == NULL) {
    return nil;
  }
  NSSize size = NSMakeSize(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));
  return [[NSImage alloc] initWithCGImage:cgImage size:size];
}

+ (NSImage *)imageWithCGImage:(CGImageRef)cgImage scale:(CGFloat)scale orientation:(NSInteger)orientation
{
  if (cgImage == NULL) {
    return nil;
  }
  CGFloat effectiveScale = scale > 0 ? scale : 1.0;
  NSSize size = NSMakeSize(CGImageGetWidth(cgImage) / effectiveScale, CGImageGetHeight(cgImage) / effectiveScale);
  NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:size];
  image.scale = effectiveScale;
  return image;
}

- (NSImage *)imageWithRenderingMode:(UIImageRenderingMode)renderingMode
{
  self.template = (renderingMode == UIImageRenderingModeAlwaysTemplate);
  return self;
}

@end

CGFloat UIImageGetScale(NSImage *image)
{
  return image.scale;
}

CGImageRef UIImageGetCGImageRef(NSImage *image)
{
  return image.CGImage;
}

NSImage *UIImageWithData(NSData *data)
{
  return [[NSImage alloc] initWithData:data];
}

NSImage *UIImageWithContentsOfFile(NSString *path)
{
  return [[NSImage alloc] initWithContentsOfFile:path];
}
