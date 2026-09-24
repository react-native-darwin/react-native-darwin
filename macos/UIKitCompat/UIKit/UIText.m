/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIText.h"

#import <objc/runtime.h>

// Shared UITextInput geometry. Both concrete classes answer the same way:
// positions are plain character offsets, and the rects come from whichever
// layout machinery the class has.
#define UIKIT_COMPAT_TEXT_INPUT_GEOMETRY                                                   \
  -(UITextRange *)textRangeFromPosition : (UITextPosition *)from toPosition                \
      : (UITextPosition *)toPosition                                                       \
  {                                                                                        \
    return [UITextRange rangeWithStart:from end:toPosition];                               \
  }                                                                                        \
  -(UITextPosition *)positionFromPosition : (UITextPosition *)position offset               \
      : (NSInteger)offset                                                                  \
  {                                                                                        \
    return [UITextPosition positionWithOffset:position.offset + offset];                   \
  }                                                                                        \
  -(UITextPosition *)beginningOfDocument                                                   \
  {                                                                                        \
    return [UITextPosition positionWithOffset:0];                                          \
  }                                                                                        \
  -(NSInteger)offsetFromPosition : (UITextPosition *)from toPosition                        \
      : (UITextPosition *)toPosition                                                       \
  {                                                                                        \
    return toPosition.offset - from.offset;                                                \
  }


@implementation UITextInputMode

+ (UITextInputMode *)currentInputMode
{
  return [UITextInputMode new];
}

- (NSString *)primaryLanguage
{
  // NSTextInputContext knows the current input source's languages.
  return NSTextInputContext.currentInputContext.selectedKeyboardInputSource
      ?: NSLocale.currentLocale.languageCode;
}

@end

@implementation UITextPosition

+ (instancetype)positionWithOffset:(NSInteger)offset
{
  UITextPosition *position = [UITextPosition new];
  position->_offset = offset;
  return position;
}

@end

@implementation UITextRange

+ (instancetype)rangeWithStart:(UITextPosition *)start end:(UITextPosition *)end
{
  UITextRange *range = [UITextRange new];
  range->_start = start;
  range->_end = end;
  return range;
}

- (BOOL)isEmpty
{
  return _start.offset == _end.offset;
}

@end

@implementation UITextField

UIKIT_COMPAT_TEXT_INPUT_GEOMETRY

- (UITextPosition *)endOfDocument
{
  return [UITextPosition positionWithOffset:(NSInteger)self.stringValue.length];
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
  // NSTextField edits through a shared field editor; ask it when it is active.
  NSText *editor = [self.window fieldEditor:NO forObject:self];
  if ([editor isKindOfClass:[NSTextView class]]) {
    NSTextView *textView = (NSTextView *)editor;
    NSUInteger offset = (NSUInteger)MAX((NSInteger)0, position.offset);
    NSRect rect = [textView.layoutManager boundingRectForGlyphRange:NSMakeRange(offset, 0)
                                                    inTextContainer:textView.textContainer];
    return NSRectToCGRect(rect);
  }
  return CGRectMake(0, 0, 1, self.bounds.size.height);
}

- (CGRect)firstRectForRange:(UITextRange *)range
{
  return [self caretRectForPosition:range.start];
}

- (NSArray<UITextSelectionRect *> *)selectionRectsForRange:(__unused UITextRange *)range
{
  return @[];
}

- (NSString *)text
{
  return self.stringValue;
}

- (void)setText:(NSString *)text
{
  self.stringValue = text ?: @"";
}

- (void)buildMenuWithBuilder:(__unused id<UIMenuBuilder>)builder
{
}

- (void)removeDictationResultPlaceholder:(__unused id)placeholder willInsertResult:(__unused BOOL)willInsertResult
{
}

- (id)insertDictationResultPlaceholder
{
  return nil;
}

- (NSString *)placeholder
{
  return self.placeholderString;
}

- (void)setPlaceholder:(NSString *)placeholder
{
  self.placeholderString = placeholder;
}

