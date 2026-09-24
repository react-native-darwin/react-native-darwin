/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIControls.h"

#import <objc/runtime.h>

#import "UIView.h"

#pragma mark - UILabel

@implementation UILabel

- (instancetype)initWithFrame:(NSRect)frameRect
{
  if ((self = [super initWithFrame:frameRect])) {
    // An NSTextField is editable and bordered by default; a UILabel is neither.
    self.bezeled = NO;
    self.editable = NO;
    self.selectable = NO;
    self.drawsBackground = NO;
    self.lineBreakMode = NSLineBreakByTruncatingTail;
  }
  return self;
}

- (NSString *)text
{
  return self.stringValue;
}

- (void)setText:(NSString *)text
{
  self.stringValue = text ?: @"";
}

- (NSAttributedString *)attributedText
{
  return self.attributedStringValue;
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
  self.attributedStringValue = attributedText ?: [NSAttributedString new];
}

- (NSInteger)numberOfLines
{
  return self.maximumNumberOfLines;
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
  self.maximumNumberOfLines = numberOfLines;
  self.usesSingleLineMode = (numberOfLines == 1);
}

- (NSTextAlignment)textAlignment
{
  return self.alignment;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
  self.alignment = textAlignment;
}

@end

#pragma mark - UIImageView

@implementation UIImageView

- (instancetype)initWithImage:(NSImage *)image
{
  if ((self = [super initWithFrame:NSMakeRect(0, 0, image.size.width, image.size.height)])) {
    self.image = image;
    self.imageScaling = NSImageScaleProportionallyUpOrDown;
  }
  return self;
}

- (BOOL)isFlipped
{
  return YES;
}

@end

#pragma mark - UIActivityIndicatorView

@implementation UIActivityIndicatorView

- (instancetype)initWithFrame:(NSRect)frameRect
{
  if ((self = [super initWithFrame:frameRect])) {
    self.style = NSProgressIndicatorStyleSpinning;
    self.indeterminate = YES;
    self.displayedWhenStopped = NO;
    _hidesWhenStopped = YES;
  }
  return self;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)style
{
  _activityIndicatorViewStyle = style;
  self.controlSize = (style == UIActivityIndicatorViewStyleLarge) ? NSControlSizeRegular : NSControlSizeSmall;
}

- (void)setHidesWhenStopped:(BOOL)hidesWhenStopped
{
  _hidesWhenStopped = hidesWhenStopped;
  self.displayedWhenStopped = !hidesWhenStopped;
}

- (void)startAnimating
{
  [self startAnimation:nil];
}

- (void)stopAnimating
{
  [self stopAnimation:nil];
}

- (BOOL)isAnimating
{
  // NSProgressIndicator does not expose its animating state. Visibility is the
  // observable proxy when hidesWhenStopped is on, which is the default.
  return !self.isHidden;
}

@end

#pragma mark - UISwitch

@implementation UISwitch

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(__unused UIControlEvents)controlEvents
{
  self.target = target;
  self.action = action;
}

- (BOOL)isOn
{
  return self.state == NSControlStateValueOn;
}

- (void)setOn:(BOOL)on
{
  self.state = on ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)setOn:(BOOL)on animated:(__unused BOOL)animated
{
  self.on = on;
}

@end

#pragma mark - UISlider

@implementation UISlider

- (float)value
{
  return self.floatValue;
}

- (void)setValue:(float)value
{
  self.floatValue = value;
}

- (void)setValue:(float)value animated:(__unused BOOL)animated
{
  self.floatValue = value;
}

- (float)minimumValue
{
  return (float)self.minValue;
}

- (void)setMinimumValue:(float)minimumValue
{
  self.minValue = minimumValue;
}

- (float)maximumValue
{
  return (float)self.maxValue;
}

- (void)setMaximumValue:(float)maximumValue
{
  self.maxValue = maximumValue;
}

@end

#pragma mark - UIButton

@implementation UIButton {
  NSMutableDictionary<NSNumber *, NSString *> *_titles;
  NSMutableDictionary<NSNumber *, UIColor *> *_titleColors;
  UILabel *_titleLabel;
}

@synthesize configuration = _configuration;

- (instancetype)initWithFrame:(NSRect)frameRect
{
  if ((self = [super initWithFrame:frameRect])) {
    _titles = [NSMutableDictionary new];
    _titleColors = [NSMutableDictionary new];
  }
  return self;
}

