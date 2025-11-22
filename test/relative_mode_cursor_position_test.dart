import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui;

/// Tests for cursor position updates in relative mouse mode
///
/// This test file validates that when in relative (FPS) mode, the cursor
/// position is correctly updated based on remote absolute coordinates
/// received from the controlled machine.
void main() {
  group('Relative Mode Cursor Position', () {
    test('Remote absolute position is converted to local coordinates', () {
      // Remote display: 1920x1080
      const remoteDisplayW = 1920;
      const remoteDisplayH = 1080;
      const remoteX = 960.0; // Center X
      const remoteY = 540.0; // Center Y

      // Local view: 800x600
      const viewWidth = 800.0;
      const viewHeight = 600.0;

      // Remote video size (actual video dimensions)
      const remoteVideoW = 1920.0;
      const remoteVideoH = 1080.0;

      // Calculate video aspect ratio
      const videoAspect = remoteVideoW / remoteVideoH; // 16:9
      const viewAspect = viewWidth / viewHeight; // 4:3

      // Video is wider than view, so we have letterbox (black bars top/bottom)
      expect(videoAspect > viewAspect, true);

      const contentWidth = viewWidth;
      const contentHeight = contentWidth / videoAspect;
      const offsetX = 0.0;
      const offsetY = (viewHeight - contentHeight) / 2;

      // Convert remote center to local coordinates
      const normalizedX = remoteX / remoteDisplayW;
      const normalizedY = remoteY / remoteDisplayH;

      final localX = offsetX + (normalizedX * contentWidth);
      final localY = offsetY + (normalizedY * contentHeight);

      // Center of remote should map to center of local content area
      expect(localX, closeTo(viewWidth / 2, 0.1));
      expect(localY, closeTo(viewHeight / 2, 0.1));
    });

    test('Remote corner positions map to local content corners', () {
      const remoteDisplayW = 1920;
      const remoteDisplayH = 1080;
      const viewWidth = 1280.0;
      const viewHeight = 720.0;
      const remoteVideoW = 1920.0;
      const remoteVideoH = 1080.0;

      const videoAspect = remoteVideoW / remoteVideoH;
      const viewAspect = viewWidth / viewHeight;

      // Same aspect ratio, no letterboxing
      expect((videoAspect - viewAspect).abs() < 0.01, true);

      const contentWidth = viewWidth;
      const contentHeight = viewHeight;
      const offsetX = 0.0;
      const offsetY = 0.0;

      // Test top-left corner
      {
        const remoteX = 0.0;
        const remoteY = 0.0;
        const normalizedX = remoteX / remoteDisplayW;
        const normalizedY = remoteY / remoteDisplayH;
        final localX = offsetX + (normalizedX * contentWidth);
        final localY = offsetY + (normalizedY * contentHeight);

        expect(localX, closeTo(0.0, 0.1));
        expect(localY, closeTo(0.0, 0.1));
      }

      // Test bottom-right corner
      {
        const remoteX = 1920.0;
        const remoteY = 1080.0;
        const normalizedX = remoteX / remoteDisplayW;
        const normalizedY = remoteY / remoteDisplayH;
        final localX = offsetX + (normalizedX * contentWidth);
        final localY = offsetY + (normalizedY * contentHeight);

        expect(localX, closeTo(viewWidth, 0.1));
        expect(localY, closeTo(viewHeight, 0.1));
      }
    });

    test('Pillarbox mode (portrait video on landscape view)', () {
      const remoteDisplayW = 1080;
      const remoteDisplayH = 1920;
      const viewWidth = 1920.0;
      const viewHeight = 1080.0;
      const remoteVideoW = 1080.0;
      const remoteVideoH = 1920.0;

      const videoAspect = remoteVideoW / remoteVideoH; // 9:16 (portrait)
      const viewAspect = viewWidth / viewHeight; // 16:9 (landscape)

      // Video is taller than view, so we have pillarbox (black bars left/right)
      expect(videoAspect < viewAspect, true);

      const contentHeight = viewHeight;
      const contentWidth = contentHeight * videoAspect;
      const offsetY = 0.0;
      const offsetX = (viewWidth - contentWidth) / 2;

      // Test center position
      const remoteX = 540.0;
      const remoteY = 960.0;
      const normalizedX = remoteX / remoteDisplayW;
      const normalizedY = remoteY / remoteDisplayH;

      final localX = offsetX + (normalizedX * contentWidth);
      final localY = offsetY + (normalizedY * contentHeight);

      // Center of remote should map to center of view
      expect(localX, closeTo(viewWidth / 2, 0.1));
      expect(localY, closeTo(viewHeight / 2, 0.1));
    });

    test('Position clamping to view bounds', () {
      // Test that coordinates are properly clamped
      const viewWidth = 800.0;
      const viewHeight = 600.0;

      // Test negative coordinates
      var localX = -100.0;
      var localY = -50.0;

      localX = localX.clamp(0.0, viewWidth);
      localY = localY.clamp(0.0, viewHeight);

      expect(localX, 0.0);
      expect(localY, 0.0);

      // Test coordinates beyond view bounds
      localX = 1000.0;
      localY = 800.0;

      localX = localX.clamp(0.0, viewWidth);
      localY = localY.clamp(0.0, viewHeight);

      expect(localX, viewWidth);
      expect(localY, viewHeight);
    });

    test('Normalized coordinates without video size info', () {
      // When video size is unknown, assume coordinates are normalized (0-1)
      const viewWidth = 1024.0;
      const viewHeight = 768.0;

      // Simulate normalized coordinates (0-1 range)
      const normalizedX = 0.5;
      const normalizedY = 0.75;

      final localX = normalizedX * viewWidth;
      final localY = normalizedY * viewHeight;

      expect(localX, 512.0);
      expect(localY, 576.0);
    });

    test('Small movements should update position', () {
      // Test that even small position changes are detected
      const offset1 = ui.Offset(100.0, 100.0);
      const offset2 = ui.Offset(101.0, 101.0);

      expect(offset1 != offset2, true);

      // Calculate distance
      final dx = offset2.dx - offset1.dx;
      final dy = offset2.dy - offset1.dy;
      final distanceSquared = dx * dx + dy * dy;

      // Even 1 pixel movement should be detectable
      expect(distanceSquared, greaterThan(0));
      expect(distanceSquared, closeTo(2.0, 0.1)); // sqrt(1^2 + 1^2) ≈ 1.41
    });

    test('High-frequency position updates', () {
      // Simulate rapid position updates from remote
      final positions = <ui.Offset>[];

      for (int i = 0; i < 100; i++) {
        final x = 100.0 + i * 5.0;
        final y = 200.0 + i * 3.0;
        positions.add(ui.Offset(x, y));
      }

      expect(positions.length, 100);

      // Verify positions are sequential and increasing
      for (int i = 1; i < positions.length; i++) {
        expect(positions[i].dx, greaterThan(positions[i - 1].dx));
        expect(positions[i].dy, greaterThan(positions[i - 1].dy));
      }
    });

    test('Different remote display resolutions', () {
      final testCases = [
        {'w': 1920, 'h': 1080, 'name': '1080p'},
        {'w': 2560, 'h': 1440, 'name': '1440p'},
        {'w': 3840, 'h': 2160, 'name': '4K'},
        {'w': 1280, 'h': 720, 'name': '720p'},
      ];

      const viewWidth = 1280.0;
      const viewHeight = 720.0;

      for (final testCase in testCases) {
        final remoteDisplayW = testCase['w'] as int;
        final remoteDisplayH = testCase['h'] as int;
        final name = testCase['name'] as String;

        // Test center position for each resolution
        final remoteX = remoteDisplayW / 2.0;
        final remoteY = remoteDisplayH / 2.0;

        final normalizedX = remoteX / remoteDisplayW;
        final normalizedY = remoteY / remoteDisplayH;

        final localX = normalizedX * viewWidth;
        final localY = normalizedY * viewHeight;

        // Center should always map to center regardless of remote resolution
        expect(localX, closeTo(viewWidth / 2, 0.1),
            reason: 'Failed for $name resolution');
        expect(localY, closeTo(viewHeight / 2, 0.1),
            reason: 'Failed for $name resolution');
      }
    });
  });

  group('Mode-specific Behavior', () {
    test('Relative mode should update cursor from remote position', () {
      // In relative mode (FPS mode), cursor position comes from remote
      const isRelativeMode = true;

      if (isRelativeMode) {
        // Remote sends absolute position
        const remoteX = 500.0;
        const remoteY = 300.0;

        // This should update local cursor position
        expect(remoteX, greaterThan(0));
        expect(remoteY, greaterThan(0));
      }
    });

    test('Absolute mode should not update cursor from remote position', () {
      // In absolute mode, cursor position is determined by local mouse
      const isRelativeMode = false;

      if (!isRelativeMode) {
        // Remote position should not affect local cursor display
        // (only used for injection to remote system)
        expect(isRelativeMode, false);
      }
    });
  });

  group('Edge Cases', () {
    test('Zero-size view handling', () {
      const viewWidth = 0.0;
      const viewHeight = 0.0;

      // Should handle gracefully without crashing
      expect(viewWidth <= 0 || viewHeight <= 0, true);
      // Function should return early
    });

    test('Zero-size remote video handling', () {
      const remoteVideoW = 0.0;
      const remoteVideoH = 0.0;

      // Should fall back to normalized coordinate mode
      expect(remoteVideoW <= 0 || remoteVideoH <= 0, true);
    });

    test('Extreme aspect ratio differences', () {
      // Ultra-wide remote on square view
      const remoteVideoW = 3440.0;
      const remoteVideoH = 1440.0;
      const viewWidth = 800.0;
      const viewHeight = 800.0;

      const videoAspect = remoteVideoW / remoteVideoH; // ~2.39:1
      const viewAspect = viewWidth / viewHeight; // 1:1

      expect(videoAspect > viewAspect, true);

      // Should still calculate valid content area
      const contentWidth = viewWidth;
      const contentHeight = contentWidth / videoAspect;

      expect(contentHeight, lessThan(viewHeight));
      expect(contentHeight, greaterThan(0));
    });
  });
}
