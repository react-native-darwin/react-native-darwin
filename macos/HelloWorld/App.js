/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * Deliberately plain: a few nested Views with backgrounds, borders and Text.
 * The point is to exercise flexbox layout, the flipped coordinate system,
 * layer-backed background colours and border drawing -- the things most likely
 * to be wrong first on AppKit.
 *
 * @format
 */

import React from 'react';
import {
  ColorWithSystemEffectMacOS,
  DynamicColorMacOS,
  Platform,
  PlatformColor,
  Text,
  View,
} from 'react-native';
import {Commands} from 'react-native/Libraries/Components/View/ViewNativeComponent';

const SWATCHES = ['#e5484d', '#f5a524', '#30a46c', '#0091ff'];

/** A swatch that reacts to the mouse, via the macOS-only hover props. */
function Swatch({color}) {
  const [hovered, setHovered] = React.useState(false);
  return (
    <View
      style={[styles.swatch, {backgroundColor: color}, hovered && styles.swatchHovered]}
      tooltip={`${color} — hovered: ${hovered}`}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    />
  );
}

export default function App() {
  const [hint, setHint] = React.useState('Hover a swatch');
  const [key, setKey] = React.useState('waiting for a key');
  const [drop, setDrop] = React.useState('drop a file here');
  const cardRef = React.useRef(null);
  // Nothing else will focus it: AppKit moves focus on Tab, and only when Full
  // Keyboard Access is on.
  React.useEffect(() => {
    if (cardRef.current != null) {
      Commands.focus(cardRef.current);
    }
  }, []);
  return (
    <View style={styles.root}>
      <View
        ref={cardRef}
        style={styles.card}
        tooltip="A macOS tooltip, from the tooltip prop"
        focusable
        enableFocusRing
        // Tab is claimed, so it reaches onKeyDown instead of moving focus.
        // ArrowDown is not, so it is reported and still does whatever AppKit
        // would have done with it.
        keyDownEvents={[{key: 'Tab'}, {key: 'Enter'}]}
        onKeyDown={e => {
          const k = e.nativeEvent;
          setKey(
            `onKeyDown ${JSON.stringify(k.key)}` +
              (k.metaKey ? ' +meta' : '') +
              (k.shiftKey ? ' +shift' : '') +
              (k.altKey ? ' +alt' : '') +
              (k.ctrlKey ? ' +ctrl' : ''),
          );
        }}
        onKeyUp={e => {
          // Read before the updater runs: synthetic events are pooled.
          const up = e.nativeEvent.key;
          setKey(k => `${k} / up ${JSON.stringify(up)}`);
        }}>
        <Text style={styles.title}>React Native</Text>
        <Text style={styles.subtitle}>running on {Platform.OS} with AppKit</Text>
        <View style={styles.row}>
          {SWATCHES.map(color => (
            <View
              key={color}
              onMouseEnter={() => setHint(`onMouseEnter ${color}`)}
              onMouseLeave={() => setHint('Hover a swatch')}>
              <Swatch color={color} />
            </View>
          ))}
        </View>
        <Text style={styles.subtitle}>{hint}</Text>
        <Text style={styles.subtitle}>{key}</Text>
        <View
          style={styles.dropZone}
          draggedTypes={['fileUrl', 'image', 'string']}
          onDragEnter={() => setDrop('drag entered')}
          onDragLeave={() => setDrop('drag left')}
          onDrop={e => {
            const files = e.nativeEvent.dataTransfer.files;
            setDrop(
              files.length === 0
                ? 'dropped, no files'
                : `dropped ${files.length}: ${files.map(f => f.name || f.type).join(', ')}`,
            );
          }}>
          <Text style={styles.note}>{drop}</Text>
        </View>
        <View style={styles.row}>
          {/* AppKit semantic name, straight from NSColor */}
          <View style={[styles.swatch, {backgroundColor: PlatformColor('systemIndigoColor')}]} />
          {/* follows light/dark appearance */}
          <View
            style={[
              styles.swatch,
              {backgroundColor: DynamicColorMacOS({light: '#cccccc', dark: '#8b5cf6'})},
            ]}
          />
          {/* AppKit derives the pressed variant itself */}
          <View
            style={[
              styles.swatch,
              {
                backgroundColor: ColorWithSystemEffectMacOS(
                  PlatformColor('systemIndigoColor'),
                  'disabled',
                ),
              },
            ]}
          />
          <View style={[styles.swatch, {backgroundColor: PlatformColor('controlAccentColor')}]} />
        </View>
        <Text style={styles.note}>
          PlatformColor / DynamicColorMacOS / ColorWithSystemEffectMacOS
        </Text>
        <Text style={styles.note}>
          Top-left origin, flexbox layout, layer-backed colour and borders.
        </Text>
      </View>
    </View>
  );
}

const styles = {
  root: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#11181c',
  },
  swatchHovered: {
    transform: [{scale: 1.25}],
  },
  card: {
    width: 460,
    padding: 28,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#2b3a41',
    backgroundColor: '#18262c',
  },
  title: {fontSize: 30, fontWeight: '700', color: '#ffffff'},
  subtitle: {fontSize: 15, color: '#9bb0b8', marginTop: 6},
  row: {flexDirection: 'row', marginTop: 22},
  dropZone: {
    marginTop: 14,
    padding: 14,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#3a4d55',
    backgroundColor: '#12202600',
  },
  swatch: {width: 56, height: 56, borderRadius: 8, marginRight: 12},
  note: {fontSize: 12, color: '#6c8189', marginTop: 22, lineHeight: 18},
};