// AppKit has one title. UIKit has one per control state. Only the normal state
// is ever rendered here; the rest are stored so reads round-trip.
- (void)setConfiguration:(UIButtonConfiguration *)configuration
{
  _configuration = configuration;
  // Map the parts AppKit can honour; the rest is carried for round-tripping.
  if (configuration.attributedTitle != nil) {
    self.attributedTitle = configuration.attributedTitle;
  } else if (configuration.title != nil) {
    self.title = configuration.title;
  }
  if (configuration.baseBackgroundColor != nil) {
    self.bezelColor = configuration.baseBackgroundColor;
  }
  if (configuration.baseForegroundColor != nil) {
    self.contentTintColor = configuration.baseForegroundColor;
  }
}

- (UILabel *)titleLabel
{
  if (_titleLabel == nil) {
    _titleLabel = [[UILabel alloc] initWithFrame:NSZeroRect];
    _titleLabel.font = self.font;
  }
  return _titleLabel;
}

+ (instancetype)buttonWithConfiguration:(UIButtonConfiguration *)configuration
                          primaryAction:(UIAction *)primaryAction
{
  UIButton *button = [[self alloc] initWithFrame:NSZeroRect];
  button.bezelStyle = NSBezelStyleRounded;
  button.configuration = configuration;
  if (primaryAction != nil) {
    [button addAction:primaryAction forControlEvents:UIControlEventTouchUpInside];
  }
  return button;
}

+ (instancetype)buttonWithType:(__unused UIButtonType)buttonType
{
  // AppKit picks a button style from bezel and bordered flags rather than a
  // type at construction. A plain rounded push button is the closest default.
  UIButton *button = [[self alloc] initWithFrame:NSZeroRect];
  button.bezelStyle = NSBezelStyleRounded;
  return button;
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
  _titles[@(state)] = title;
  if (state == UIControlStateNormal) {
    self.title = title ?: @"";
  }
}

- (NSString *)titleForState:(UIControlState)state
{
  return _titles[@(state)];
}

