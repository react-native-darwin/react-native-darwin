/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * Text input types.
 *
 * This is the thinnest part of the layer and the least finished. AppKit's text
 * system differs from UIKit's in kind, not in naming: NSTextField is
 * cell-backed, editing runs through a window-shared field editor, and there is
 * no UITextPosition/UITextRange model at all. What is here is enough to parse
 * and link; correct behaviour is commit 10 in MACOS-FORK.md section 5.2.
 */

#pragma once

#import <AppKit/AppKit.h>

#import "UIKitDefines.h"
#import "UIView.h"

NS_ASSUME_NONNULL_BEGIN

@class UITextSelectionRect;

typedef NS_ENUM(NSInteger, UITextAutocapitalizationType) {
  UITextAutocapitalizationTypeNone = 0,
  UITextAutocapitalizationTypeWords,
  UITextAutocapitalizationTypeSentences,
  UITextAutocapitalizationTypeAllCharacters,
};

typedef NS_ENUM(NSInteger, UITextAutocorrectionType) {
  UITextAutocorrectionTypeDefault = 0,
  UITextAutocorrectionTypeNo,
  UITextAutocorrectionTypeYes,
};

typedef NS_ENUM(NSInteger, UITextSpellCheckingType) {
  UITextSpellCheckingTypeDefault = 0,
  UITextSpellCheckingTypeNo,
  UITextSpellCheckingTypeYes,
};

typedef NS_ENUM(NSInteger, UIKeyboardAppearance) {
  UIKeyboardAppearanceDefault = 0,
  UIKeyboardAppearanceDark,
  UIKeyboardAppearanceLight,
};

// UITextContentType is a string enum, declared alongside its values in
// UIViewAnimation.h.

/**
 * The trait bag UIKit attaches to every text input. React Native's
 * RCTBackedTextInputViewProtocol inherits from it, so the properties have to
 * exist on the protocol rather than only on the concrete classes.
 */
@protocol UITextInputTraits <NSObject>
@optional
@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, assign) UIReturnKeyType returnKeyType;
@property (nonatomic, assign) UITextAutocapitalizationType autocapitalizationType;
@property (nonatomic, assign) UITextAutocorrectionType autocorrectionType;
@property (nonatomic, assign) UITextSpellCheckingType spellCheckingType;
@property (nonatomic, assign) UIKeyboardAppearance keyboardAppearance;
@property (nonatomic, assign) UITextSmartInsertDeleteType smartInsertDeleteType;
@property (nonatomic, assign) UITextSmartQuotesType smartQuotesType;
@property (nonatomic, assign) UITextSmartDashesType smartDashesType;
@property (nonatomic, assign, getter=isSecureTextEntry) BOOL secureTextEntry;
@property (nonatomic, assign) BOOL enablesReturnKeyAutomatically;
@property (nonatomic, copy, nullable) NSString *textContentType;
@property (nonatomic, strong, nullable) id passwordRules;
@end

// UIKit models a caret position as an opaque object so it can survive text
// mutation. AppKit uses plain integer offsets. These wrap an offset so the
// upstream API shape survives.
@interface UITextPosition : NSObject
@property (nonatomic, readonly) NSInteger offset;
+ (instancetype)positionWithOffset:(NSInteger)offset;
@end

@interface UITextRange : NSObject
@property (nonatomic, readonly) UITextPosition *start;
@property (nonatomic, readonly) UITextPosition *end;
@property (nonatomic, readonly, getter=isEmpty) BOOL empty;
+ (instancetype)rangeWithStart:(UITextPosition *)start end:(UITextPosition *)end;
@end

