/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIGraphics.h"

@implementation UIGraphicsImageRendererFormat

+ (instancetype)defaultFormat
{
  UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat new];
  format.scale = NSScreen.mainScreen.backingScaleFactor ?: 1.0;
  format.opaque = NO;
  return format;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _scale = 1.0;
    _opaque = NO;
  }
  return self;
}

@end

@implementation UIGraphicsImageRendererContext {
  NSGraphicsContext *_context;
}

- (instancetype)initWithGraphicsContext:(NSGraphicsContext *)context
{
  if ((self = [super init])) {
    _context = context;
  }
  return self;
}

- (CGContextRef)CGContext
{
  return _context.CGContext;
}

- (void)fillRect:(CGRect)rect
{
  NSRectFill(NSRectFromCGRect(rect));
}

- (void)strokeRect:(CGRect)rect
{
  NSFrameRect(NSRectFromCGRect(rect));
}

@end

@implementation UIGraphicsImageRenderer {
  CGSize _size;
  UIGraphicsImageRendererFormat *_format;
}

- (instancetype)initWithSize:(CGSize)size
{
  return [self initWithSize:size format:[UIGraphicsImageRendererFormat defaultFormat]];
}

- (instancetype)initWithSize:(CGSize)size format:(UIGraphicsImageRendererFormat *)format
{
  if ((self = [super init])) {
    _size = size;
    _format = format;
  }
  return self;
}

- (NSImage *)imageWithActions:(NS_NOESCAPE void (^)(UIGraphicsImageRendererContext *))actions
{
  CGFloat scale = _format.scale > 0 ? _format.scale : 1.0;
  NSInteger pixelsWide = (NSInteger)ceil(_size.width * scale);
  NSInteger pixelsHigh = (NSInteger)ceil(_size.height * scale);
  if (pixelsWide <= 0 || pixelsHigh <= 0) {
    return [[NSImage alloc] initWithSize:NSSizeFromCGSize(_size)];
  }

  NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                 pixelsWide:pixelsWide
                                                                 pixelsHigh:pixelsHigh
                                                              bitsPerSample:8
                                                            samplesPerPixel:4
                                                                   hasAlpha:YES
                                                                   isPlanar:NO
                                                             colorSpaceName:NSDeviceRGBColorSpace
                                                                bytesPerRow:0
                                                               bitsPerPixel:0];
  rep.size = NSSizeFromCGSize(_size);

  NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
  [NSGraphicsContext saveGraphicsState];
  NSGraphicsContext.currentContext = context;

  // UIKit's renderer hands back a top-left origin context. Flip so drawing code
  // ported from iOS lands the right way up.
  CGContextRef cgContext = context.CGContext;
  CGContextTranslateCTM(cgContext, 0, _size.height);
  CGContextScaleCTM(cgContext, 1, -1);

  if (actions != nil) {
    actions([[UIGraphicsImageRendererContext alloc] initWithGraphicsContext:context]);
  }

  [NSGraphicsContext restoreGraphicsState];

  NSImage *image = [[NSImage alloc] initWithSize:NSSizeFromCGSize(_size)];
  [image addRepresentation:rep];
  image.scale = scale;
  return image;
}

@end

#pragma mark - Legacy UIGraphics* context stack

// UIKit keeps a global context stack. Mirrored here because a handful of
// upstream call sites still use the old API rather than the renderer.
static NSMutableArray<NSBitmapImageRep *> *UIGraphicsRepStack(void)
{
  static NSMutableArray *stack;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    stack = [NSMutableArray new];
  });
  return stack;
}

void UIGraphicsBeginImageContextWithOptions(CGSize size, __unused BOOL opaque, CGFloat scale)
{
  CGFloat effectiveScale = scale > 0 ? scale : (NSScreen.mainScreen.backingScaleFactor ?: 1.0);
  NSInteger pixelsWide = (NSInteger)ceil(size.width * effectiveScale);
  NSInteger pixelsHigh = (NSInteger)ceil(size.height * effectiveScale);
  if (pixelsWide <= 0 || pixelsHigh <= 0) {
    return;
  }

  NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                 pixelsWide:pixelsWide
                                                                 pixelsHigh:pixelsHigh
                                                              bitsPerSample:8
                                                            samplesPerPixel:4
                                                                   hasAlpha:YES
                                                                   isPlanar:NO
                                                             colorSpaceName:NSDeviceRGBColorSpace
                                                                bytesPerRow:0
                                                               bitsPerPixel:0];
  rep.size = NSSizeFromCGSize(size);
  [UIGraphicsRepStack() addObject:rep];

  [NSGraphicsContext saveGraphicsState];
  NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
  NSGraphicsContext.currentContext = context;
  CGContextRef cgContext = context.CGContext;
  CGContextTranslateCTM(cgContext, 0, size.height);
  CGContextScaleCTM(cgContext, 1, -1);
}

NSImage *UIGraphicsGetImageFromCurrentImageContext(void)
{
  NSBitmapImageRep *rep = UIGraphicsRepStack().lastObject;
  if (rep == nil) {
    return nil;
  }
  NSImage *image = [[NSImage alloc] initWithSize:rep.size];
  [image addRepresentation:rep];
  return image;
}

void UIGraphicsEndImageContext(void)
{
  if (UIGraphicsRepStack().count == 0) {
    return;
  }
  [UIGraphicsRepStack() removeLastObject];
  [NSGraphicsContext restoreGraphicsState];
}

CGContextRef UIGraphicsGetCurrentContext(void)
{
  return NSGraphicsContext.currentContext.CGContext;
}
