/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIText.h"

#import <objc/message.h>
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


@implementation RCTUIKitCompatTextInputMode

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

@implementation RCTUIKitCompatTextPosition

+ (instancetype)positionWithOffset:(NSInteger)offset
{
  UITextPosition *position = [UITextPosition new];
  position->_offset = offset;
  return position;
}

@end

@implementation RCTUIKitCompatTextRange

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


/**
 * Hands a key press to the React Native view that owns this text input.
 *
 * AppKit gives a text field's keys to the field editor, which is a descendant
 * of the component view, so the component view's own -keyDown: never runs and
 * `onKeyDown` would be silently dead on a TextInput while working everywhere
 * else. The owner is found by asking rather than by importing it: this layer
 * is below React Native and has no business naming its classes.
 *
 * The answer is whether the view claimed the key -- `keyDownEvents` -- in which
 * case AppKit's own handling is skipped, exactly as for a plain view.
 */
static BOOL RCTUIKitCompatDispatchKeyEvent(NSView *view, NSEvent *event)
{
  for (NSView *candidate = view; candidate != nil; candidate = candidate.superview) {
    if ([candidate respondsToSelector:@selector(handleKeyboardEvent:)]) {
      BOOL (*send)(id, SEL, NSEvent *) = (BOOL (*)(id, SEL, NSEvent *))objc_msgSend;
      return send(candidate, @selector(handleKeyboardEvent:), event);
    }
  }
  return NO;
}


/**
 * The field editor, so key events reach React Native.
 *
 * NSTextField does not handle its own keys: while editing, the window lends it
 * a shared NSTextView -- the field editor -- which inserts the text and stops
 * there, without calling up the responder chain. So a -keyDown: on the field
 * never runs, and `onKeyDown` would work on every view except the one people
 * most expect it on.
 *
 * NSCell vends the editor through -fieldEditorForView:, which is the supported
 * place to substitute one. This subclass forwards the event first and only
 * edits if React Native did not claim the key.
 */
@interface RCTUIKitCompatFieldEditor : NSTextView
@end

@implementation RCTUIKitCompatFieldEditor

- (void)keyDown:(NSEvent *)event
{
  // Dispatch from the client -- the text field being edited -- rather than from
  // the editor, whose superview chain is the window's, not the component tree's.
  NSView *client = [self.delegate isKindOfClass:[NSView class]] ? (NSView *)self.delegate : self;
  if (!RCTUIKitCompatDispatchKeyEvent(client, event)) {
    [super keyDown:event];
  }
}

- (void)keyUp:(NSEvent *)event
{
  NSView *client = [self.delegate isKindOfClass:[NSView class]] ? (NSView *)self.delegate : self;
  if (!RCTUIKitCompatDispatchKeyEvent(client, event)) {
    [super keyUp:event];
  }
}

@end

@interface RCTUIKitCompatTextFieldCell : NSTextFieldCell
@end

@implementation RCTUIKitCompatTextFieldCell