- (BOOL)canPerformAction:(SEL)action withSender:(__unused id)sender
{
  return [self respondsToSelector:action];
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(__unused UIControlEvents)controlEvents
{
  self.target = target;
  self.action = action;
}

- (void)removeTarget:(__unused id)target action:(__unused SEL)action forControlEvents:(__unused UIControlEvents)events
{
  self.target = nil;
  self.action = NULL;
}

- (id<UITextDropDelegate>)textDropDelegate
{
  return objc_getAssociatedObject(self, @selector(textDropDelegate));
}

- (void)setTextDropDelegate:(id<UITextDropDelegate>)textDropDelegate
{
  objc_setAssociatedObject(self, @selector(textDropDelegate), textDropDelegate, OBJC_ASSOCIATION_ASSIGN);
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
  return NSRectToCGRect([self.cell drawingRectForBounds:NSRectFromCGRect(bounds)]);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
  return [self textRectForBounds:bounds];
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
  return [self textRectForBounds:bounds];
}

- (void)paste:(id)sender
{
  [[self.window fieldEditor:YES forObject:self] paste:sender];
}

- (void)copy:(id)sender
{
  [[self.window fieldEditor:YES forObject:self] copy:sender];
}

- (void)cut:(id)sender
{
  [[self.window fieldEditor:YES forObject:self] cut:sender];
}

- (void)selectAll:(id)sender
{
  [[self.window fieldEditor:YES forObject:self] selectAll:sender];
}

- (NSAttributedString *)attributedPlaceholder
{
  return self.placeholderAttributedString;
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder
{
  self.placeholderAttributedString = attributedPlaceholder;
}

@end

@implementation UITextSelectionRect
@end

@implementation UITextView

UIKIT_COMPAT_TEXT_INPUT_GEOMETRY

- (UITextPosition *)endOfDocument
{
  return [UITextPosition positionWithOffset:(NSInteger)self.string.length];
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
  NSUInteger offset = (NSUInteger)MAX((NSInteger)0, position.offset);
  NSRect rect = [self.layoutManager boundingRectForGlyphRange:NSMakeRange(offset, 0)
                                              inTextContainer:self.textContainer];
  return NSRectToCGRect(rect);
}

- (CGRect)firstRectForRange:(UITextRange *)range
{
  return [self caretRectForPosition:range.start];
}

- (NSArray<UITextSelectionRect *> *)selectionRectsForRange:(__unused UITextRange *)range
{
  return @[];
}

- (NSAttributedString *)attributedText
{
  return self.textStorage;
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
  [self.textStorage setAttributedString:attributedText ?: [NSAttributedString new]];
}

- (NSTextAlignment)textAlignment
{
  return self.alignment;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
  self.alignment = textAlignment;
}

- (id<UITextDropDelegate>)textDropDelegate
{
  return objc_getAssociatedObject(self, @selector(textDropDelegate));
}

- (void)setTextDropDelegate:(id<UITextDropDelegate>)textDropDelegate
{
  objc_setAssociatedObject(self, @selector(textDropDelegate), textDropDelegate, OBJC_ASSOCIATION_ASSIGN);
}

- (CGSize)contentSize
{
  // The size the text actually occupies, which is what UITextView reports.
  [self.layoutManager ensureLayoutForTextContainer:self.textContainer];
  return NSSizeToCGSize([self.layoutManager usedRectForTextContainer:self.textContainer].size);
}

- (void)setContentSize:(__unused CGSize)contentSize
{
  // Driven by the text, not settable. Accepted so upstream assignments compile.
}

- (UIEdgeInsets)contentInset
{
  NSSize inset = self.textContainerInset;
  return UIEdgeInsetsMake(inset.height, inset.width, inset.height, inset.width);
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
  self.textContainerInset = NSMakeSize(contentInset.left, contentInset.top);
}

- (BOOL)canPerformAction:(SEL)action withSender:(__unused id)sender
{
  return [self respondsToSelector:action];
}

- (void)removeDictationResultPlaceholder:(__unused id)placeholder willInsertResult:(__unused BOOL)willInsertResult
{
}

- (id)insertDictationResultPlaceholder
{
  return nil;
}

- (void)buildMenuWithBuilder:(__unused id<UIMenuBuilder>)builder
{
}

- (NSString *)text
{
  return self.string;
}

- (void)setText:(NSString *)text
{
  self.string = text ?: @"";
}

@end
