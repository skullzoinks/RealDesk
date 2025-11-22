import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:realdesk/input/schema/remote_input.pb.dart' as pb;

void main() {
  group('Protobuf Cursor Image Tests', () {
    test('应该能够创建并序列化 CursorImage', () {
      // 创建一个 2x2 的 RGBA 光标图像
      final width = 2;
      final height = 2;
      final rgba = Uint8List.fromList([
        255, 0, 0, 255, // 红色像素
        0, 255, 0, 255, // 绿色像素
        0, 0, 255, 255, // 蓝色像素
        255, 255, 255, 255, // 白色像素
      ]);

      final cursor = pb.CursorImage()
        ..w = width
        ..h = height
        ..hotspotX = 1
        ..hotspotY = 1
        ..visible = true
        ..rgba = rgba;

      expect(cursor.w, equals(2));
      expect(cursor.h, equals(2));
      expect(cursor.hotspotX, equals(1));
      expect(cursor.hotspotY, equals(1));
      expect(cursor.visible, equals(true));
      expect(cursor.rgba.length, equals(16));
    });

    test('应该能够将 CursorImage 包装在 Envelope 中', () {
      final cursor = pb.CursorImage()
        ..w = 16
        ..h = 16
        ..hotspotX = 8
        ..hotspotY = 8
        ..visible = true
        ..rgba = Uint8List(16 * 16 * 4); // 空白图像

      final envelope = pb.Envelope()..cursorImage = cursor;

      expect(envelope.whichPayload(), equals(pb.Envelope_Payload.cursorImage));
      expect(envelope.cursorImage.w, equals(16));
      expect(envelope.cursorImage.h, equals(16));
    });

    test('应该能够序列化和反序列化 Envelope', () {
      final cursor = pb.CursorImage()
        ..w = 32
        ..h = 32
        ..hotspotX = 0
        ..hotspotY = 0
        ..visible = false
        ..rgba = Uint8List(32 * 32 * 4);

      final envelope = pb.Envelope()..cursorImage = cursor;

      // 序列化为二进制
      final bytes = envelope.writeToBuffer();
      expect(bytes.isNotEmpty, isTrue);

      // 反序列化
      final decoded = pb.Envelope.fromBuffer(bytes);
      expect(decoded.whichPayload(), equals(pb.Envelope_Payload.cursorImage));
      expect(decoded.cursorImage.w, equals(32));
      expect(decoded.cursorImage.h, equals(32));
      expect(decoded.cursorImage.hotspotX, equals(0));
      expect(decoded.cursorImage.hotspotY, equals(0));
      expect(decoded.cursorImage.visible, equals(false));
      expect(decoded.cursorImage.rgba.length, equals(32 * 32 * 4));
    });

    test('RGBA 到 BGRA 转换应该正确', () {
      // 测试 RGBA 到 BGRA 的转换逻辑
      final rgba = Uint8List.fromList([
        255, 0, 0, 255, // R=255, G=0, B=0, A=255
        0, 255, 0, 255, // R=0, G=255, B=0, A=255
        0, 0, 255, 255, // R=0, G=0, B=255, A=255
      ]);

      final bgra = Uint8List(rgba.length);
      for (int i = 0; i < rgba.length; i += 4) {
        bgra[i] = rgba[i + 2]; // B
        bgra[i + 1] = rgba[i + 1]; // G
        bgra[i + 2] = rgba[i]; // R
        bgra[i + 3] = rgba[i + 3]; // A
      }

      // 验证转换结果
      expect(bgra[0], equals(0)); // B=0
      expect(bgra[1], equals(0)); // G=0
      expect(bgra[2], equals(255)); // R=255
      expect(bgra[3], equals(255)); // A=255

      expect(bgra[4], equals(0)); // B=0
      expect(bgra[5], equals(255)); // G=255
      expect(bgra[6], equals(0)); // R=0
      expect(bgra[7], equals(255)); // A=255

      expect(bgra[8], equals(255)); // B=255
      expect(bgra[9], equals(0)); // G=0
      expect(bgra[10], equals(0)); // R=0
      expect(bgra[11], equals(255)); // A=255
    });

    test('应该能够处理其他 Protobuf 消息类型', () {
      // 测试 MouseAbs
      final mouseAbs = pb.MouseAbs()
        ..x = 100.0
        ..y = 200.0
        ..displayW = 1920
        ..displayH = 1080
        ..btns = (pb.Buttons()..bits = 1); // 左键

      final envelope1 = pb.Envelope()..mouseAbs = mouseAbs;
      expect(envelope1.whichPayload(), equals(pb.Envelope_Payload.mouseAbs));

      // 测试 Keyboard
      final keyboard = pb.Keyboard()
        ..key = 'a'
        ..code = 65
        ..down = true
        ..mods = 1; // Ctrl

      final envelope2 = pb.Envelope()..keyboard = keyboard;
      expect(envelope2.whichPayload(), equals(pb.Envelope_Payload.keyboard));

      // 测试 GamepadFeedback
      final feedback = pb.GamepadFeedback()
        ..index = 0
        ..largeMotor = 0.5
        ..smallMotor = 0.3
        ..ledCode = 1;

      final envelope3 = pb.Envelope()..gamepadFeedback = feedback;
      expect(envelope3.whichPayload(),
          equals(pb.Envelope_Payload.gamepadFeedback));
    });

    test('应该能够区分不同的消息类型', () {
      final envelopes = [
        pb.Envelope()..keyboard = (pb.Keyboard()..key = 'a'),
        pb.Envelope()..mouseAbs = (pb.MouseAbs()..x = 10.0),
        pb.Envelope()..mouseRel = (pb.MouseRel()..dx = 5.0),
        pb.Envelope()..mouseWheel = (pb.MouseWheel()..dy = -10.0),
        pb.Envelope()..cursorImage = (pb.CursorImage()..w = 16),
        pb.Envelope()..gamepadFeedback = (pb.GamepadFeedback()..index = 0),
      ];

      expect(envelopes[0].whichPayload(), equals(pb.Envelope_Payload.keyboard));
      expect(envelopes[1].whichPayload(), equals(pb.Envelope_Payload.mouseAbs));
      expect(envelopes[2].whichPayload(), equals(pb.Envelope_Payload.mouseRel));
      expect(
          envelopes[3].whichPayload(), equals(pb.Envelope_Payload.mouseWheel));
      expect(
          envelopes[4].whichPayload(), equals(pb.Envelope_Payload.cursorImage));
      expect(envelopes[5].whichPayload(),
          equals(pb.Envelope_Payload.gamepadFeedback));
    });
  });
}
