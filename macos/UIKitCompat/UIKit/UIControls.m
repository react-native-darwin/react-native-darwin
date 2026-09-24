/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "UIControls.h"

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
}

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

- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state
{
  _titleColors[@(state)] = color;
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

@implementation UITableViewCell {
  UILabel *_textLabel;
}

- (instancetype)initWithStyle:(__unused UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  if ((self = [super initWithFrame:NSZeroRect])) {
    _reuseIdentifier = [reuseIdentifier copy];
  }
  return self;
}

- (UILabel *)textLabel
{
  if (_textLabel == nil) {
    _textLabel = [[UILabel alloc] initWithFrame:self.bounds];
    [self addSubview:_textLabel];
  }
  return _textLabel;
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
  }
  return self;
}

- (void)reloadData
{
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
    cell = [[cellClass alloc] initWithFrame:NSZeroRect];
    cell.reuseIdentifier = identifier;
    _cells[identifier] = cell;
  }
  return cell;
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
