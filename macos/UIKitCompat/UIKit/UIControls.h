/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Portions copyright (c) Microsoft Corporation.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * The UIKit control classes React Native names, backed by AppKit.
 *
 * Each of these is a subclass rather than an alias, because the AppKit
 * counterpart differs in more than naming -- NSTextField is not a UITextField,
 * it is a cell-backed control with a shared field editor.
 */

#pragma once

#import <AppKit/AppKit.h>

#import "UIColor.h"
#import "UIImage.h"
#import "UIKitDefines.h"
#import "UIView.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UILabel

@interface UILabel : NSTextField

@property (nonatomic, copy, nullable) NSString *text;
// NSTextField already declares -textColor; redeclaring it only fights over
// property attributes.
@property (nonatomic, assign) NSInteger numberOfLines;
@property (nonatomic, assign) NSTextAlignment textAlignment;
// UIKit layout margins; macOS has no equivalent, so this is stored only.
@property (nonatomic, assign) UIEdgeInsets layoutMargins;
@property (nonatomic, assign) BOOL adjustsFontSizeToFitWidth;
@property (nonatomic, assign) CGFloat minimumScaleFactor;

@end

#pragma mark - UIImageView

@interface UIImageView : NSImageView

- (instancetype)initWithImage:(nullable NSImage *)image;

@end

#pragma mark - UIActivityIndicatorView

typedef NS_ENUM(NSInteger, UIActivityIndicatorViewStyle) {
  UIActivityIndicatorViewStyleMedium = 0,
  UIActivityIndicatorViewStyleLarge = 1,
};

@interface UIActivityIndicatorView : NSProgressIndicator

@property (nonatomic, assign) UIActivityIndicatorViewStyle activityIndicatorViewStyle;
@property (nonatomic, assign) BOOL hidesWhenStopped;
@property (nonatomic, strong, nullable) UIColor *color;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end

#pragma mark - UISwitch

@interface UISwitch : NSSwitch
- (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;
@property (nonatomic, assign, getter=isOn) BOOL on;
@property (nonatomic, strong, nullable) UIColor *onTintColor;
// NSSwitch draws its own thumb; stored for round-tripping only.
@property (nonatomic, strong, nullable) UIColor *thumbTintColor;
@property (nonatomic, strong, nullable) UIColor *tintColor;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

#pragma mark - UISlider

@interface UISlider : NSSlider
@property (nonatomic, assign) float value;
@property (nonatomic, assign) float minimumValue;
@property (nonatomic, assign) float maximumValue;
- (void)setValue:(float)value animated:(BOOL)animated;
@end

#pragma mark - UIButton

@interface UIButton : NSButton
+ (instancetype)buttonWithType:(UIButtonType)buttonType;
- (void)setTitle:(nullable NSString *)title forState:(UIControlState)state;
- (void)setTitleColor:(nullable UIColor *)color forState:(UIControlState)state;
- (nullable NSString *)titleForState:(UIControlState)state;
- (void)setImage:(nullable NSImage *)image forState:(UIControlState)state;
- (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;
@end

// AppKit has no pull-to-refresh control; a Mac scrolls with a wheel or a
// trackpad and refreshes from a toolbar button. Declared so the component
// parses.
@interface UIRefreshControl : NSView
@property (nonatomic, readonly, getter=isRefreshing) BOOL refreshing;
@property (nonatomic, strong, nullable) UIColor *tintColor;
@property (nonatomic, copy, nullable) NSAttributedString *attributedTitle;
- (void)beginRefreshing;
- (void)endRefreshing;
- (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;
@end

@protocol UIFocusItem <NSObject>
@end

@protocol UIDropInteractionDelegate <NSObject>
@optional
- (BOOL)dropInteraction:(id)interaction canHandleSession:(id)session;
@end

#pragma mark - UITableView

// Used only by the RedBox extra-data view, which is excluded from the macOS
// build. Declared so the file parses rather than needing an upstream guard.
@class UITableView;

@protocol UITableViewDataSource <NSObject>
@optional
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
@end

@protocol UITableViewDelegate <NSObject>
@optional
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(id)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(id)indexPath;
@end

typedef NS_ENUM(NSInteger, UITableViewCellStyle) {
  UITableViewCellStyleDefault = 0,
  UITableViewCellStyleValue1,
  UITableViewCellStyleValue2,
  UITableViewCellStyleSubtitle,
};

@interface UITableViewCell : NSView
@property (nonatomic, readonly, nullable) UILabel *textLabel;
@property (nonatomic, copy, nullable) NSString *reuseIdentifier;
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier;
@end

// Derived from NSView, not NSTableView, on purpose. NSTableView already
// declares dataSource and delegate with NSTableView-specific protocol types,
// which cannot be narrowed to the UIKit ones. This is a parse-level stand-in:
// the only upstream user is the RedBox extra-data view, which the macOS build
// excludes. If a real table is ever needed, it should wrap an NSTableView
// rather than subclass one.
@interface UITableView : NSView
@property (nonatomic, weak, nullable) id<UITableViewDataSource> dataSource;
@property (nonatomic, weak, nullable) id<UITableViewDelegate> delegate;
- (void)registerClass:(nullable Class)cellClass forCellReuseIdentifier:(NSString *)identifier;
- (nullable UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (void)reloadData;
@end

#pragma mark - Accessibility

// NSAccessibilityElement exists but is not an NSView and does not carry UIKit's
// frame/label/traits triple, so React Native's accessibility elements need a
// concrete class of their own.
@interface UIAccessibilityElement : NSAccessibilityElement

@property (nonatomic, weak, nullable) id accessibilityContainer;
@property (nonatomic, assign) CGRect accessibilityFrame;
@property (nonatomic, assign) BOOL isAccessibilityElement;
@property (nonatomic, assign) NSInteger accessibilityTraits;

- (instancetype)initWithAccessibilityContainer:(id)container;

@end

#ifdef __cplusplus
extern "C" {
#endif

// UIKit converts a rect from a view's space to screen space. AppKit's screen
// origin is bottom-left, so this flips as well as converts.
CGRect UIAccessibilityConvertFrameToScreenCoordinates(CGRect rect, NSView *view);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
