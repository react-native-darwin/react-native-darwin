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

@class UIAction;
@class UIButtonConfiguration;

#pragma mark - UILabel

@interface UILabel : NSTextField

@property (nonatomic, copy, nullable) NSString *text;
// NSTextField spells it attributedStringValue.
@property (nonatomic, copy, nullable) NSAttributedString *attributedText;
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
// NSButton draws its title through a cell rather than a subview; this vends a
// label wrapper so upstream's font and colour tweaks land somewhere.
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, strong, nullable) UIButtonConfiguration *configuration;
+ (instancetype)buttonWithConfiguration:(UIButtonConfiguration *)configuration
                          primaryAction:(nullable UIAction *)primaryAction;
- (void)setTitle:(nullable NSString *)title forState:(UIControlState)state;
- (void)setTitleColor:(nullable UIColor *)color forState:(UIControlState)state;
- (nullable NSString *)titleForState:(UIControlState)state;
- (void)setImage:(nullable NSImage *)image forState:(UIControlState)state;
- (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;
// iOS 14's block-based action registration.
- (void)addAction:(UIAction *)action forControlEvents:(UIControlEvents)controlEvents;
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

/**
 * The keyboard input accessory bar.
 *
 * macOS has no software keyboard, so nothing ever presents one of these.
 * Declared as a plain view rather than aliased to NSToolbar, because a window
 * toolbar is a different thing with a different API and pretending otherwise
 * would be worse than an honest empty view.
 */
@interface UIBarButtonItem : NSObject
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, weak, nullable) id target;
@property (nonatomic, assign, nullable) SEL action;
@property (nonatomic, assign) NSInteger style;
- (instancetype)initWithTitle:(nullable NSString *)title
                        style:(NSInteger)style
                       target:(nullable id)target
                       action:(nullable SEL)action;
- (instancetype)initWithBarButtonSystemItem:(NSInteger)systemItem
                                     target:(nullable id)target
                                     action:(nullable SEL)action;
@end

typedef NS_ENUM(NSInteger, UIBarButtonItemStyle) {
  UIBarButtonItemStylePlain = 0,
  UIBarButtonItemStyleDone = 2,
};

typedef NS_ENUM(NSInteger, UIBarButtonSystemItem) {
  UIBarButtonSystemItemDone = 0,
  UIBarButtonSystemItemCancel = 1,
  UIBarButtonSystemItemFlexibleSpace = 5,
};

/**
 * iOS 15's declarative button configuration.
 *
 * NSButton is configured through bezel style, colours and a cell, not a value
 * object. This carries the fields React Native's RedBox sets so the code
 * compiles; -applyToButton: maps the ones AppKit can honour.
 */
@interface UIBackgroundConfiguration : NSObject
@property (nonatomic, strong, nullable) UIColor *backgroundColor;
@property (nonatomic, assign) CGFloat cornerRadius;
+ (instancetype)clearConfiguration;
@end

@interface UIButtonConfiguration : NSObject
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, strong, nullable) UIColor *baseForegroundColor;
@property (nonatomic, strong, nullable) UIColor *baseBackgroundColor;
@property (nonatomic, strong, nullable) UIBackgroundConfiguration *background;
@property (nonatomic, copy, nullable) NSAttributedString *attributedTitle;
// UIKit uses directional (leading/trailing) insets here, not left/right.
@property (nonatomic, assign) NSDirectionalEdgeInsets contentInsets;
@property (nonatomic, assign) CGFloat cornerRadius;
+ (instancetype)plainButtonConfiguration;
+ (instancetype)filledButtonConfiguration;
+ (instancetype)tintedButtonConfiguration;
+ (instancetype)grayButtonConfiguration;
@end

@interface UIToolbar : NSView
@property (nonatomic, copy, nullable) NSArray<UIBarButtonItem *> *items;
- (void)setItems:(nullable NSArray<UIBarButtonItem *> *)items animated:(BOOL)animated;
- (void)sizeToFit;
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

typedef NS_ENUM(NSInteger, UITableViewStyle) {
  UITableViewStylePlain = 0,
  UITableViewStyleGrouped,
  UITableViewStyleInsetGrouped,
};

