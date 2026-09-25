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

#import "UIKeyCommand.h"
#import "UIKitDefines.h"
#import "UIView.h"

// The shim's compile-time names, which is all this layer is for.
//
// Deliberately aliases rather than real classes: registering a UIKit name
// with the ObjC runtime makes Apple's own frameworks mistake the process for
// Catalyst. macOS's one-time-code AutoFill does exactly that for the focused
// text field, and answering yes sends it into UIKitMacHelper, which dlopens a
// UIKit.framework that does not exist here and takes the process down.
//
// Forward-declared first so the aliases can appear before anything uses them.
@class RCTUIKitCompatTextInputMode;
@class RCTUIKitCompatTextPosition;
@class RCTUIKitCompatTextRange;
@class RCTUIKitCompatTextField;
@class RCTUIKitCompatTextSelectionRect;
@class RCTUIKitCompatTextView;
@compatibility_alias UITextInputMode RCTUIKitCompatTextInputMode;
@compatibility_alias UITextPosition RCTUIKitCompatTextPosition;
@compatibility_alias UITextRange RCTUIKitCompatTextRange;
@compatibility_alias UITextField RCTUIKitCompatTextField;
@compatibility_alias UITextSelectionRect RCTUIKitCompatTextSelectionRect;
@compatibility_alias UITextView RCTUIKitCompatTextView;


NS_ASSUME_NONNULL_BEGIN

@class RCTUIKitCompatTextSelectionRect;

/**
 * The active keyboard's input mode.
 *
 * macOS has no software keyboard, but it does have a current input source, and
 * -primaryLanguage is the only thing React Native reads -- it uses it to decide
 * whether the user is composing in a language that needs IME handling. So this
 * answers the real current input source rather than nil.
 */
@interface RCTUIKitCompatTextInputMode : NSObject
@property (nonatomic, readonly, nullable) NSString *primaryLanguage;
@property (class, nonatomic, readonly, nullable) UITextInputMode *currentInputMode;
@end

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
@interface RCTUIKitCompatTextPosition : NSObject
@property (nonatomic, readonly) NSInteger offset;
+ (instancetype)positionWithOffset:(NSInteger)offset;
@end

@interface RCTUIKitCompatTextRange : NSObject
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
// Marked text is the in-progress IME composition. AppKit tracks it on the text
// view itself, so this is nil unless a concrete class overrides it.
@property (nonatomic, readonly, nullable) UITextRange *markedTextRange;
// The active input source. There is no software keyboard on macOS, but the
// current input source still tells you the composition language.
@property (nonatomic, readonly, nullable) UITextInputMode *textInputMode;
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
- (void)textViewDidChangeSelection:(id)textView;
@end