@protocol UITextInput <UITextInputTraits>
@optional
@property (nonatomic, copy, nullable) UITextRange *selectedTextRange;
@property (nonatomic, readonly) UITextPosition *beginningOfDocument;
@property (nonatomic, readonly) UITextPosition *endOfDocument;
- (nullable NSString *)textInRange:(UITextRange *)range;
- (void)replaceRange:(UITextRange *)range withText:(NSString *)text;
- (NSInteger)offsetFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition;
- (nullable UITextRange *)textRangeFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition;
- (nullable UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset;
// Caret and selection geometry. NSTextView exposes this through its layout
// manager, so the concrete classes compute it there.
- (CGRect)caretRectForPosition:(UITextPosition *)position;
- (CGRect)firstRectForRange:(UITextRange *)range;
- (NSArray<UITextSelectionRect *> *)selectionRectsForRange:(UITextRange *)range;
@end

@protocol UITextFieldDelegate <NSTextFieldDelegate>
@optional
- (BOOL)textFieldShouldBeginEditing:(id)textField;
- (void)textFieldDidBeginEditing:(id)textField;
- (BOOL)textFieldShouldEndEditing:(id)textField;
- (void)textFieldDidEndEditing:(id)textField;
- (BOOL)textFieldShouldReturn:(id)textField;
@end

@protocol UITextViewDelegate <NSTextViewDelegate>
@optional
- (BOOL)textViewShouldBeginEditing:(id)textView;
- (void)textViewDidBeginEditing:(id)textView;
- (void)textViewDidChange:(id)textView;
- (void)textViewDidEndEditing:(id)textView;
@end

@interface UITextField : NSTextField <UITextInput, UITextInputTraits>
@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, assign) UIReturnKeyType returnKeyType;
@property (nonatomic, assign) UITextAutocapitalizationType autocapitalizationType;
@property (nonatomic, assign) UITextAutocorrectionType autocorrectionType;
@property (nonatomic, assign) UITextSpellCheckingType spellCheckingType;
@property (nonatomic, assign) UIKeyboardAppearance keyboardAppearance;
@property (nonatomic, assign, getter=isSecureTextEntry) BOOL secureTextEntry;
@property (nonatomic, copy, nullable) NSString *text;
// NSTextField spells it placeholderString.
@property (nonatomic, copy, nullable) NSString *placeholder;
// UIKit's per-field default attributes. NSTextField applies typing attributes
// through its field editor instead, so these are stored and applied on edit.
@property (nonatomic, copy, nullable) NSDictionary<NSAttributedStringKey, id> *defaultTextAttributes;
// NSTextField spells it placeholderAttributedString.
@property (nonatomic, copy, nullable) NSAttributedString *attributedPlaceholder;
// UIResponder's editing-menu hook; NSResponder has -validateUserInterfaceItem:.
- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender;
// iOS 13 menu building. AppKit builds menus from NSMenu; accepted and dropped.
- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder;
// UIKit's dictation hooks. No AppKit counterpart; accepted and dropped.
- (void)removeDictationResultPlaceholder:(id)placeholder willInsertResult:(BOOL)willInsertResult;
- (id)insertDictationResultPlaceholder;
@end

// UIKit's per-rect selection geometry. NSTextView exposes selection as ranges,
// so this is a value object the text layer fills in.
@interface UITextSelectionRect : NSObject
@property (nonatomic, readonly) CGRect rect;
@property (nonatomic, readonly) NSWritingDirection writingDirection;
@property (nonatomic, readonly) BOOL containsStart;
@property (nonatomic, readonly) BOOL containsEnd;
@property (nonatomic, readonly) BOOL isVertical;
@end

@protocol UIEditMenuInteractionDelegate <NSObject>
@optional
- (nullable id)editMenuInteraction:(id)interaction menuForConfiguration:(id)configuration suggestedActions:(NSArray *)suggestedActions;
@end

@interface UITextView : NSTextView <UITextInput, UITextInputTraits>
// No status bar to scroll to on macOS; stored only.
@property (nonatomic, assign) BOOL scrollsToTop;
// NSTextView spells it alignment.
@property (nonatomic, assign) NSTextAlignment textAlignment;
// NSTextView holds its content in a text storage rather than a property.
@property (nonatomic, copy, nullable) NSAttributedString *attributedText;
- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder;
@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, assign) UIReturnKeyType returnKeyType;
@property (nonatomic, copy, nullable) NSString *text;
@end

// UIKit's editing notifications. AppKit posts NSControlTextDidChange and
// NSTextDidChange instead; these names are mapped onto those so upstream
// observers register for something that actually fires.
#define UITextFieldTextDidChangeNotification NSControlTextDidChangeNotification
#define UITextFieldTextDidBeginEditingNotification NSControlTextDidBeginEditingNotification
#define UITextFieldTextDidEndEditingNotification NSControlTextDidEndEditingNotification
#define UITextViewTextDidChangeNotification NSTextDidChangeNotification
#define UITextViewTextDidBeginEditingNotification NSTextDidBeginEditingNotification
#define UITextViewTextDidEndEditingNotification NSTextDidEndEditingNotification

NS_ASSUME_NONNULL_END