typedef NS_ENUM(NSInteger, UITableViewCellSeparatorStyle) {
  UITableViewCellSeparatorStyleNone = 0,
  UITableViewCellSeparatorStyleSingleLine,
};

typedef NS_ENUM(NSInteger, UITableViewCellSelectionStyle) {
  UITableViewCellSelectionStyleNone = 0,
  UITableViewCellSelectionStyleBlue,
  UITableViewCellSelectionStyleGray,
  UITableViewCellSelectionStyleDefault,
};

// UIKit's "size the row from its content" sentinel.
static const CGFloat UITableViewAutomaticDimension = -1.0;

// iOS 13 menu actions. AppKit uses NSMenuItem; declared so the type resolves.
@interface UIAction : NSObject
@property (nonatomic, copy, nullable) NSString *title;
+ (instancetype)actionWithTitle:(NSString *)title
                          image:(nullable NSImage *)image
                     identifier:(nullable NSString *)identifier
                        handler:(void (^_Nullable)(UIAction *action))handler;
+ (instancetype)actionWithHandler:(void (^_Nullable)(UIAction *action))handler;
- (void)UIKitCompatInvoke;
@end

typedef NS_ENUM(NSInteger, UITableViewScrollPosition) {
  UITableViewScrollPositionNone = 0,
  UITableViewScrollPositionTop,
  UITableViewScrollPositionMiddle,
  UITableViewScrollPositionBottom,
};

// UIKit adds row/section indexing to NSIndexPath.
@interface NSIndexPath (UIKitCompat)
@property (nonatomic, readonly) NSInteger row;
@property (nonatomic, readonly) NSInteger section;
+ (NSIndexPath *)indexPathForRow:(NSInteger)row inSection:(NSInteger)section;
@end

@interface UITableViewCell : NSView
@property (nonatomic, readonly, nullable) UILabel *textLabel;
@property (nonatomic, readonly, nullable) UILabel *detailTextLabel;
@property (nonatomic, readonly, nullable) NSView *contentView;
@property (nonatomic, strong, nullable) NSView *selectedBackgroundView;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;
@property (nonatomic, copy, nullable) NSString *reuseIdentifier;
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier;
@end

/**
 * A parse-and-link stand-in for UITableView, derived from NSView rather than
 * NSTableView.
 *
 * NSTableView already declares dataSource and delegate with its own protocol
 * types, and a category cannot narrow a property's type. The only consumer is
 * the RedBox extra-data view, which is a debugging surface; a real macOS table
 * should wrap an NSTableView rather than subclass one.
 */
@interface UITableView : NSView
@property (nonatomic, weak, nullable) id<UITableViewDataSource> dataSource;
@property (nonatomic, weak, nullable) id<UITableViewDelegate> delegate;
@property (nonatomic, assign) UITableViewCellSeparatorStyle separatorStyle;
@property (nonatomic, strong, nullable) UIColor *separatorColor;
@property (nonatomic, assign) NSInteger indicatorStyle;
@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, assign) CGFloat estimatedRowHeight;
// UITableView inherits UIScrollView's bounce flag.
@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, assign) BOOL alwaysBounceVertical;
@property (nonatomic, assign) BOOL showsVerticalScrollIndicator;
@property (nonatomic, assign) BOOL allowsSelection;
@property (nonatomic, assign) BOOL allowsMultipleSelection;
@property (nonatomic, strong, nullable) NSView *tableHeaderView;
@property (nonatomic, strong, nullable) NSView *tableFooterView;
- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style;
- (void)registerClass:(nullable Class)cellClass forCellReuseIdentifier:(NSString *)identifier;
- (nullable UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
                                          forIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;
- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath
              atScrollPosition:(UITableViewScrollPosition)scrollPosition
                      animated:(BOOL)animated;
- (void)selectRowAtIndexPath:(nullable NSIndexPath *)indexPath
                    animated:(BOOL)animated
              scrollPosition:(UITableViewScrollPosition)scrollPosition;
- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (nullable UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (nullable NSIndexPath *)indexPathForSelectedRow;
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
