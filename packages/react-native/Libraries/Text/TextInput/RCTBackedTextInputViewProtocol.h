/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <RCTPlatformTypes/RCTPlatformTypes.h>
#import <UIKit/UIKit.h>

@protocol RCTBackedTextInputDelegate;

NS_ASSUME_NONNULL_BEGIN

@protocol RCTBackedTextInputViewProtocol <RCTPlatformTextInput>

@property (nonatomic, copy, nullable) NSAttributedString *attributedText;
@property (nonatomic, copy, nullable) NSString *placeholder;
@property (nonatomic, strong, nullable) RCTUIColor *placeholderColor;
@property (nonatomic, assign, readonly) BOOL textWasPasted;
@property (nonatomic, assign, readonly) BOOL dictationRecognizing;
@property (nonatomic, assign) RCTPlatformEdgeInsets textContainerInset;
@property (nonatomic, strong, nullable) RCTPlatformView *inputAccessoryView;
@property (nonatomic, strong, nullable) RCTPlatformView *inputView;
@property (nonatomic, weak, nullable) id<RCTBackedTextInputDelegate> textInputDelegate;
@property (nonatomic, readonly) CGSize contentSize;
@property (nonatomic, strong, nullable) NSDictionary<NSAttributedStringKey, id> *defaultTextAttributes;
@property (nonatomic, assign) BOOL contextMenuHidden;
@property (nonatomic, assign, getter=isEditable) BOOL editable;
@property (nonatomic, assign) BOOL caretHidden;
@property (nonatomic, assign) BOOL enablesReturnKeyAutomatically;
@property (nonatomic, assign) RCTPlatformTextFieldViewMode clearButtonMode;
@property (nonatomic, assign) RCTPlatformDataDetectorTypes dataDetectorTypes;
@property (nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;
@property (nonatomic, strong, nullable) NSString *inputAccessoryViewID;
@property (nonatomic, strong, nullable) NSString *inputAccessoryViewButtonLabel;
@property (nonatomic, assign, readonly) CGFloat zoomScale;
@property (nonatomic, assign, readonly) CGPoint contentOffset;
@property (nonatomic, assign, readonly) RCTPlatformEdgeInsets contentInset;
@property (nullable, nonatomic, copy) NSDictionary<NSAttributedStringKey, id> *typingAttributes;
@property (nonatomic, strong, nullable) NSArray<NSString *> *acceptDragAndDropTypes;

// [macOS
// Grammar checking, which AppKit tracks separately from spell checking. A
// negative value means "leave the platform default alone".
@property (nonatomic, assign) NSInteger grammarCheck;
// Multiline only: keep the text scrollable but draw no vertical scroller.
@property (nonatomic, assign) BOOL hideVerticalScrollIndicator;
// Which pasteboard types onPaste reports: "string", "image", "fileUrl".
// A text view will not accept an image at all unless it says it can read one,
// so this also decides what the field will take.
@property (nonatomic, copy, nullable) NSArray<NSString *> *pastedTypes;
// macOS]

// This protocol disallows direct access to `selectedTextRange` property because
// unwise usage of it can break the `delegate` behavior. So, we always have to
// explicitly specify should `delegate` be notified about the change or not.
// If the change was initiated programmatically, we must NOT notify the delegate.
// If the change was a result of user actions (like typing or touches), we MUST notify the delegate.
- (void)setSelectedTextRange:(nullable RCTPlatformTextRange *)selectedTextRange NS_UNAVAILABLE;
- (void)setSelectedTextRange:(nullable RCTPlatformTextRange *)selectedTextRange notifyDelegate:(BOOL)notifyDelegate;
- (void)scrollRangeToVisible:(NSRange)selectedTextRange;

// This protocol disallows direct access to `text` property because
// unwise usage of it can break the `attributeText` behavior.
// Use `attributedText.string` instead.
@property (nonatomic, copy, nullable) NSString *text NS_UNAVAILABLE;

@property (nonatomic, assign) BOOL disableKeyboardShortcuts;

@end

NS_ASSUME_NONNULL_END