// The runtime name is deliberately not `UITextField`.
//
// The compile-time name is what this shim is for, and @compatibility_alias
// gives that without registering the name with the ObjC runtime. That matters:
// several Apple frameworks decide whether a process is Catalyst by asking
// NSClassFromString for a UIKit class. macOS's one-time-code AutoFill does it
// for the field that holds focus, and answering yes sends it into
// UIKitMacHelper, which dlopens a UIKit.framework that does not exist on this
// platform and takes the process down with it.
@interface RCTUIKitCompatTextField : NSTextField <UITextInput, UITextInputTraits>
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
// The attributes newly typed text takes on. NSTextField has no such property:
// editing happens in the window's shared field editor, which is an NSTextView
// and does. Reads and writes are forwarded there while editing, and held here
// otherwise so the value survives between edits.
@property (nonatomic, copy, null_resettable) NSDictionary<NSAttributedStringKey, id> *typingAttributes;
// NSTextField spells the styled value attributedStringValue.
@property (nonatomic, copy, nullable) NSAttributedString *attributedText;
// NSControl spells it alignment.
@property (nonatomic, assign) NSTextAlignment textAlignment;
// UIKit's clear button. NSTextField has no equivalent, so this is stored and
// otherwise unused -- a Mac text field does not show one.
@property (nonatomic, assign) UITextFieldViewMode clearButtonMode;
// UIKit hangs custom keyboards and toolbars off the responder. AppKit has no
// software keyboard, so these are stored and never presented.
@property (nonatomic, strong, nullable) UIView *inputView;
@property (nonatomic, strong, nullable) UIView *inputAccessoryView;
// Traits UITextInputTraits declares as @optional. A protocol property creates
// no storage, so each one an ObjC class is expected to answer has to be
// synthesized by that class -- omitting them is an unrecognized selector at
// the first access, not a compile error.
@property (nonatomic, assign) UITextSmartInsertDeleteType smartInsertDeleteType;
@property (nonatomic, assign) UITextSmartQuotesType smartQuotesType;
@property (nonatomic, assign) UITextSmartDashesType smartDashesType;
@property (nonatomic, copy, nullable) NSString *textContentType;
@property (nonatomic, strong, nullable) id passwordRules;
@property (nonatomic, assign) BOOL enablesReturnKeyAutomatically;
// UIKit tints the caret and selection through the view; AppKit takes it from
// the field editor's insertion-point colour.
@property (nonatomic, strong, nullable) UIColor *tintColor;
// NSTextField spells it placeholderAttributedString.
@property (nonatomic, copy, nullable) NSAttributedString *attributedPlaceholder;
// UIResponder's editing-menu hook; NSResponder has -validateUserInterfaceItem:.
- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender;
// iOS 13 menu building. AppKit builds menus from NSMenu; accepted and dropped.
- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder;
// UIKit's dictation hooks. No AppKit counterpart; accepted and dropped.
- (void)removeDictationResultPlaceholder:(id)placeholder willInsertResult:(BOOL)willInsertResult;
- (id)insertDictationResultPlaceholder;
// UITextField lets a subclass inset the text and the placeholder. NSTextField
// draws through a cell, so these report the cell's drawing rect.
- (CGRect)textRectForBounds:(CGRect)bounds;
- (CGRect)editingRectForBounds:(CGRect)bounds;
- (CGRect)placeholderRectForBounds:(CGRect)bounds;
// UIResponderStandardEditActions. NSTextField routes these through the field
// editor, so they are forwarded to it.
- (void)paste:(nullable id)sender;
- (void)copy:(nullable id)sender;
- (void)cut:(nullable id)sender;
- (void)selectAll:(nullable id)sender;
// NSControl carries one target/action pair; UIKit registers per control event.
// The pairs are stored per event and dispatched from the AppKit action.
- (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;
- (void)removeTarget:(nullable id)target action:(nullable SEL)action forControlEvents:(UIControlEvents)controlEvents;
@property (nonatomic, weak, nullable) id<UITextDropDelegate> textDropDelegate;
@end

// UIKit's per-rect selection geometry. NSTextView exposes selection as ranges,
// so this is a value object the text layer fills in.
@interface RCTUIKitCompatTextSelectionRect : NSObject
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

@interface RCTUIKitCompatTextView : NSTextView <UITextInput, UITextInputTraits>
// No status bar to scroll to on macOS; stored only.
@property (nonatomic, assign) BOOL scrollsToTop;
// NSTextView spells it alignment.
@property (nonatomic, assign) NSTextAlignment textAlignment;
// NSTextView holds its content in a text storage rather than a property.
@property (nonatomic, copy, nullable) NSAttributedString *attributedText;
// UIScrollView-ish geometry that UITextView inherits; NSTextView is the
// document inside an NSScrollView, so this is the laid-out text size.
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, assign) UIEdgeInsets contentInset;
- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender;
- (void)removeDictationResultPlaceholder:(id)placeholder willInsertResult:(BOOL)willInsertResult;
- (id)insertDictationResultPlaceholder;
- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder;
@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, assign) UIReturnKeyType returnKeyType;
@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, weak, nullable) id<UITextDropDelegate> textDropDelegate;
// As on UITextField: UITextInputTraits declares these @optional, so a class
// expected to answer them has to synthesize its own storage.
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
// UIKit's text view scrolls itself. NSTextView is the document view of an
// enclosing NSScrollView, so this forwards to that.
@property (nonatomic, assign, getter=isScrollEnabled) BOOL scrollEnabled;
@property (nonatomic, assign) CGPoint contentOffset;
@property (nonatomic, assign) CGFloat zoomScale;
@property (nonatomic, strong, nullable) UIView *inputView;
@property (nonatomic, strong, nullable) UIView *inputAccessoryView;
@property (nonatomic, assign) UIDataDetectorTypes dataDetectorTypes;
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