- (NSTextView *)fieldEditorForView:(NSView *)controlView
{
  // One per window, as AppKit's own is: the editor is reused across fields.
  static const char kFieldEditorKey = 0;
  NSWindow *window = controlView.window;
  if (window == nil) {
    return nil;
  }
  RCTUIKitCompatFieldEditor *editor = objc_getAssociatedObject(window, &kFieldEditorKey);
  if (editor == nil) {
    editor = [[RCTUIKitCompatFieldEditor alloc] initWithFrame:NSZeroRect];
    editor.fieldEditor = YES;
    objc_setAssociatedObject(window, &kFieldEditorKey, editor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return editor;
}

@end

@implementation RCTUIKitCompatTextField {
  NSDictionary<NSAttributedStringKey, id> *_typingAttributes;
  NSMutableArray<NSArray *> *_controlEventTargets;
  NSString *_placeholder;
  BOOL _reportedEndEditing;
}

UIKIT_COMPAT_TEXT_INPUT_GEOMETRY

/**
 * The live field editor, when this field is the one being edited.
 *
 * `-fieldEditor:forObject:` with NO does not create one, so this is nil unless
 * editing is actually under way -- which is what makes it safe to ask for on
 * every access.
 */
- (NSTextView *)uikitCompat_activeFieldEditor
{
  NSText *editor = [self.window fieldEditor:NO forObject:self];
  if ([editor isKindOfClass:[NSTextView class]] && self.currentEditor == editor) {
    return (NSTextView *)editor;
  }
  return nil;
}

@synthesize smartInsertDeleteType = _smartInsertDeleteType;
@synthesize smartQuotesType = _smartQuotesType;
@synthesize smartDashesType = _smartDashesType;
@synthesize textContentType = _textContentType;
@synthesize passwordRules = _passwordRules;
@synthesize enablesReturnKeyAutomatically = _enablesReturnKeyAutomatically;

/**
 * Marked text is an in-progress IME composition. AppKit tracks it on the field
 * editor, so there is nothing marked when the field is not being edited.
 */
- (UITextRange *)markedTextRange
{
  NSTextView *editor = [self uikitCompat_activeFieldEditor];
  if (editor == nil || !editor.hasMarkedText) {
    return nil;
  }
  NSRange range = editor.markedRange;
  return [UITextRange rangeWithStart:[UITextPosition positionWithOffset:(NSInteger)range.location]
                                 end:[UITextPosition positionWithOffset:(NSInteger)(range.location + range.length)]];
}

- (UITextInputMode *)textInputMode
{
  // UIKit reports the software keyboard's language. AppKit has no software
  // keyboard, and no caller here does more than null-check the result.
  return nil;
}

- (UIColor *)tintColor
{
  NSTextView *editor = [self uikitCompat_activeFieldEditor];
  return editor != nil ? editor.insertionPointColor : nil;
}

- (void)setTintColor:(UIColor *)tintColor
{
  NSTextView *editor = [self uikitCompat_activeFieldEditor];
  if (editor != nil && tintColor != nil) {
    editor.insertionPointColor = tintColor;
  }
}

/**
 * NSTextField arrives configured as a form control: bezelled, opaque, and with
 * its own focus ring. React Native draws all of that itself on the view that
 * owns this one, so the field has to be stripped back to just the text.
 *
 * `selectable` is the one that matters for behaviour rather than looks. AppKit
 * will not begin editing a field it cannot select -- `acceptsFirstResponder`
 * returns NO, the click does nothing, and no field editor is ever installed.
 */

/**
 * A click on text input must never drag the window.
 *
 * React Native's view defaults `mouseDownCanMoveWindow` to YES, matching
 * AppKit, and AppKit asks the view under the cursor before delivering the
 * event at all -- so a text view that inherits YES swallows its own clicks and
 * starts a zero-pixel window drag instead. There is no mouseDown to debug,
 * which is what makes it worth a comment.
 */
- (BOOL)mouseDownCanMoveWindow
{
  return NO;
}


- (void)keyDown:(NSEvent *)event
{
  if (!RCTUIKitCompatDispatchKeyEvent(self, event)) {
    [super keyDown:event];
  }
}

- (void)keyUp:(NSEvent *)event
{
  if (!RCTUIKitCompatDispatchKeyEvent(self, event)) {
    [super keyUp:event];
  }
}

+ (Class)cellClass
{
  return [RCTUIKitCompatTextFieldCell class];
}

- (void)uikitCompat_configureForTextInput
{
  [super setEditable:YES];
  self.selectable = YES;
  self.bezeled = NO;
  self.bordered = NO;
  self.drawsBackground = NO;
  self.focusRingType = NSFocusRingTypeNone;
  self.usesSingleLineMode = YES;
  self.cell.scrollable = YES;
  self.cell.wraps = NO;
}

- (instancetype)initWithFrame:(NSRect)frame
{
  if (self = [super initWithFrame:frame]) {
    [self uikitCompat_configureForTextInput];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
  if (self = [super initWithCoder:coder]) {
    [self uikitCompat_configureForTextInput];
  }
  return self;
}

/**
 * React Native has no `editable` on UITextField, so RCTUITextField maps the
 * prop onto `enabled` -- and overrides `isEditable` to answer from it. That
 * leaves AppKit's own editable and selectable flags untouched, which is what
 * actually decides whether a click starts editing. Keep them in step here,
 * where the mapping is visible, rather than asking upstream to know about it.
 */
- (void)setEnabled:(BOOL)enabled
{
  [super setEnabled:enabled];
  [super setEditable:enabled];
  self.selectable = enabled;
}

- (NSAttributedString *)attributedText
{
  return self.attributedStringValue;
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
  self.attributedStringValue = attributedText ?: [[NSAttributedString alloc] initWithString:@""];
}

- (NSTextAlignment)textAlignment
{
  return self.alignment;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
  self.alignment = textAlignment;
}

/**
 * The selection, which on AppKit lives in the field editor rather than the
 * field. With no editor there is nothing selected, and UIKit reports nil for
 * a field that is not being edited too.
 */
- (UITextRange *)selectedTextRange
{
  NSTextView *editor = [self uikitCompat_activeFieldEditor];
  if (editor == nil) {
    return nil;
  }
  NSRange range = editor.selectedRange;
  return [UITextRange rangeWithStart:[UITextPosition positionWithOffset:(NSInteger)range.location]
                                 end:[UITextPosition positionWithOffset:(NSInteger)(range.location + range.length)]];
}

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange
{
  NSTextView *editor = [self uikitCompat_activeFieldEditor];
  if (editor == nil || selectedTextRange == nil) {
    return;
  }
  NSInteger start = MAX((NSInteger)0, selectedTextRange.start.offset);
  NSInteger end = MAX(start, selectedTextRange.end.offset);
  NSInteger length = (NSInteger)self.stringValue.length;
  start = MIN(start, length);
  end = MIN(end, length);
  editor.selectedRange = NSMakeRange((NSUInteger)start, (NSUInteger)(end - start));
}

- (NSDictionary<NSAttributedStringKey, id> *)typingAttributes
{
  NSTextView *editor = [self uikitCompat_activeFieldEditor];
  if (editor != nil) {
    return editor.typingAttributes;
  }
  // Between edits there is no field editor to ask. UIKit's own default for a
  // field that was never typed into is its default text attributes.
  return _typingAttributes ?: self.defaultTextAttributes ?: @{};
}

- (void)setTypingAttributes:(NSDictionary<NSAttributedStringKey, id> *)typingAttributes
{
  _typingAttributes = [typingAttributes copy];
  NSTextView *editor = [self uikitCompat_activeFieldEditor];
  if (editor != nil) {
    editor.typingAttributes = _typingAttributes ?: @{};
  }
}

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

/**
 * The plain and attributed placeholders are one value on NSTextField: setting
 * `placeholderAttributedString` clears `placeholderString`, and the reverse.
 * UIKit keeps both, and React Native relies on that -- it sets `placeholder`,
 * builds `attributedPlaceholder` from it, and rebuilds that again whenever the
 * text attributes change. Reading the plain one back through AppKit returns nil
 * the second time round, so the placeholder is rebuilt as empty and silently
 * disappears. Hold the string here instead.
 */
- (NSString *)placeholder
{
  return _placeholder ?: self.placeholderString;
}

- (void)setPlaceholder:(NSString *)placeholder
{
  _placeholder = [placeholder copy];
  self.placeholderString = placeholder;
}

- (BOOL)canPerformAction:(SEL)action withSender:(__unused id)sender
{
  return [self respondsToSelector:action];
}

/**
 * UIKit registers a target/action pair per control event; NSControl carries
 * exactly one pair, fired when editing *ends*. Collapsing the two loses the
 * distinction that matters most here -- RCTBackedTextFieldDelegateAdapter
 * registers for EditingChanged and EditingDidEndOnExit, and with one slot the
 * second registration silently replaces the first. The result is an input that
 * accepts typing and never reports it, which is how `onChangeText` came to
 * never fire.
 *
 * So the pairs are kept per event here, and driven from the AppKit
 * notifications that actually correspond to them.
 */
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents
{
  if (target == nil || action == NULL) {
    return;
  }
  if (_controlEventTargets == nil) {
    _controlEventTargets = [NSMutableArray new];
  }
  [_controlEventTargets addObject:@[
    [NSValue valueWithNonretainedObject:target],
    [NSValue valueWithPointer:action],
    @(controlEvents),
  ]];
}

- (void)removeTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)events
{
  NSMutableArray *kept = [NSMutableArray new];
  for (NSArray *entry in _controlEventTargets) {
    id entryTarget = [entry[0] nonretainedObjectValue];
    SEL entryAction = (SEL)[entry[1] pointerValue];
    UIControlEvents entryEvents = (UIControlEvents)[entry[2] unsignedIntegerValue];
    BOOL matches = (target == nil || entryTarget == target) && (action == NULL || entryAction == action) &&
        (entryEvents & events) != 0;
    if (!matches) {
      [kept addObject:entry];
    }
  }
  _controlEventTargets = kept;
}

- (void)uikitCompat_sendActionsForControlEvents:(UIControlEvents)controlEvents
{
  // Copied first: an action is free to add or remove targets while running.
  for (NSArray *entry in [_controlEventTargets copy]) {
    if (((UIControlEvents)[entry[2] unsignedIntegerValue] & controlEvents) == 0) {
      continue;
    }
    id target = [entry[0] nonretainedObjectValue];
    SEL action = (SEL)[entry[1] pointerValue];
    if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [target performSelector:action withObject:self];
#pragma clang diagnostic pop
    }
  }
}

/**
 * The delegate, as UIKit's protocol rather than AppKit's.
 *
 * NSTextField calls `controlTextDidBeginEditing:` and friends; the adapter on
 * the React Native side implements `textFieldDidBeginEditing:` and friends.
 * Same events, different selectors, so nothing was ever called -- which is why
 * `onFocus`, `onBlur` and `onSubmitEditing` stayed silent while typing itself
 * worked.
 */
- (id<UITextFieldDelegate>)uikitCompat_uiDelegate
{
  id delegate = self.delegate;
  return [delegate conformsToProtocol:@protocol(UITextFieldDelegate)] ? delegate : nil;
}

// NSControl's own hooks, called by the field editor. Preferred over the
// matching notifications: the notifications are posted onward to the control's
// delegate, and observing them from the control itself turned out not to see
// begin and end at all.
- (void)textDidBeginEditing:(NSNotification *)notification
{
  [super textDidBeginEditing:notification];
  _reportedEndEditing = NO;
  [self uikitCompat_sendActionsForControlEvents:UIControlEventEditingDidBegin];

  id<UITextFieldDelegate> delegate = [self uikitCompat_uiDelegate];
  if ([delegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
    [delegate textFieldDidBeginEditing:self];
  }
}

- (void)textDidChange:(NSNotification *)notification
{
  [super textDidChange:notification];
  [self uikitCompat_sendActionsForControlEvents:UIControlEventEditingChanged];
}

/**
 * AppKit reports *why* editing ended in the notification's text movement.
 * Return is what UIKit calls EditingDidEndOnExit -- the submit -- while
 * clicking away or tabbing out is a plain EditingDidEnd.
 */
- (void)textDidEndEditing:(NSNotification *)notification
{
  [super textDidEndEditing:notification];

  NSNumber *movement = notification.userInfo[@"NSTextMovement"];
  BOOL submitted = movement.integerValue == NSReturnTextMovement;
  id<UITextFieldDelegate> delegate = [self uikitCompat_uiDelegate];

  // AppKit ends editing on Return and then re-establishes the field editor with
  // the text selected, so this runs again on the next click -- a second blur
  // with no focus in between. Report the end once per editing session.
  if (_reportedEndEditing) {
    return;
  }
  _reportedEndEditing = YES;

  // Return is a submit before it is an end-of-editing, and the order matters:
  // onSubmitEditing should carry the text, which onBlur may go on to clear.
  // The answer says whether the field should also give up focus: that is
  // `submitBehavior`, which distinguishes `submit` from `blurAndSubmit`.
  BOOL shouldBlurOnSubmit = NO;
  if (submitted && [delegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
    shouldBlurOnSubmit = [delegate textFieldShouldReturn:self];
  }

  UIControlEvents events = UIControlEventEditingDidEnd;
  if (submitted) {
    events |= UIControlEventEditingDidEndOnExit;
  }
  [self uikitCompat_sendActionsForControlEvents:events];

  if ([delegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
    [delegate textFieldDidEndEditing:self];
  }

  if (submitted && shouldBlurOnSubmit) {
    // Asynchronously: AppKit is still unwinding this edit, and taking the
    // responder away underneath it leaves a caret drawn in a field that no
    // longer has focus.
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.currentEditor != nil) {
        [self.window makeFirstResponder:nil];
      }
    });
  }
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

@implementation RCTUIKitCompatTextSelectionRect
@end

@implementation RCTUIKitCompatTextView

/**
 * The delegate, as UIKit's protocol rather than AppKit's -- the same mismatch
 * UITextField has. NSTextView tells its delegate through `textDidChange:` and
 * `textViewDidChangeSelection:`; the React Native adapter listens for
 * `textViewDidChange:` and the rest of the UIKit set. Without the bridge a
 * multiline input accepts typing and reports none of it.
 */

/**
 * A click on text input must never drag the window.
 *
 * React Native's view defaults `mouseDownCanMoveWindow` to YES, matching
 * AppKit, and AppKit asks the view under the cursor before delivering the
 * event at all -- so a text view that inherits YES swallows its own clicks and
 * starts a zero-pixel window drag instead. There is no mouseDown to debug,
 * which is what makes it worth a comment.
 */
- (BOOL)mouseDownCanMoveWindow
{
  return NO;
}

/**
 * NSTextView sizes itself to its text; UITextView fills the frame it is given.
 * Left alone, a multiline input collapses to a single line's height -- it looks
 * right, because React Native's own view draws the background behind it, but
 * only that top strip is hit-testable, so clicking anywhere below the first
 * line does nothing at all.
 *
 * Fixed height with a width-tracking container is what matches UITextView:
 * the text wraps to the width, and the view keeps whatever height layout gave
 * it.
 */

- (void)keyDown:(NSEvent *)event
{
  if (!RCTUIKitCompatDispatchKeyEvent(self, event)) {
    [super keyDown:event];
  }
}

- (void)keyUp:(NSEvent *)event
{
  if (!RCTUIKitCompatDispatchKeyEvent(self, event)) {
    [super keyUp:event];
  }
}

- (void)uikitCompat_configureForTextInput
{
  self.drawsBackground = NO;
  self.richText = NO;
  self.importsGraphics = NO;
  self.allowsUndo = YES;
  self.minSize = NSMakeSize(0, 0);
  self.maxSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
  self.verticallyResizable = NO;
  self.horizontallyResizable = NO;
  self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  self.textContainer.widthTracksTextView = YES;
  self.textContainer.heightTracksTextView = YES;
  self.textContainer.lineFragmentPadding = 0;
}

- (instancetype)initWithFrame:(NSRect)frame
{
  if (self = [super initWithFrame:frame]) {
    [self uikitCompat_configureForTextInput];
  }
  return self;
}

- (instancetype)initWithFrame:(NSRect)frame textContainer:(NSTextContainer *)container
{
  if (self = [super initWithFrame:frame textContainer:container]) {
    [self uikitCompat_configureForTextInput];
  }
  return self;
}

- (id<UITextViewDelegate>)uikitCompat_uiDelegate
{
  id delegate = self.delegate;
  return [delegate conformsToProtocol:@protocol(UITextViewDelegate)] ? delegate : nil;
}

// NSTextView funnels every edit through here, including paste, drops and
// undo -- which a keystroke-level hook would miss.
- (void)didChangeText
{
  [super didChangeText];
  id<UITextViewDelegate> delegate = [self uikitCompat_uiDelegate];
  if ([delegate respondsToSelector:@selector(textViewDidChange:)]) {
    [delegate textViewDidChange:self];
  }
}

- (void)setSelectedRange:(NSRange)range affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)stillSelecting
{
  [super setSelectedRange:range affinity:affinity stillSelecting:stillSelecting];
  id<UITextViewDelegate> delegate = [self uikitCompat_uiDelegate];
  if ([delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
    [delegate textViewDidChangeSelection:self];
  }
}

// NSTextView is its own responder rather than borrowing the window's field
// editor, so begin and end editing are the responder transitions themselves.
- (BOOL)becomeFirstResponder
{
  if (![super becomeFirstResponder]) {
    return NO;
  }
  id<UITextViewDelegate> delegate = [self uikitCompat_uiDelegate];
  if ([delegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
    [delegate textViewDidBeginEditing:self];
  }
  return YES;
}

- (BOOL)resignFirstResponder
{
  if (![super resignFirstResponder]) {
    return NO;
  }
  id<UITextViewDelegate> delegate = [self uikitCompat_uiDelegate];
  if ([delegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
    [delegate textViewDidEndEditing:self];
  }
  return YES;
}

@synthesize autocapitalizationType = _autocapitalizationType;
@synthesize autocorrectionType = _autocorrectionType;
@synthesize spellCheckingType = _spellCheckingType;
@synthesize keyboardAppearance = _keyboardAppearance;
@synthesize smartInsertDeleteType = _smartInsertDeleteType;
@synthesize smartQuotesType = _smartQuotesType;
@synthesize smartDashesType = _smartDashesType;
@synthesize secureTextEntry = _secureTextEntry;
@synthesize enablesReturnKeyAutomatically = _enablesReturnKeyAutomatically;
@synthesize textContentType = _textContentType;
@synthesize passwordRules = _passwordRules;
@synthesize inputView = _inputView;
@synthesize inputAccessoryView = _inputAccessoryView;
@synthesize dataDetectorTypes = _dataDetectorTypes;
@synthesize zoomScale = _zoomScale;

/**
 * UIKit's text view scrolls on its own. NSTextView is the document view inside
 * an NSScrollView, so scrolling is a property of the enclosing view -- and
 * there may not be one, when the text view is used unwrapped.
 */
- (BOOL)isScrollEnabled
{
  NSScrollView *scrollView = self.enclosingScrollView;
  return scrollView != nil ? (scrollView.hasVerticalScroller || scrollView.hasHorizontalScroller) : NO;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
  NSScrollView *scrollView = self.enclosingScrollView;
  scrollView.hasVerticalScroller = scrollEnabled;
  scrollView.hasHorizontalScroller = NO;
}

- (CGPoint)contentOffset
{
  NSScrollView *scrollView = self.enclosingScrollView;
  return scrollView != nil ? scrollView.contentView.bounds.origin : CGPointZero;
}

- (void)setContentOffset:(CGPoint)contentOffset
{
  [self.enclosingScrollView.contentView scrollToPoint:contentOffset];
}

- (UITextInputMode *)textInputMode
{
  // No software keyboard on macOS; callers only null-check this.
  return nil;
}

- (UITextRange *)markedTextRange
{
  if (!self.hasMarkedText) {
    return nil;
  }
  NSRange range = self.markedRange;
  return [UITextRange rangeWithStart:[UITextPosition positionWithOffset:(NSInteger)range.location]
                                 end:[UITextPosition positionWithOffset:(NSInteger)(range.location + range.length)]];
}

- (UITextRange *)selectedTextRange
{
  NSRange range = self.selectedRange;
  return [UITextRange rangeWithStart:[UITextPosition positionWithOffset:(NSInteger)range.location]
                                 end:[UITextPosition positionWithOffset:(NSInteger)(range.location + range.length)]];
}

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange
{
  if (selectedTextRange == nil) {
    return;
  }
  NSInteger length = (NSInteger)self.string.length;
  NSInteger start = MIN(MAX((NSInteger)0, selectedTextRange.start.offset), length);
  NSInteger end = MIN(MAX(start, selectedTextRange.end.offset), length);
  self.selectedRange = NSMakeRange((NSUInteger)start, (NSUInteger)(end - start));
}

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
