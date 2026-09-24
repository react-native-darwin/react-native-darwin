#!/usr/bin/env python3
"""
Copyright (c) Meta Platforms, Inc. and affiliates.

This source code is licensed under the MIT license found in the
LICENSE file in the root directory of this source tree.

Rejects a method in the compatibility layer that sends itself the exact same
selector.

This is the layer's characteristic bug. Almost everything here is a category on
an AppKit class, and the natural shape is to forward to the AppKit primitive:

    - (NSString *)string { return [self stringForType:NSPasteboardTypeString]; }

which is correct -- `string` and `stringForType:` are different selectors. But
when the method being added turns out to already exist on the primary class,
the same shape becomes

    + (NSPasteboard *)generalPasteboard { return NSPasteboard.generalPasteboard; }

which is infinite recursion. It compiles without a warning and segfaults at run
time. Clang's -Wobjc-protocol-method-implementation catches some of these and
misses others, so this compares whole selectors directly.

Prefix matching is not enough: -initWithData:scale: legitimately calls
-initWithData:, and -setFrame: legitimately calls -setFrame:display:.
"""

import re
import sys
from pathlib import Path

DEFINITION = re.compile(r'^\s*([-+])\s*\([^)]*\)\s*(.+?)\s*\{?\s*$')
IMPLEMENTATION = re.compile(r'^\s*@implementation\s+([A-Za-z_][A-Za-z0-9_]*)')


def selector_from_definition(sig):
    """`fooWithBar:(T)bar baz:(T)b` -> `fooWithBar:baz:`; `foo` -> `foo`."""
    sig = sig.rstrip('{').strip()
    if ':' not in sig:
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)$', sig)
        return m.group(1) if m else None
    parts = re.findall(r'([A-Za-z_][A-Za-z0-9_]*)\s*:', sig)
    # Drop parameter names: they follow a `)` rather than starting a part.
    parts = re.findall(r'(?:^|\s)([A-Za-z_][A-Za-z0-9_]*)\s*:\s*\(', sig)
    return ''.join(p + ':' for p in parts) if parts else None


def selectors_sent_to_self(body, class_name=None):
    """Full selectors sent to self, or -- for + methods -- to the class itself.

    The class case matters: +generalPasteboard calling NSPasteboard.generalPasteboard
    is the exact bug that segfaulted, and `self` never appears in it.
    """
    found = set()
    receivers = [r'self']
    if class_name:
        receivers.append(re.escape(class_name))
    for m in re.finditer(r'\[\s*(?:' + '|'.join(receivers) + r')\s+', body):
        depth, i = 1, m.end()
        start = i
        while i < len(body) and depth > 0:
            if body[i] == '[':
                depth += 1
            elif body[i] == ']':
                depth -= 1
            i += 1
        inner = body[start:i - 1]
        # Strip nested message sends so their keywords are not counted.
        inner = re.sub(r'\[[^\[\]]*\]', ' ', inner)
        while re.search(r'\[[^\[\]]*\]', inner):
            inner = re.sub(r'\[[^\[\]]*\]', ' ', inner)
        if ':' in inner:
            parts = re.findall(r'([A-Za-z_][A-Za-z0-9_]*)\s*:', inner)
            if parts:
                found.add(''.join(p + ':' for p in parts))
        else:
            word = inner.strip()
            if re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', word):
                found.add(word)
    dot_receivers = '|'.join(receivers)
    for m in re.finditer(r'\b(?:' + dot_receivers + r')\.([A-Za-z_][A-Za-z0-9_]*)\s*(=)?', body):
        name, assigned = m.group(1), m.group(2)
        if assigned:
            found.add('set' + name[0].upper() + name[1:] + ':')
        else:
            found.add(name)
    return found


failures = []

for path in sorted(Path('macos/UIKitCompat').rglob('*.m')):
    lines = path.read_text().split('\n')
    i = 0
    current_class = None
    while i < len(lines):
        impl = IMPLEMENTATION.match(lines[i])
        if impl:
            current_class = impl.group(1)
        m = DEFINITION.match(lines[i])
        if not m or lines[i].strip().endswith(';'):
            i += 1
            continue

        # A signature may wrap across lines; collect until the opening brace.
        sig_lines, j = [lines[i]], i
        while '{' not in lines[j] and j + 1 < len(lines) and j - i < 12:
            j += 1
            sig_lines.append(lines[j])
        sig = ' '.join(sig_lines)
        sm = DEFINITION.match(sig.replace('\n', ' '))
        selector = selector_from_definition(sm.group(2)) if sm else None
        if not selector:
            i += 1
            continue

        depth, k, body, started = 0, j, [], False
        while k < len(lines):
            depth += lines[k].count('{') - lines[k].count('}')
            if '{' in lines[k]:
                started = True
            if started:
                body.append(lines[k])
            if started and depth <= 0:
                break
            k += 1

        if selector in selectors_sent_to_self('\n'.join(body), current_class):
            failures.append(f'{path}:{i + 1}: -{selector} sends itself')
        i = max(k, i + 1)

if failures:
    print('self-recursive methods in the compatibility layer:', file=sys.stderr)
    for f in failures:
        print(f'  {f}', file=sys.stderr)
    print('', file=sys.stderr)
    print('Call the AppKit primitive instead, or drop the method if the primary', file=sys.stderr)
    print('class already provides it.', file=sys.stderr)
    sys.exit(1)

print('    ok: no self-recursive methods')
