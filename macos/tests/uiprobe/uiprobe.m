/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * Drive a running app with real input events.
 *
 * Every macOS defect this fork has found was found by doing this rather than
 * by reading code or watching a build pass: the scroll crash, the swallowed
 * first keystroke, the alert that never appeared, the app with no Edit menu.
 * The build is not evidence that anything works.
 *
 * Events go through CGEventPost, which -- unlike AppleScript's System Events
 * -- needs no Accessibility permission, so this runs unattended in a terminal
 * or in CI.
 *
 * Build:  clang -framework Foundation -framework CoreGraphics -o uiprobe uiprobe.m
 *
 * Usage:
 *   uiprobe click  <x> <y>
 *   uiprobe scroll <x> <y> <ticks> [delta]   negative delta scrolls down
 *   uiprobe type   <x> <y> <text>            clicks first, then types
 *   uiprobe key    <keycode> [cmd|shift|alt|ctrl ...]
 *
 * Coordinates are global screen points, top-left origin.
 * Useful key codes: Return 36, Tab 48, Escape 53, Space 49, V 9.
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

static void pause_(useconds_t us) { usleep(us); }

static void clickAt(double x, double y)
{
  CGPoint p = CGPointMake(x, y);
  CGWarpMouseCursorPosition(p);
  pause_(40000);
  CGEventRef down = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, p, kCGMouseButtonLeft);
  CGEventPost(kCGHIDEventTap, down);
  CFRelease(down);
  pause_(60000);
  CGEventRef up = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, p, kCGMouseButtonLeft);
  CGEventPost(kCGHIDEventTap, up);
  CFRelease(up);
  pause_(250000);
}

static void scrollAt(double x, double y, int ticks, int delta)
{
  CGPoint p = CGPointMake(x, y);
  CGWarpMouseCursorPosition(p);
  for (int i = 0; i < ticks; i++) {
    CGEventRef e = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 1, delta);
    CGEventSetLocation(e, p);
    CGEventPost(kCGHIDEventTap, e);
    CFRelease(e);
    pause_(40000);
  }
}

static void typeString(NSString *text)
{
  for (NSUInteger i = 0; i < text.length; i++) {
    unichar c = [text characterAtIndex:i];
    // Keycode 0 with an explicit unicode string: types the character whatever
    // the keyboard layout is.
    CGEventRef down = CGEventCreateKeyboardEvent(NULL, 0, true);
    CGEventKeyboardSetUnicodeString(down, 1, &c);
    CGEventPost(kCGHIDEventTap, down);
    CFRelease(down);
    CGEventRef up = CGEventCreateKeyboardEvent(NULL, 0, false);
    CGEventKeyboardSetUnicodeString(up, 1, &c);
    CGEventPost(kCGHIDEventTap, up);
    CFRelease(up);
    pause_(30000);
  }
}

static void pressKey(CGKeyCode code, CGEventFlags flags)
{
  // The modifier has to go down as its own event, not just ride along as a
  // flag: a key equivalent the menu has to match -- Cmd+V, say -- is ignored
  // otherwise, and paste silently does nothing.
  struct { CGEventFlags mask; CGKeyCode key; } mods[] = {
      {kCGEventFlagMaskCommand, 55}, {kCGEventFlagMaskShift, 56},
      {kCGEventFlagMaskAlternate, 58}, {kCGEventFlagMaskControl, 59},
  };

  for (size_t i = 0; i < sizeof(mods) / sizeof(mods[0]); i++) {
    if (flags & mods[i].mask) {
      CGEventRef d = CGEventCreateKeyboardEvent(NULL, mods[i].key, true);
      CGEventPost(kCGHIDEventTap, d);
      CFRelease(d);
      pause_(40000);
    }
  }

  CGEventRef down = CGEventCreateKeyboardEvent(NULL, code, true);
  CGEventSetFlags(down, flags);
  CGEventPost(kCGHIDEventTap, down);
  CFRelease(down);
  pause_(40000);
  CGEventRef up = CGEventCreateKeyboardEvent(NULL, code, false);
  CGEventSetFlags(up, flags);
  CGEventPost(kCGHIDEventTap, up);
  CFRelease(up);
  pause_(40000);

  for (size_t i = 0; i < sizeof(mods) / sizeof(mods[0]); i++) {
    if (flags & mods[i].mask) {
      CGEventRef u = CGEventCreateKeyboardEvent(NULL, mods[i].key, false);
      CGEventPost(kCGHIDEventTap, u);
      CFRelease(u);
    }
  }
}

static int usage(void)
{
  fprintf(stderr,
          "usage: uiprobe click  <x> <y>\n"
          "       uiprobe scroll <x> <y> <ticks> [delta]\n"
          "       uiprobe type   <x> <y> <text>\n"
          "       uiprobe key    <keycode> [cmd|shift|alt|ctrl ...]\n");
  return 2;
}

int main(int argc, const char **argv)
{
  @autoreleasepool {
    if (argc < 2) {
      return usage();
    }
    NSString *cmd = @(argv[1]);

    if ([cmd isEqualToString:@"click"] && argc == 4) {
      clickAt(atof(argv[2]), atof(argv[3]));
      printf("clicked %s,%s\n", argv[2], argv[3]);
      return 0;
    }

    if ([cmd isEqualToString:@"scroll"] && argc >= 5) {
      int delta = argc > 5 ? atoi(argv[5]) : -40;
      scrollAt(atof(argv[2]), atof(argv[3]), atoi(argv[4]), delta);
      printf("scrolled %s ticks of %d at %s,%s\n", argv[4], delta, argv[2], argv[3]);
      return 0;
    }

    if ([cmd isEqualToString:@"type"] && argc == 5) {
      clickAt(atof(argv[2]), atof(argv[3]));
      typeString(@(argv[4]));
      printf("typed %s\n", argv[4]);
      return 0;
    }

    if ([cmd isEqualToString:@"key"] && argc >= 3) {
      CGEventFlags flags = 0;
      for (int i = 3; i < argc; i++) {
        NSString *m = @(argv[i]);
        if ([m isEqualToString:@"cmd"]) flags |= kCGEventFlagMaskCommand;
        else if ([m isEqualToString:@"shift"]) flags |= kCGEventFlagMaskShift;
        else if ([m isEqualToString:@"alt"]) flags |= kCGEventFlagMaskAlternate;
        else if ([m isEqualToString:@"ctrl"]) flags |= kCGEventFlagMaskControl;
        else return usage();
      }
      pressKey((CGKeyCode)atoi(argv[2]), flags);
      printf("pressed keycode %s\n", argv[2]);
      return 0;
    }

    return usage();
  }
}