- (void)setImage:(NSImage *)image forState:(UIControlState)state
{
  if (state == UIControlStateNormal) {
    self.image = image;
  }
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(__unused UIControlEvents)controlEvents
{
  // NSControl has a single target/action pair rather than one per event.
  self.target = target;
  self.action = action;
}

- (void)addAction:(UIAction *)action forControlEvents:(__unused UIControlEvents)controlEvents
{
  // The action object holds the block; the control fires it through the
  // single AppKit target/action pair.
  objc_setAssociatedObject(self, @selector(addAction:forControlEvents:), action, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  self.target = action;
  self.action = @selector(UIKitCompatInvoke);
}

- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state
{
  _titleColors[@(state)] = color;
}

@end

#pragma mark - Button configuration

@implementation UIBackgroundConfiguration

+ (instancetype)clearConfiguration
{
  return [UIBackgroundConfiguration new];
}

@end

@implementation UIButtonConfiguration

+ (instancetype)plainButtonConfiguration
{
  return [UIButtonConfiguration new];
}

+ (instancetype)filledButtonConfiguration
{
  return [UIButtonConfiguration new];
}

+ (instancetype)tintedButtonConfiguration
{
  return [UIButtonConfiguration new];
}

+ (instancetype)grayButtonConfiguration
{
  return [UIButtonConfiguration new];
}

@end

#pragma mark - Input accessory

@implementation UIBarButtonItem

- (instancetype)initWithTitle:(NSString *)title style:(NSInteger)style target:(id)target action:(SEL)action
{
  if ((self = [super init])) {
    _title = [title copy];
    _style = style;
    _target = target;
    _action = action;
  }
  return self;
}

- (instancetype)initWithBarButtonSystemItem:(__unused NSInteger)systemItem target:(id)target action:(SEL)action
{
  return [self initWithTitle:nil style:0 target:target action:action];
}

@end

@implementation UIToolbar

- (void)setItems:(NSArray<UIBarButtonItem *> *)items animated:(__unused BOOL)animated
{
  self.items = items;
}

- (void)sizeToFit
{
  // Nothing presents an accessory bar on macOS, so there is no intrinsic size.
}

@end

#pragma mark - UIRefreshControl

@implementation UIRefreshControl

- (void)beginRefreshing
{
  _refreshing = YES;
}

- (void)endRefreshing
{
  _refreshing = NO;
}

- (void)addTarget:(__unused id)target action:(__unused SEL)action forControlEvents:(__unused UIControlEvents)events
{
  // Nothing drives this on macOS.
}

@end

#pragma mark - UITableView

@implementation UIAction {
  void (^_handler)(UIAction *);
}

+ (instancetype)actionWithTitle:(NSString *)title
                          image:(__unused NSImage *)image
                     identifier:(__unused NSString *)identifier
                        handler:(void (^)(UIAction *))handler
{
  UIAction *action = [UIAction new];
  action.title = title;
  action->_handler = [handler copy];
  return action;
}

+ (instancetype)actionWithHandler:(void (^)(UIAction *))handler
{
  return [self actionWithTitle:@"" image:nil identifier:nil handler:handler];
}

- (void)UIKitCompatInvoke
{
  if (_handler != nil) {
    _handler(self);
  }
}

@end

@implementation NSIndexPath (UIKitCompat)

- (NSInteger)row
{
  return self.length > 1 ? [self indexAtPosition:1] : 0;
}

- (NSInteger)section
{
  return self.length > 0 ? [self indexAtPosition:0] : 0;
}

+ (NSIndexPath *)indexPathForRow:(NSInteger)row inSection:(NSInteger)section
{
  NSUInteger indexes[] = {(NSUInteger)section, (NSUInteger)row};
  return [NSIndexPath indexPathWithIndexes:indexes length:2];
}

@end

@implementation UITableViewCell {
  UILabel *_textLabel;
  UILabel *_detailTextLabel;
  NSView *_contentView;
}

- (instancetype)initWithStyle:(__unused UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  if ((self = [super initWithFrame:NSZeroRect])) {
    _reuseIdentifier = [reuseIdentifier copy];
  }
  return self;
}

- (NSView *)contentView
{
  if (_contentView == nil) {
    _contentView = [[RCTPlatformView alloc] initWithFrame:self.bounds];
    _contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:_contentView];
  }
  return _contentView;
}

- (UILabel *)textLabel
{
  if (_textLabel == nil) {
    _textLabel = [[UILabel alloc] initWithFrame:NSZeroRect];
    [self.contentView addSubview:_textLabel];
  }
  return _textLabel;
}

- (UILabel *)detailTextLabel
{
  if (_detailTextLabel == nil) {
    _detailTextLabel = [[UILabel alloc] initWithFrame:NSZeroRect];
    [self.contentView addSubview:_detailTextLabel];
  }
  return _detailTextLabel;
}

@end

@implementation UITableView {
  NSMutableDictionary<NSString *, Class> *_cellClasses;
  NSMutableDictionary<NSString *, UITableViewCell *> *_cells;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
  if ((self = [super initWithFrame:frameRect])) {
    _cellClasses = [NSMutableDictionary new];
    _cells = [NSMutableDictionary new];
    _rowHeight = 44;
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame style:(__unused UITableViewStyle)style
{
  return [self initWithFrame:NSRectFromCGRect(frame)];
}

- (void)registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier
{
  if (cellClass != Nil) {
    _cellClasses[identifier] = cellClass;
  }
}

- (UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
  UITableViewCell *cell = _cells[identifier];
  if (cell == nil) {
    Class cellClass = _cellClasses[identifier] ?: [UITableViewCell class];
    cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    _cells[identifier] = cell;
  }
  return cell;
}

- (UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
                                          forIndexPath:(__unused NSIndexPath *)indexPath
{
  return [self dequeueReusableCellWithIdentifier:identifier];
}

- (void)reloadData
{
}

- (void)scrollToRowAtIndexPath:(__unused NSIndexPath *)indexPath
              atScrollPosition:(__unused UITableViewScrollPosition)scrollPosition
                      animated:(__unused BOOL)animated
{
}

- (void)selectRowAtIndexPath:(__unused NSIndexPath *)indexPath
                    animated:(__unused BOOL)animated
              scrollPosition:(__unused UITableViewScrollPosition)scrollPosition
{
}

- (void)deselectRowAtIndexPath:(__unused NSIndexPath *)indexPath animated:(__unused BOOL)animated
{
}

- (UITableViewCell *)cellForRowAtIndexPath:(__unused NSIndexPath *)indexPath
{
  return nil;
}

- (NSIndexPath *)indexPathForSelectedRow
{
  return nil;
}

@end

#pragma mark - Accessibility

@implementation UIAccessibilityElement

@synthesize accessibilityFrame = _accessibilityFrame;
@synthesize isAccessibilityElement = _isAccessibilityElement;
@synthesize accessibilityTraits = _accessibilityTraits;

- (instancetype)initWithAccessibilityContainer:(id)container
{
  if ((self = [super init])) {
    _accessibilityContainer = container;
    _isAccessibilityElement = YES;
  }
  return self;
}

@end

CGRect UIAccessibilityConvertFrameToScreenCoordinates(CGRect rect, NSView *view)
{
  if (view == nil || view.window == nil) {
    return rect;
  }
  NSRect inWindow = [view convertRect:NSRectFromCGRect(rect) toView:nil];
  return NSRectToCGRect([view.window convertRectToScreen:inWindow]);
}
