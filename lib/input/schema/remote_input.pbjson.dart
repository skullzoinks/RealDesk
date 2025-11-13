// This is a generated file - do not edit.
//
// Generated from remote_input.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use buttonsDescriptor instead')
const Buttons$json = {
  '1': 'Buttons',
  '2': [
    {'1': 'bits', '3': 1, '4': 1, '5': 13, '10': 'bits'},
  ],
};

/// Descriptor for `Buttons`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buttonsDescriptor =
    $convert.base64Decode('CgdCdXR0b25zEhIKBGJpdHMYASABKA1SBGJpdHM=');

@$core.Deprecated('Use keyboardDescriptor instead')
const Keyboard$json = {
  '1': 'Keyboard',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'code', '3': 2, '4': 1, '5': 5, '10': 'code'},
    {'1': 'down', '3': 3, '4': 1, '5': 8, '10': 'down'},
    {'1': 'mods', '3': 4, '4': 1, '5': 13, '10': 'mods'},
  ],
};

/// Descriptor for `Keyboard`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyboardDescriptor = $convert.base64Decode(
    'CghLZXlib2FyZBIQCgNrZXkYASABKAlSA2tleRISCgRjb2RlGAIgASgFUgRjb2RlEhIKBGRvd2'
    '4YAyABKAhSBGRvd24SEgoEbW9kcxgEIAEoDVIEbW9kcw==');

@$core.Deprecated('Use mouseAbsDescriptor instead')
const MouseAbs$json = {
  '1': 'MouseAbs',
  '2': [
    {'1': 'x', '3': 1, '4': 1, '5': 2, '10': 'x'},
    {'1': 'y', '3': 2, '4': 1, '5': 2, '10': 'y'},
    {
      '1': 'btns',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.remote.proto.Buttons',
      '10': 'btns'
    },
    {'1': 'displayW', '3': 4, '4': 1, '5': 5, '10': 'displayW'},
    {'1': 'displayH', '3': 5, '4': 1, '5': 5, '10': 'displayH'},
  ],
};

/// Descriptor for `MouseAbs`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mouseAbsDescriptor = $convert.base64Decode(
    'CghNb3VzZUFicxIMCgF4GAEgASgCUgF4EgwKAXkYAiABKAJSAXkSKQoEYnRucxgDIAEoCzIVLn'
    'JlbW90ZS5wcm90by5CdXR0b25zUgRidG5zEhoKCGRpc3BsYXlXGAQgASgFUghkaXNwbGF5VxIa'
    'CghkaXNwbGF5SBgFIAEoBVIIZGlzcGxheUg=');

@$core.Deprecated('Use mouseRelDescriptor instead')
const MouseRel$json = {
  '1': 'MouseRel',
  '2': [
    {'1': 'dx', '3': 1, '4': 1, '5': 2, '10': 'dx'},
    {'1': 'dy', '3': 2, '4': 1, '5': 2, '10': 'dy'},
    {
      '1': 'btns',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.remote.proto.Buttons',
      '10': 'btns'
    },
    {'1': 'rateHz', '3': 4, '4': 1, '5': 5, '10': 'rateHz'},
  ],
};

/// Descriptor for `MouseRel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mouseRelDescriptor = $convert.base64Decode(
    'CghNb3VzZVJlbBIOCgJkeBgBIAEoAlICZHgSDgoCZHkYAiABKAJSAmR5EikKBGJ0bnMYAyABKA'
    'syFS5yZW1vdGUucHJvdG8uQnV0dG9uc1IEYnRucxIWCgZyYXRlSHoYBCABKAVSBnJhdGVIeg==');

@$core.Deprecated('Use mouseWheelDescriptor instead')
const MouseWheel$json = {
  '1': 'MouseWheel',
  '2': [
    {'1': 'dx', '3': 1, '4': 1, '5': 2, '10': 'dx'},
    {'1': 'dy', '3': 2, '4': 1, '5': 2, '10': 'dy'},
  ],
};

/// Descriptor for `MouseWheel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mouseWheelDescriptor = $convert.base64Decode(
    'CgpNb3VzZVdoZWVsEg4KAmR4GAEgASgCUgJkeBIOCgJkeRgCIAEoAlICZHk=');

