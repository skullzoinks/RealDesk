import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';

import '../input/schema/remote_input.pb.dart' as pb;

/// Data channel manager for sending input events that match the
/// remotecontrol `remote/proto/serializer.h` JSON schema.
class DataChannelManager {
  DataChannelManager({
    required RTCDataChannel? rtChannel,
    required RTCDataChannel? reliableChannel,
    bool useProtobuf = false,
  })  : _rt = rtChannel,
        _reliable = reliableChannel,
        _useProtobuf = useProtobuf,
        _logger = Logger();

  final RTCDataChannel? _rt;
  final RTCDataChannel? _reliable;
  final bool _useProtobuf;
  final Logger _logger;

  RTCDataChannel? _choose(bool reliablePreferred) {
    if (reliablePreferred) {
      return _reliable ?? _rt;
    }
    return _rt ?? _reliable;
  }

  void _sendJson(
    Map<String, dynamic> msg, {
    bool reliable = false,
  }) {
    final ch = _choose(reliable);
    if (ch == null) {
      _logger.w('DataChannel not available (reliable=$reliable)');
      return;
    }
    if (ch.state != RTCDataChannelState.RTCDataChannelOpen) {
      _logger.w('DataChannel not open (label=${ch.label}, state=${ch.state})');
      return;
    }
    try {
      ch.send(RTCDataChannelMessage(jsonEncode(msg)));
      _logger.d('DC(${ch.label}) <- ${msg['type']} [JSON]');
    } catch (e, stackTrace) {
      _logger.e('Failed to send data channel message',
          error: e, stackTrace: stackTrace);
    }
  }

  void _sendProtobuf(
    pb.Envelope envelope, {
    bool reliable = false,
  }) {
    final ch = _choose(reliable);
    if (ch == null) {
      _logger.w('DataChannel not available (reliable=$reliable)');
      return;
    }
    if (ch.state != RTCDataChannelState.RTCDataChannelOpen) {
      _logger.w('DataChannel not open (label=${ch.label}, state=${ch.state})');
      return;
    }
    try {
      final bytes = envelope.writeToBuffer();
      ch.send(RTCDataChannelMessage.fromBinary(Uint8List.fromList(bytes)));
      _logger.d('DC(${ch.label}) <- ${envelope.whichPayload()} [Protobuf]');
    } catch (e, stackTrace) {
      _logger.e('Failed to send protobuf message',
          error: e, stackTrace: stackTrace);
    }
  }

  // --- Helpers (mask, timestamp) ---
  int _buttonsMaskFromList(Iterable<String>? buttons) {
    if (buttons == null) return 0;
    int mask = 0;
    for (final b in buttons) {
      switch (b) {
        case 'left':
        case 'primary':
        case 'l':
          mask |= 1; // left
          break;
        case 'right':
        case 'secondary':
        case 'r':
          mask |= 4; // right (bit 2)
          break;
        case 'middle':
        case 'tertiary':
        case 'm':
          mask |= 2; // middle (bit 1)
          break;
        case 'back':
          mask |= 8;
          break;
        case 'forward':
          mask |= 16;
          break;
        default:
          break;
      }
    }
    return mask;
  }

  int _modsMask(Map<String, bool>? meta) {
    if (meta == null) return 0;
    int mask = 0;
    if (meta['ctrl'] == true) mask |= 1;
    if (meta['alt'] == true) mask |= 2;
    if (meta['shift'] == true) mask |= 4;
    if (meta['meta'] == true) mask |= 8;
    return mask;
  }

  // --- Event senders matching remotecontrol schema ---

  void sendMouseAbs({
    required double x,
    required double y,
    required int displayW,
    required int displayH,
    Iterable<String>? buttons,
  }) {
    if (_useProtobuf) {
      final envelope = pb.Envelope()
        ..mouseAbs = (pb.MouseAbs()
          ..x = x
          ..y = y
          ..btns = (pb.Buttons()..bits = _buttonsMaskFromList(buttons))
          ..displayW = displayW
          ..displayH = displayH);
      _sendProtobuf(envelope, reliable: true);
    } else {
      _sendJson(
        {
          'type': 'mouseAbs',
          'x': x,
          'y': y,
          'buttons': _buttonsMaskFromList(buttons),
          'displayW': displayW,
          'displayH': displayH,
        },
        reliable: true,
      );
    }
  }

