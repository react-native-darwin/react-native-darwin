/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIAlertController.h"

@implementation UIAlertAction {
  void (^_handler)(UIAlertAction *);
}

+ (instancetype)actionWithTitle:(NSString *)title
                          style:(UIAlertActionStyle)style
                        handler:(void (^)(UIAlertAction *))handler
{
  UIAlertAction *action = [UIAlertAction new];
  action->_title = [title copy];
  action->_style = style;
  action->_handler = [handler copy];
  action->_enabled = YES;
  return action;
}

- (void)UIKitCompatInvoke
{
  if (_handler != nil) {
    _handler(self);
  }
}

@end

@interface UIAlertAction (UIKitCompatPrivate)
- (void)UIKitCompatInvoke;
@end

@implementation UIActivityViewController {
  NSArray *_activityItems;
}

- (instancetype)initWithActivityItems:(NSArray *)activityItems
                applicationActivities:(__unused NSArray *)applicationActivities
{
  if ((self = [super initWithNibName:nil bundle:nil])) {
    _activityItems = [activityItems copy];
  }
  return self;
}

- (void)loadView
{
  self.view = [[NSView alloc] initWithFrame:NSZeroRect];
}

- (void)presentFromView:(NSView *)view
{
  NSSharingServicePicker *picker = [[NSSharingServicePicker alloc] initWithItems:_activityItems];
  [picker showRelativeToRect:view.bounds ofView:view preferredEdge:NSRectEdgeMinY];
  if (self.completionWithItemsHandler) {
    // AppKit reports completion through a delegate; nothing to report yet.
    self.completionWithItemsHandler(nil, NO, _activityItems, nil);
  }
}

@end

@implementation UIAlertController {
  NSMutableArray<UIAlertAction *> *_actions;
  NSMutableArray<UITextField *> *_textFields;
}

+ (instancetype)alertControllerWithTitle:(NSString *)title
                                 message:(NSString *)message
                          preferredStyle:(UIAlertControllerStyle)preferredStyle
{
  UIAlertController *controller = [[UIAlertController alloc] initWithNibName:nil bundle:nil];
  controller.title = title;
  controller.message = message;
  controller.preferredStyle = preferredStyle;
  return controller;
}

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _actions = [NSMutableArray new];
    _textFields = [NSMutableArray new];
  }
  return self;
}

- (NSArray<UITextField *> *)textFields
{
  return [_textFields copy];
}

- (void)addTextFieldWithConfigurationHandler:(void (^)(UITextField *))configurationHandler
{
  UITextField *field = [[UITextField alloc] initWithFrame:NSMakeRect(0, 0, 240, 24)];
  if (configurationHandler) {
    configurationHandler(field);
  }
  [_textFields addObject:field];
}

- (void)loadView
{
  // NSViewController demands a view even though NSAlert draws its own.
  self.view = [[NSView alloc] initWithFrame:NSZeroRect];
}

- (NSArray<UIAlertAction *> *)actions
{
  return [_actions copy];
}

- (void)addAction:(UIAlertAction *)action
{
  [_actions addObject:action];
}

- (void)presentFromWindow:(NSWindow *)window
{
  NSAlert *alert = [NSAlert new];
  alert.messageText = self.title ?: @"";
  alert.informativeText = self.message ?: @"";

  // NSAlert orders buttons right to left and treats the first as default,
  // which is the opposite of how UIKit lists a cancel action. Put cancel last
  // so it lands on the left, where a Mac user expects it.
  NSMutableArray<UIAlertAction *> *ordered = [NSMutableArray new];
  NSMutableArray<UIAlertAction *> *cancels = [NSMutableArray new];
  for (UIAlertAction *action in _actions) {
    [(action.style == UIAlertActionStyleCancel ? cancels : ordered) addObject:action];
  }
  [ordered addObjectsFromArray:cancels];

  for (UIAlertAction *action in ordered) {
    NSButton *button = [alert addButtonWithTitle:action.title ?: @""];
    button.enabled = action.isEnabled;
    if (action.style == UIAlertActionStyleDestructive) {
      if (@available(macOS 11.0, *)) {
        button.hasDestructiveAction = YES;
      }
    }
  }

  if (_textFields.count == 1) {
    alert.accessoryView = _textFields.firstObject;
  } else if (_textFields.count > 1) {
    NSStackView *stack = [NSStackView stackViewWithViews:_textFields];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    alert.accessoryView = stack;
  }

  void (^handle)(NSModalResponse) = ^(NSModalResponse response) {
    NSInteger index = response - NSAlertFirstButtonReturn;
    if (index >= 0 && index < (NSInteger)ordered.count) {
      [ordered[(NSUInteger)index] UIKitCompatInvoke];
    }
  };

  if (window != nil) {
    [alert beginSheetModalForWindow:window completionHandler:handle];
  } else {
    handle([alert runModal]);
  }
}

@end
