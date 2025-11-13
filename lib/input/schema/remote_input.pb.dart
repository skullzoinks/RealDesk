// This is a generated file - do not edit.
//
// Generated from remote_input.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Buttons extends $pb.GeneratedMessage {
  factory Buttons({
    $core.int? bits,
  }) {
    final result = create();
    if (bits != null) result.bits = bits;
    return result;
  }

  Buttons._();

  factory Buttons.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Buttons.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Buttons',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote.proto'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'bits', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Buttons clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Buttons copyWith(void Function(Buttons) updates) =>
      super.copyWith((message) => updates(message as Buttons)) as Buttons;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Buttons create() => Buttons._();
  @$core.override
  Buttons createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Buttons getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Buttons>(create);
  static Buttons? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get bits => $_getIZ(0);
  @$pb.TagNumber(1)
  set bits($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBits() => $_has(0);
  @$pb.TagNumber(1)
  void clearBits() => $_clearField(1);
}

class Keyboard extends $pb.GeneratedMessage {
  factory Keyboard({
    $core.String? key,
    $core.int? code,
    $core.bool? down,
    $core.int? mods,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (code != null) result.code = code;
    if (down != null) result.down = down;
    if (mods != null) result.mods = mods;
    return result;
  }

  Keyboard._();

  factory Keyboard.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Keyboard.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Keyboard',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote.proto'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aI(2, _omitFieldNames ? '' : 'code')
    ..aOB(3, _omitFieldNames ? '' : 'down')
    ..aI(4, _omitFieldNames ? '' : 'mods', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Keyboard clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Keyboard copyWith(void Function(Keyboard) updates) =>
      super.copyWith((message) => updates(message as Keyboard)) as Keyboard;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Keyboard create() => Keyboard._();
  @$core.override
  Keyboard createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Keyboard getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Keyboard>(create);
  static Keyboard? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get code => $_getIZ(1);
  @$pb.TagNumber(2)
  set code($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get down => $_getBF(2);
  @$pb.TagNumber(3)
  set down($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDown() => $_has(2);
  @$pb.TagNumber(3)
  void clearDown() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get mods => $_getIZ(3);
  @$pb.TagNumber(4)
  set mods($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMods() => $_has(3);
  @$pb.TagNumber(4)
  void clearMods() => $_clearField(4);
}

class MouseAbs extends $pb.GeneratedMessage {
  factory MouseAbs({
    $core.double? x,
    $core.double? y,
    Buttons? btns,
    $core.int? displayW,
    $core.int? displayH,
  }) {
    final result = create();
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (btns != null) result.btns = btns;
    if (displayW != null) result.displayW = displayW;
    if (displayH != null) result.displayH = displayH;
    return result;
  }

  MouseAbs._();

  factory MouseAbs.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MouseAbs.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MouseAbs',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote.proto'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'x', fieldType: $pb.PbFieldType.OF)
    ..aD(2, _omitFieldNames ? '' : 'y', fieldType: $pb.PbFieldType.OF)
    ..aOM<Buttons>(3, _omitFieldNames ? '' : 'btns', subBuilder: Buttons.create)
    ..aI(4, _omitFieldNames ? '' : 'displayW', protoName: 'displayW')
    ..aI(5, _omitFieldNames ? '' : 'displayH', protoName: 'displayH')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MouseAbs clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MouseAbs copyWith(void Function(MouseAbs) updates) =>
      super.copyWith((message) => updates(message as MouseAbs)) as MouseAbs;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MouseAbs create() => MouseAbs._();
  @$core.override
  MouseAbs createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MouseAbs getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MouseAbs>(create);
  static MouseAbs? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get x => $_getN(0);
  @$pb.TagNumber(1)
  set x($core.double value) => $_setFloat(0, value);
  @$pb.TagNumber(1)
  $core.bool hasX() => $_has(0);
  @$pb.TagNumber(1)
  void clearX() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get y => $_getN(1);
  @$pb.TagNumber(2)
  set y($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasY() => $_has(1);
  @$pb.TagNumber(2)
  void clearY() => $_clearField(2);

  @$pb.TagNumber(3)
  Buttons get btns => $_getN(2);
  @$pb.TagNumber(3)
  set btns(Buttons value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasBtns() => $_has(2);
  @$pb.TagNumber(3)
  void clearBtns() => $_clearField(3);
  @$pb.TagNumber(3)
  Buttons ensureBtns() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.int get displayW => $_getIZ(3);
  @$pb.TagNumber(4)
  set displayW($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisplayW() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplayW() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get displayH => $_getIZ(4);
  @$pb.TagNumber(5)
  set displayH($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDisplayH() => $_has(4);
  @$pb.TagNumber(5)
  void clearDisplayH() => $_clearField(5);
}

class MouseRel extends $pb.GeneratedMessage {
  factory MouseRel({
    $core.double? dx,
    $core.double? dy,
    Buttons? btns,
    $core.int? rateHz,
  }) {
    final result = create();
    if (dx != null) result.dx = dx;
    if (dy != null) result.dy = dy;
    if (btns != null) result.btns = btns;
    if (rateHz != null) result.rateHz = rateHz;
    return result;
  }

  MouseRel._();

  factory MouseRel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MouseRel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MouseRel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote.proto'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'dx', fieldType: $pb.PbFieldType.OF)
    ..aD(2, _omitFieldNames ? '' : 'dy', fieldType: $pb.PbFieldType.OF)
    ..aOM<Buttons>(3, _omitFieldNames ? '' : 'btns', subBuilder: Buttons.create)
    ..aI(4, _omitFieldNames ? '' : 'rateHz', protoName: 'rateHz')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MouseRel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MouseRel copyWith(void Function(MouseRel) updates) =>
      super.copyWith((message) => updates(message as MouseRel)) as MouseRel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MouseRel create() => MouseRel._();
  @$core.override
  MouseRel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MouseRel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MouseRel>(create);
  static MouseRel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get dx => $_getN(0);
  @$pb.TagNumber(1)
  set dx($core.double value) => $_setFloat(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDx() => $_has(0);
  @$pb.TagNumber(1)
  void clearDx() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get dy => $_getN(1);
  @$pb.TagNumber(2)
  set dy($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDy() => $_has(1);
  @$pb.TagNumber(2)
  void clearDy() => $_clearField(2);

  @$pb.TagNumber(3)
  Buttons get btns => $_getN(2);
  @$pb.TagNumber(3)
  set btns(Buttons value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasBtns() => $_has(2);
  @$pb.TagNumber(3)
  void clearBtns() => $_clearField(3);
  @$pb.TagNumber(3)
  Buttons ensureBtns() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.int get rateHz => $_getIZ(3);
  @$pb.TagNumber(4)
  set rateHz($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRateHz() => $_has(3);
  @$pb.TagNumber(4)
  void clearRateHz() => $_clearField(4);
}

class MouseWheel extends $pb.GeneratedMessage {
  factory MouseWheel({
    $core.double? dx,
    $core.double? dy,
  }) {
    final result = create();
    if (dx != null) result.dx = dx;
    if (dy != null) result.dy = dy;
    return result;
  }

  MouseWheel._();

  factory MouseWheel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MouseWheel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MouseWheel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote.proto'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'dx', fieldType: $pb.PbFieldType.OF)
    ..aD(2, _omitFieldNames ? '' : 'dy', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MouseWheel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MouseWheel copyWith(void Function(MouseWheel) updates) =>
      super.copyWith((message) => updates(message as MouseWheel)) as MouseWheel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MouseWheel create() => MouseWheel._();
  @$core.override
  MouseWheel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MouseWheel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MouseWheel>(create);
  static MouseWheel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get dx => $_getN(0);
  @$pb.TagNumber(1)
  set dx($core.double value) => $_setFloat(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDx() => $_has(0);
  @$pb.TagNumber(1)
  void clearDx() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get dy => $_getN(1);
  @$pb.TagNumber(2)
  set dy($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDy() => $_has(1);
  @$pb.TagNumber(2)
  void clearDy() => $_clearField(2);
}

class CursorImage extends $pb.GeneratedMessage {
  factory CursorImage({
    $core.int? w,
    $core.int? h,
    $core.int? hotspotX,
    $core.int? hotspotY,
    $core.bool? visible,
    $core.List<$core.int>? rgba,
  }) {
    final result = create();
    if (w != null) result.w = w;
    if (h != null) result.h = h;
    if (hotspotX != null) result.hotspotX = hotspotX;
    if (hotspotY != null) result.hotspotY = hotspotY;
    if (visible != null) result.visible = visible;
    if (rgba != null) result.rgba = rgba;
    return result;
  }

  CursorImage._();

  factory CursorImage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CursorImage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CursorImage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote.proto'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'w')
    ..aI(2, _omitFieldNames ? '' : 'h')
    ..aI(3, _omitFieldNames ? '' : 'hotspotX', protoName: 'hotspotX')
    ..aI(4, _omitFieldNames ? '' : 'hotspotY', protoName: 'hotspotY')
    ..aOB(5, _omitFieldNames ? '' : 'visible')
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'rgba', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CursorImage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CursorImage copyWith(void Function(CursorImage) updates) =>
      super.copyWith((message) => updates(message as CursorImage))
          as CursorImage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CursorImage create() => CursorImage._();
  @$core.override
  CursorImage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CursorImage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CursorImage>(create);
  static CursorImage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get w => $_getIZ(0);
  @$pb.TagNumber(1)
  set w($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasW() => $_has(0);
  @$pb.TagNumber(1)
  void clearW() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get h => $_getIZ(1);
  @$pb.TagNumber(2)
  set h($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasH() => $_has(1);
  @$pb.TagNumber(2)
  void clearH() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get hotspotX => $_getIZ(2);
  @$pb.TagNumber(3)
  set hotspotX($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHotspotX() => $_has(2);
  @$pb.TagNumber(3)
  void clearHotspotX() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get hotspotY => $_getIZ(3);
  @$pb.TagNumber(4)
  set hotspotY($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHotspotY() => $_has(3);
  @$pb.TagNumber(4)
  void clearHotspotY() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get visible => $_getBF(4);
  @$pb.TagNumber(5)
  set visible($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasVisible() => $_has(4);
  @$pb.TagNumber(5)
  void clearVisible() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get rgba => $_getN(5);
  @$pb.TagNumber(6)
  set rgba($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRgba() => $_has(5);
  @$pb.TagNumber(6)
  void clearRgba() => $_clearField(6);
}

class ImeState extends $pb.GeneratedMessage {
  factory ImeState({
    $core.bool? open,
    $core.String? lang,
  }) {
    final result = create();
    if (open != null) result.open = open;
    if (lang != null) result.lang = lang;
    return result;
  }

  ImeState._();

  factory ImeState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImeState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImeState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote.proto'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'open')
    ..aOS(2, _omitFieldNames ? '' : 'lang')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImeState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImeState copyWith(void Function(ImeState) updates) =>
      super.copyWith((message) => updates(message as ImeState)) as ImeState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImeState create() => ImeState._();
  @$core.override
  ImeState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImeState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImeState>(create);
  static ImeState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get open => $_getBF(0);
  @$pb.TagNumber(1)
  set open($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOpen() => $_has(0);
  @$pb.TagNumber(1)
  void clearOpen() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get lang => $_getSZ(1);
  @$pb.TagNumber(2)
  set lang($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLang() => $_has(1);
  @$pb.TagNumber(2)
  void clearLang() => $_clearField(2);
}

class GamepadXInput extends $pb.GeneratedMessage {
  factory GamepadXInput({
    $core.int? buttonsMask,
    $core.double? lx,
    $core.double? ly,
    $core.double? rx,
    $core.double? ry,
    $core.double? lt,
    $core.double? rt,
    $core.int? index,
  }) {
    final result = create();
    if (buttonsMask != null) result.buttonsMask = buttonsMask;
    if (lx != null) result.lx = lx;
    if (ly != null) result.ly = ly;
    if (rx != null) result.rx = rx;
    if (ry != null) result.ry = ry;
    if (lt != null) result.lt = lt;
    if (rt != null) result.rt = rt;
    if (index != null) result.index = index;
    return result;
  }

  GamepadXInput._();

  factory GamepadXInput.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GamepadXInput.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GamepadXInput',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote.proto'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'buttonsMask',
        protoName: 'buttonsMask', fieldType: $pb.PbFieldType.OU3)
    ..aD(2, _omitFieldNames ? '' : 'lx', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'ly', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'rx', fieldType: $pb.PbFieldType.OF)
    ..aD(5, _omitFieldNames ? '' : 'ry', fieldType: $pb.PbFieldType.OF)
    ..aD(6, _omitFieldNames ? '' : 'lt', fieldType: $pb.PbFieldType.OF)
    ..aD(7, _omitFieldNames ? '' : 'rt', fieldType: $pb.PbFieldType.OF)
    ..aI(8, _omitFieldNames ? '' : 'index')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GamepadXInput clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GamepadXInput copyWith(void Function(GamepadXInput) updates) =>
      super.copyWith((message) => updates(message as GamepadXInput))
          as GamepadXInput;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GamepadXInput create() => GamepadXInput._();
  @$core.override
  GamepadXInput createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GamepadXInput getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GamepadXInput>(create);
  static GamepadXInput? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get buttonsMask => $_getIZ(0);
  @$pb.TagNumber(1)
  set buttonsMask($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasButtonsMask() => $_has(0);
  @$pb.TagNumber(1)
  void clearButtonsMask() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get lx => $_getN(1);
  @$pb.TagNumber(2)
  set lx($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLx() => $_has(1);
  @$pb.TagNumber(2)
  void clearLx() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get ly => $_getN(2);
  @$pb.TagNumber(3)
  set ly($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLy() => $_has(2);
  @$pb.TagNumber(3)
  void clearLy() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get rx => $_getN(3);
  @$pb.TagNumber(4)
  set rx($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRx() => $_has(3);
  @$pb.TagNumber(4)
  void clearRx() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get ry => $_getN(4);
  @$pb.TagNumber(5)
  set ry($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRy() => $_has(4);
  @$pb.TagNumber(5)
  void clearRy() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get lt => $_getN(5);
  @$pb.TagNumber(6)
  set lt($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLt() => $_has(5);
  @$pb.TagNumber(6)
  void clearLt() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get rt => $_getN(6);
  @$pb.TagNumber(7)
  set rt($core.double value) => $_setFloat(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRt() => $_has(6);
  @$pb.TagNumber(7)
  void clearRt() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get index => $_getIZ(7);
  @$pb.TagNumber(8)
  set index($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIndex() => $_has(7);
  @$pb.TagNumber(8)
  void clearIndex() => $_clearField(8);
}

class GamepadConnection extends $pb.GeneratedMessage {
  factory GamepadConnection({
    $core.int? index,
    $core.bool? connected,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (connected != null) result.connected = connected;
    return result;
  }

  GamepadConnection._();

  factory GamepadConnection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GamepadConnection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GamepadConnection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote.proto'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..aOB(2, _omitFieldNames ? '' : 'connected')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GamepadConnection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GamepadConnection copyWith(void Function(GamepadConnection) updates) =>
      super.copyWith((message) => updates(message as GamepadConnection))
          as GamepadConnection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GamepadConnection create() => GamepadConnection._();
  @$core.override
  GamepadConnection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GamepadConnection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GamepadConnection>(create);
  static GamepadConnection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get connected => $_getBF(1);
  @$pb.TagNumber(2)
  set connected($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConnected() => $_has(1);
  @$pb.TagNumber(2)
  void clearConnected() => $_clearField(2);
}

class GamepadFeedback extends $pb.GeneratedMessage {
  factory GamepadFeedback({
    $core.int? index,
    $core.double? largeMotor,
    $core.double? smallMotor,
    $core.int? ledCode,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (largeMotor != null) result.largeMotor = largeMotor;
    if (smallMotor != null) result.smallMotor = smallMotor;
    if (ledCode != null) result.ledCode = ledCode;
    return result;
  }

  GamepadFeedback._();

  factory GamepadFeedback.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GamepadFeedback.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GamepadFeedback',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote.proto'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index')
    ..aD(2, _omitFieldNames ? '' : 'largeMotor',
        protoName: 'largeMotor', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'smallMotor',
        protoName: 'smallMotor', fieldType: $pb.PbFieldType.OF)
    ..aI(4, _omitFieldNames ? '' : 'ledCode', protoName: 'ledCode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GamepadFeedback clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GamepadFeedback copyWith(void Function(GamepadFeedback) updates) =>
      super.copyWith((message) => updates(message as GamepadFeedback))
          as GamepadFeedback;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GamepadFeedback create() => GamepadFeedback._();
  @$core.override
  GamepadFeedback createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GamepadFeedback getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GamepadFeedback>(create);
  static GamepadFeedback? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get largeMotor => $_getN(1);
  @$pb.TagNumber(2)
  set largeMotor($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLargeMotor() => $_has(1);
  @$pb.TagNumber(2)
  void clearLargeMotor() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get smallMotor => $_getN(2);
  @$pb.TagNumber(3)
  set smallMotor($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSmallMotor() => $_has(2);
  @$pb.TagNumber(3)
  void clearSmallMotor() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get ledCode => $_getIZ(3);
  @$pb.TagNumber(4)
  set ledCode($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLedCode() => $_has(3);
  @$pb.TagNumber(4)
  void clearLedCode() => $_clearField(4);
}

enum Envelope_Payload {
  keyboard,
  mouseAbs,
  mouseRel,
  mouseWheel,
  cursorImage,
  imeState,
  gamepadXInput,
  gamepadConnection,
  gamepadFeedback,
  notSet
}

class Envelope extends $pb.GeneratedMessage {
  factory Envelope({
    Keyboard? keyboard,
    MouseAbs? mouseAbs,
    MouseRel? mouseRel,
    MouseWheel? mouseWheel,
    CursorImage? cursorImage,
    ImeState? imeState,
    GamepadXInput? gamepadXInput,
    GamepadConnection? gamepadConnection,
    GamepadFeedback? gamepadFeedback,
  }) {
    final result = create();
    if (keyboard != null) result.keyboard = keyboard;
    if (mouseAbs != null) result.mouseAbs = mouseAbs;
    if (mouseRel != null) result.mouseRel = mouseRel;
    if (mouseWheel != null) result.mouseWheel = mouseWheel;
    if (cursorImage != null) result.cursorImage = cursorImage;
    if (imeState != null) result.imeState = imeState;
    if (gamepadXInput != null) result.gamepadXInput = gamepadXInput;
    if (gamepadConnection != null) result.gamepadConnection = gamepadConnection;
    if (gamepadFeedback != null) result.gamepadFeedback = gamepadFeedback;
    return result;
  }

  Envelope._();

  factory Envelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Envelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Envelope_Payload> _Envelope_PayloadByTag = {
    1: Envelope_Payload.keyboard,
    2: Envelope_Payload.mouseAbs,
    3: Envelope_Payload.mouseRel,
    4: Envelope_Payload.mouseWheel,
    5: Envelope_Payload.cursorImage,
    6: Envelope_Payload.imeState,
    7: Envelope_Payload.gamepadXInput,
    8: Envelope_Payload.gamepadConnection,
    9: Envelope_Payload.gamepadFeedback,
    0: Envelope_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Envelope',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote.proto'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9])
    ..aOM<Keyboard>(1, _omitFieldNames ? '' : 'keyboard',
        subBuilder: Keyboard.create)
    ..aOM<MouseAbs>(2, _omitFieldNames ? '' : 'mouseAbs',
        protoName: 'mouseAbs', subBuilder: MouseAbs.create)
    ..aOM<MouseRel>(3, _omitFieldNames ? '' : 'mouseRel',
        protoName: 'mouseRel', subBuilder: MouseRel.create)
    ..aOM<MouseWheel>(4, _omitFieldNames ? '' : 'mouseWheel',
        protoName: 'mouseWheel', subBuilder: MouseWheel.create)
    ..aOM<CursorImage>(5, _omitFieldNames ? '' : 'cursorImage',
        protoName: 'cursorImage', subBuilder: CursorImage.create)
    ..aOM<ImeState>(6, _omitFieldNames ? '' : 'imeState',
        protoName: 'imeState', subBuilder: ImeState.create)
    ..aOM<GamepadXInput>(7, _omitFieldNames ? '' : 'gamepadXInput',
        protoName: 'gamepadXInput', subBuilder: GamepadXInput.create)
    ..aOM<GamepadConnection>(8, _omitFieldNames ? '' : 'gamepadConnection',
        protoName: 'gamepadConnection', subBuilder: GamepadConnection.create)
    ..aOM<GamepadFeedback>(9, _omitFieldNames ? '' : 'gamepadFeedback',
        protoName: 'gamepadFeedback', subBuilder: GamepadFeedback.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Envelope clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Envelope copyWith(void Function(Envelope) updates) =>
      super.copyWith((message) => updates(message as Envelope)) as Envelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Envelope create() => Envelope._();
  @$core.override
  Envelope createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Envelope getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Envelope>(create);
  static Envelope? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  Envelope_Payload whichPayload() => _Envelope_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Keyboard get keyboard => $_getN(0);
  @$pb.TagNumber(1)
  set keyboard(Keyboard value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKeyboard() => $_has(0);
  @$pb.TagNumber(1)
  void clearKeyboard() => $_clearField(1);
  @$pb.TagNumber(1)
  Keyboard ensureKeyboard() => $_ensure(0);

  @$pb.TagNumber(2)
  MouseAbs get mouseAbs => $_getN(1);
  @$pb.TagNumber(2)
  set mouseAbs(MouseAbs value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMouseAbs() => $_has(1);
  @$pb.TagNumber(2)
  void clearMouseAbs() => $_clearField(2);
  @$pb.TagNumber(2)
  MouseAbs ensureMouseAbs() => $_ensure(1);

  @$pb.TagNumber(3)
  MouseRel get mouseRel => $_getN(2);
  @$pb.TagNumber(3)
  set mouseRel(MouseRel value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMouseRel() => $_has(2);
  @$pb.TagNumber(3)
  void clearMouseRel() => $_clearField(3);
  @$pb.TagNumber(3)
  MouseRel ensureMouseRel() => $_ensure(2);

  @$pb.TagNumber(4)
  MouseWheel get mouseWheel => $_getN(3);
  @$pb.TagNumber(4)
  set mouseWheel(MouseWheel value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMouseWheel() => $_has(3);
  @$pb.TagNumber(4)
  void clearMouseWheel() => $_clearField(4);
  @$pb.TagNumber(4)
  MouseWheel ensureMouseWheel() => $_ensure(3);

  @$pb.TagNumber(5)
  CursorImage get cursorImage => $_getN(4);
  @$pb.TagNumber(5)
  set cursorImage(CursorImage value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCursorImage() => $_has(4);
  @$pb.TagNumber(5)
  void clearCursorImage() => $_clearField(5);
  @$pb.TagNumber(5)
  CursorImage ensureCursorImage() => $_ensure(4);

  @$pb.TagNumber(6)
  ImeState get imeState => $_getN(5);
  @$pb.TagNumber(6)
  set imeState(ImeState value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasImeState() => $_has(5);
  @$pb.TagNumber(6)
  void clearImeState() => $_clearField(6);
  @$pb.TagNumber(6)
  ImeState ensureImeState() => $_ensure(5);

  @$pb.TagNumber(7)
  GamepadXInput get gamepadXInput => $_getN(6);
  @$pb.TagNumber(7)
  set gamepadXInput(GamepadXInput value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasGamepadXInput() => $_has(6);
  @$pb.TagNumber(7)
  void clearGamepadXInput() => $_clearField(7);
  @$pb.TagNumber(7)
  GamepadXInput ensureGamepadXInput() => $_ensure(6);

  @$pb.TagNumber(8)
  GamepadConnection get gamepadConnection => $_getN(7);
  @$pb.TagNumber(8)
  set gamepadConnection(GamepadConnection value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasGamepadConnection() => $_has(7);
  @$pb.TagNumber(8)
  void clearGamepadConnection() => $_clearField(8);
  @$pb.TagNumber(8)
  GamepadConnection ensureGamepadConnection() => $_ensure(7);

  @$pb.TagNumber(9)
  GamepadFeedback get gamepadFeedback => $_getN(8);
  @$pb.TagNumber(9)
  set gamepadFeedback(GamepadFeedback value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasGamepadFeedback() => $_has(8);
  @$pb.TagNumber(9)
  void clearGamepadFeedback() => $_clearField(9);
  @$pb.TagNumber(9)
  GamepadFeedback ensureGamepadFeedback() => $_ensure(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