@$core.Deprecated('Use cursorImageDescriptor instead')
const CursorImage$json = {
  '1': 'CursorImage',
  '2': [
    {'1': 'w', '3': 1, '4': 1, '5': 5, '10': 'w'},
    {'1': 'h', '3': 2, '4': 1, '5': 5, '10': 'h'},
    {'1': 'hotspotX', '3': 3, '4': 1, '5': 5, '10': 'hotspotX'},
    {'1': 'hotspotY', '3': 4, '4': 1, '5': 5, '10': 'hotspotY'},
    {'1': 'visible', '3': 5, '4': 1, '5': 8, '10': 'visible'},
    {'1': 'rgba', '3': 6, '4': 1, '5': 12, '10': 'rgba'},
  ],
};

/// Descriptor for `CursorImage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cursorImageDescriptor = $convert.base64Decode(
    'CgtDdXJzb3JJbWFnZRIMCgF3GAEgASgFUgF3EgwKAWgYAiABKAVSAWgSGgoIaG90c3BvdFgYAy'
    'ABKAVSCGhvdHNwb3RYEhoKCGhvdHNwb3RZGAQgASgFUghob3RzcG90WRIYCgd2aXNpYmxlGAUg'
    'ASgIUgd2aXNpYmxlEhIKBHJnYmEYBiABKAxSBHJnYmE=');

@$core.Deprecated('Use imeStateDescriptor instead')
const ImeState$json = {
  '1': 'ImeState',
  '2': [
    {'1': 'open', '3': 1, '4': 1, '5': 8, '10': 'open'},
    {'1': 'lang', '3': 2, '4': 1, '5': 9, '10': 'lang'},
  ],
};

/// Descriptor for `ImeState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imeStateDescriptor = $convert.base64Decode(
    'CghJbWVTdGF0ZRISCgRvcGVuGAEgASgIUgRvcGVuEhIKBGxhbmcYAiABKAlSBGxhbmc=');

@$core.Deprecated('Use gamepadXInputDescriptor instead')
const GamepadXInput$json = {
  '1': 'GamepadXInput',
  '2': [
    {'1': 'buttonsMask', '3': 1, '4': 1, '5': 13, '10': 'buttonsMask'},
    {'1': 'lx', '3': 2, '4': 1, '5': 2, '10': 'lx'},
    {'1': 'ly', '3': 3, '4': 1, '5': 2, '10': 'ly'},
    {'1': 'rx', '3': 4, '4': 1, '5': 2, '10': 'rx'},
    {'1': 'ry', '3': 5, '4': 1, '5': 2, '10': 'ry'},
    {'1': 'lt', '3': 6, '4': 1, '5': 2, '10': 'lt'},
    {'1': 'rt', '3': 7, '4': 1, '5': 2, '10': 'rt'},
    {'1': 'index', '3': 8, '4': 1, '5': 5, '10': 'index'},
  ],
};

/// Descriptor for `GamepadXInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gamepadXInputDescriptor = $convert.base64Decode(
    'Cg1HYW1lcGFkWElucHV0EiAKC2J1dHRvbnNNYXNrGAEgASgNUgtidXR0b25zTWFzaxIOCgJseB'
    'gCIAEoAlICbHgSDgoCbHkYAyABKAJSAmx5Eg4KAnJ4GAQgASgCUgJyeBIOCgJyeRgFIAEoAlIC'
    'cnkSDgoCbHQYBiABKAJSAmx0Eg4KAnJ0GAcgASgCUgJydBIUCgVpbmRleBgIIAEoBVIFaW5kZX'
    'g=');

@$core.Deprecated('Use gamepadConnectionDescriptor instead')
const GamepadConnection$json = {
  '1': 'GamepadConnection',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
    {'1': 'connected', '3': 2, '4': 1, '5': 8, '10': 'connected'},
  ],
};

/// Descriptor for `GamepadConnection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gamepadConnectionDescriptor = $convert.base64Decode(
    'ChFHYW1lcGFkQ29ubmVjdGlvbhIUCgVpbmRleBgBIAEoBVIFaW5kZXgSHAoJY29ubmVjdGVkGA'
    'IgASgIUgljb25uZWN0ZWQ=');