  void sendMouseRel({
    required double dx,
    required double dy,
    Iterable<String>? buttons,
    int rateHz = 0,
  }) {
    if (_useProtobuf) {
      final envelope = pb.Envelope()
        ..mouseRel = (pb.MouseRel()
          ..dx = dx
          ..dy = dy
          ..btns = (pb.Buttons()..bits = _buttonsMaskFromList(buttons))
          ..rateHz = rateHz);
      _sendProtobuf(envelope);
    } else {
      _sendJson(
        {
          'type': 'mouseRel',
          'dx': dx,
          'dy': dy,
          'buttons': _buttonsMaskFromList(buttons),
          'rateHz': rateHz,
        },
      );
    }
  }

  void sendWheel({
    required double dx,
    required double dy,
  }) {
    if (_useProtobuf) {
      final envelope = pb.Envelope()
        ..mouseWheel = (pb.MouseWheel()
          ..dx = dx
          ..dy = dy);
      _sendProtobuf(envelope, reliable: true);
    } else {
      _sendJson(
        {
          'type': 'mouseWheel',
          'dx': dx,
          'dy': dy,
        },
        reliable: true,
      );
    }
  }

  void sendTouchEvent({required List<Map<String, dynamic>> touches}) {
    // Note: Touch events are not yet defined in the protobuf schema,
    // so we always use JSON for now
    _sendJson(
      {
        'type': 'touch',
        'touches': touches,
      },
    );
  }

  void sendGamepadState({
    required int index,
    required int buttonsMask,
    required double lx,
    required double ly,
    required double rx,
    required double ry,
    required double lt,
    required double rt,
  }) {
    if (_useProtobuf) {
      final envelope = pb.Envelope()
        ..gamepadXInput = (pb.GamepadXInput()
          ..index = index
          ..buttonsMask = buttonsMask
          ..lx = lx
          ..ly = ly
          ..rx = rx
          ..ry = ry
          ..lt = lt
          ..rt = rt);
      _sendProtobuf(envelope);
    } else {
      _sendJson(
        {
          'type': 'gamepadXInput',
          'buttonsMask': buttonsMask,
          'lx': lx,
          'ly': ly,
          'rx': rx,
          'ry': ry,
          'lt': lt,
          'rt': rt,
          'index': index,
        },
      );
    }
  }

  void sendGamepadConnection({
    required int index,
    required bool connected,
  }) {
    if (_useProtobuf) {
      final envelope = pb.Envelope()
        ..gamepadConnection = (pb.GamepadConnection()
          ..index = index
          ..connected = connected);
      _sendProtobuf(envelope, reliable: true);
    } else {
      _sendJson(
        {
          'type': 'gamepadConnection',
          'index': index,
          'connected': connected,
        },
        reliable: true,
      );
    }
  }

  void sendKeyboard({
    required String key,
    required bool down,
    int code = 0,
    Map<String, bool>? meta,
  }) {
    if (_useProtobuf) {
      final envelope = pb.Envelope()
        ..keyboard = (pb.Keyboard()
          ..key = key
          ..code = code
          ..down = down
          ..mods = _modsMask(meta));
      _sendProtobuf(envelope, reliable: true);
    } else {
      _sendJson(
        {
          'type': 'keyboard',
          'key': key,
          'code': code,
          'down': down,
          'mods': _modsMask(meta),
        },
        reliable: true,
      );
    }
  }

  // System commands (RealDesk-specific) always use JSON (not in protobuf schema)
  void sendSystemCommand(String action) {
    _sendJson(
      {
        'type': 'system',
        'action': action,
      },
      reliable: true,
    );
  }

  void toggleMouseMode() => sendSystemCommand('toggle-abs-rel');
  void requestClipboardSync() => sendSystemCommand('clipboard-sync');
  void requestScreenshot() => sendSystemCommand('screenshot');
}