@$core.Deprecated('Use gamepadFeedbackDescriptor instead')
const GamepadFeedback$json = {
  '1': 'GamepadFeedback',
  '2': [
    {'1': 'index', '3': 1, '4': 1, '5': 5, '10': 'index'},
    {'1': 'largeMotor', '3': 2, '4': 1, '5': 2, '10': 'largeMotor'},
    {'1': 'smallMotor', '3': 3, '4': 1, '5': 2, '10': 'smallMotor'},
    {'1': 'ledCode', '3': 4, '4': 1, '5': 5, '10': 'ledCode'},
  ],
};

/// Descriptor for `GamepadFeedback`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gamepadFeedbackDescriptor = $convert.base64Decode(
    'Cg9HYW1lcGFkRmVlZGJhY2sSFAoFaW5kZXgYASABKAVSBWluZGV4Eh4KCmxhcmdlTW90b3IYAi'
    'ABKAJSCmxhcmdlTW90b3ISHgoKc21hbGxNb3RvchgDIAEoAlIKc21hbGxNb3RvchIYCgdsZWRD'
    'b2RlGAQgASgFUgdsZWRDb2Rl');

@$core.Deprecated('Use envelopeDescriptor instead')
const Envelope$json = {
  '1': 'Envelope',
  '2': [
    {
      '1': 'keyboard',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.remote.proto.Keyboard',
      '9': 0,
      '10': 'keyboard'
    },
    {
      '1': 'mouseAbs',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.remote.proto.MouseAbs',
      '9': 0,
      '10': 'mouseAbs'
    },
    {
      '1': 'mouseRel',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.remote.proto.MouseRel',
      '9': 0,
      '10': 'mouseRel'
    },
    {
      '1': 'mouseWheel',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.remote.proto.MouseWheel',
      '9': 0,
      '10': 'mouseWheel'
    },
    {
      '1': 'cursorImage',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.remote.proto.CursorImage',
      '9': 0,
      '10': 'cursorImage'
    },
    {
      '1': 'imeState',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.remote.proto.ImeState',
      '9': 0,
      '10': 'imeState'
    },
    {
      '1': 'gamepadXInput',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.remote.proto.GamepadXInput',
      '9': 0,
      '10': 'gamepadXInput'
    },
    {
      '1': 'gamepadConnection',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.remote.proto.GamepadConnection',
      '9': 0,
      '10': 'gamepadConnection'
    },
    {
      '1': 'gamepadFeedback',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.remote.proto.GamepadFeedback',
      '9': 0,
      '10': 'gamepadFeedback'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `Envelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List envelopeDescriptor = $convert.base64Decode(
    'CghFbnZlbG9wZRI0CghrZXlib2FyZBgBIAEoCzIWLnJlbW90ZS5wcm90by5LZXlib2FyZEgAUg'
    'hrZXlib2FyZBI0Cghtb3VzZUFicxgCIAEoCzIWLnJlbW90ZS5wcm90by5Nb3VzZUFic0gAUght'
    'b3VzZUFicxI0Cghtb3VzZVJlbBgDIAEoCzIWLnJlbW90ZS5wcm90by5Nb3VzZVJlbEgAUghtb3'
    'VzZVJlbBI6Cgptb3VzZVdoZWVsGAQgASgLMhgucmVtb3RlLnByb3RvLk1vdXNlV2hlZWxIAFIK'
    'bW91c2VXaGVlbBI9CgtjdXJzb3JJbWFnZRgFIAEoCzIZLnJlbW90ZS5wcm90by5DdXJzb3JJbW'
    'FnZUgAUgtjdXJzb3JJbWFnZRI0CghpbWVTdGF0ZRgGIAEoCzIWLnJlbW90ZS5wcm90by5JbWVT'
    'dGF0ZUgAUghpbWVTdGF0ZRJDCg1nYW1lcGFkWElucHV0GAcgASgLMhsucmVtb3RlLnByb3RvLk'
    'dhbWVwYWRYSW5wdXRIAFINZ2FtZXBhZFhJbnB1dBJPChFnYW1lcGFkQ29ubmVjdGlvbhgIIAEo'
    'CzIfLnJlbW90ZS5wcm90by5HYW1lcGFkQ29ubmVjdGlvbkgAUhFnYW1lcGFkQ29ubmVjdGlvbh'
    'JJCg9nYW1lcGFkRmVlZGJhY2sYCSABKAsyHS5yZW1vdGUucHJvdG8uR2FtZXBhZEZlZWRiYWNr'
    'SABSD2dhbWVwYWRGZWVkYmFja0IJCgdwYXlsb2Fk');
