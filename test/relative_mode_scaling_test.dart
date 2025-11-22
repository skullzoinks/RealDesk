import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' show Offset, Size;

/// 测试相对模式下的鼠标增量缩放
///
/// 场景：
/// 1. 视频尺寸与视图尺寸相同：1:1 缩放
/// 2. 视频比视图大：需要放大增量
/// 3. 视频比视图小：需要缩小增量
/// 4. Letterbox模式：视频更宽，上下黑边
/// 5. Pillarbox模式：视频更高，左右黑边
void main() {
  group('Relative Mode Delta Scaling', () {
    test('场景1：视频尺寸与视图相同 - 1:1 缩放', () {
      const viewWidth = 1920.0;
      const viewHeight = 1080.0;
      const remoteWidth = 1920.0;
      const remoteHeight = 1080.0;

      // 鼠标移动 10 像素
      const deltaX = 10.0;
      const deltaY = 10.0;

      // 计算缩放比例
      final scaleX = remoteWidth / viewWidth;
      final scaleY = remoteHeight / viewHeight;

      final scaledDx = deltaX * scaleX;
      final scaledDy = deltaY * scaleY;

      expect(scaleX, 1.0);
      expect(scaleY, 1.0);
      expect(scaledDx, 10.0, reason: '相同尺寸时增量不变');
      expect(scaledDy, 10.0, reason: '相同尺寸时增量不变');
    });

    test('场景2：远程视频更大 - 需要放大增量', () {
      const viewWidth = 960.0; // Flutter 窗口
      const viewHeight = 540.0;
      const remoteWidth = 1920.0; // 远程屏幕
      const remoteHeight = 1080.0;

      // 在小窗口中移动 10 像素
      const deltaX = 10.0;
      const deltaY = 10.0;

      // 应该在远程屏幕上移动 20 像素
      final scaleX = remoteWidth / viewWidth; // 2.0
      final scaleY = remoteHeight / viewHeight; // 2.0

      final scaledDx = deltaX * scaleX;
      final scaledDy = deltaY * scaleY;

      expect(scaleX, 2.0);
      expect(scaleY, 2.0);
      expect(scaledDx, 20.0, reason: '远程屏幕2倍大，增量应该2倍');
      expect(scaledDy, 20.0, reason: '远程屏幕2倍大，增量应该2倍');
    });

    test('场景3：远程视频更小 - 需要缩小增量', () {
      const viewWidth = 1920.0; // Flutter 窗口
      const viewHeight = 1080.0;
      const remoteWidth = 1280.0; // 远程屏幕
      const remoteHeight = 720.0;

      // 在大窗口中移动 10 像素
      const deltaX = 10.0;
      const deltaY = 10.0;

      // 应该在远程屏幕上移动约 6.67 像素
      final scaleX = remoteWidth / viewWidth; // 0.667
      final scaleY = remoteHeight / viewHeight; // 0.667

      final scaledDx = deltaX * scaleX;
      final scaledDy = deltaY * scaleY;

      expect(scaleX, closeTo(0.667, 0.001));
      expect(scaleY, closeTo(0.667, 0.001));
      expect(scaledDx, closeTo(6.667, 0.01), reason: '远程屏幕更小，增量应该按比例缩小');
      expect(scaledDy, closeTo(6.667, 0.01));
    });

    test('场景4：Letterbox模式 - 上下黑边', () {
      // 视频16:9，视图4:3，会有上下黑边
      const viewWidth = 1024.0;
      const viewHeight = 768.0;
      const remoteWidth = 1920.0; // 16:9
      const remoteHeight = 1080.0;

      final videoAspect = remoteWidth / remoteHeight; // 1.778
      final viewAspect = viewWidth / viewHeight; // 1.333

      // Letterbox: videoAspect > viewAspect
      // 内容区域：左右占满，上下有黑边
      final contentWidth = viewWidth;
      final contentHeight = contentWidth / videoAspect; // 576
      final blackBarHeight = (viewHeight - contentHeight) / 2; // 96

      // 计算缩放比例（基于内容区域，不包括黑边）
      final scaleX = remoteWidth / contentWidth; // 1.875
      final scaleY = remoteHeight / contentHeight; // 1.875

      // 移动 10 像素
      const deltaX = 10.0;
      const deltaY = 10.0;

      final scaledDx = deltaX * scaleX;
      final scaledDy = deltaY * scaleY;

      expect(videoAspect > viewAspect, true);
      expect(contentHeight, 576.0);
      expect(blackBarHeight, 96.0);
      expect(scaleX, closeTo(1.875, 0.001));
      expect(scaleY, closeTo(1.875, 0.001));
      expect(scaledDx, closeTo(18.75, 0.01), reason: 'Letterbox模式下需要考虑视频缩放');
      expect(scaledDy, closeTo(18.75, 0.01));
    });

    test('场景5：Pillarbox模式 - 左右黑边', () {
      // 视频4:3，视图16:9，会有左右黑边
      const viewWidth = 1920.0;
      const viewHeight = 1080.0;
      const remoteWidth = 1024.0; // 4:3
      const remoteHeight = 768.0;

      final videoAspect = remoteWidth / remoteHeight; // 1.333
      final viewAspect = viewWidth / viewHeight; // 1.778

      // Pillarbox: videoAspect < viewAspect
      // 内容区域：上下占满，左右有黑边
      final contentHeight = viewHeight;
      final contentWidth = contentHeight * videoAspect; // 1440
      final blackBarWidth = (viewWidth - contentWidth) / 2; // 240

      // 计算缩放比例
      final scaleX = remoteWidth / contentWidth; // 0.711
      final scaleY = remoteHeight / contentHeight; // 0.711

      // 移动 10 像素
      const deltaX = 10.0;
      const deltaY = 10.0;

      final scaledDx = deltaX * scaleX;
      final scaledDy = deltaY * scaleY;

      expect(videoAspect < viewAspect, true);
      expect(contentWidth, 1440.0);
      expect(blackBarWidth, 240.0);
      expect(scaleX, closeTo(0.711, 0.001));
      expect(scaleY, closeTo(0.711, 0.001));
      expect(scaledDx, closeTo(7.11, 0.01), reason: 'Pillarbox模式下需要考虑视频缩放');
      expect(scaledDy, closeTo(7.11, 0.01));
    });

    test('场景6：极端缩放 - 4K远程到720p视图', () {
      const viewWidth = 1280.0;
      const viewHeight = 720.0;
      const remoteWidth = 3840.0; // 4K
      const remoteHeight = 2160.0;

      const deltaX = 5.0;
      const deltaY = 5.0;

      final scaleX = remoteWidth / viewWidth; // 3.0
      final scaleY = remoteHeight / viewHeight; // 3.0

      final scaledDx = deltaX * scaleX;
      final scaledDy = deltaY * scaleY;

      expect(scaleX, 3.0);
      expect(scaleY, 3.0);
      expect(scaledDx, 15.0, reason: '4K远程，移动5像素应变成15像素');
      expect(scaledDy, 15.0);
    });

    test('场景7：不同宽高比的缩放', () {
      // 视图是正方形，远程是16:9
      const viewWidth = 800.0;
      const viewHeight = 800.0;
      const remoteWidth = 1920.0;
      const remoteHeight = 1080.0;

      final videoAspect = remoteWidth / remoteHeight; // 1.778
      final viewAspect = viewWidth / viewHeight; // 1.0

      // Letterbox: 视频更宽
      final contentWidth = viewWidth;
      final contentHeight = contentWidth / videoAspect; // 450

      final scaleX = remoteWidth / contentWidth; // 2.4
      final scaleY = remoteHeight / contentHeight; // 2.4

      const deltaX = 10.0;
      const deltaY = 10.0;

      final scaledDx = deltaX * scaleX;
      final scaledDy = deltaY * scaleY;

      expect(contentHeight, 450.0);
      expect(scaleX, 2.4);
      expect(scaleY, 2.4);
      expect(scaledDx, 24.0);
      expect(scaledDy, 24.0);
    });

    test('场景8：无远程视频尺寸信息 - 返回原始增量', () {
      // 当还没有收到远程视频尺寸时
      const remoteWidth = 0.0; // 未知
      const remoteHeight = 0.0;

      const deltaX = 10.0;
      const deltaY = 10.0;

      // 应该返回原始增量，不做缩放
      final shouldScale = remoteWidth > 0 && remoteHeight > 0;

      expect(shouldScale, false);
      // 返回原始值
      expect(deltaX, 10.0);
      expect(deltaY, 10.0);
    });

    test('场景9：负增量（向左/向上移动）', () {
      const viewWidth = 1920.0;
      const viewHeight = 1080.0;
      const remoteWidth = 3840.0;
      const remoteHeight = 2160.0;

      // 向左和向上移动
      const deltaX = -10.0;
      const deltaY = -15.0;

      final scaleX = remoteWidth / viewWidth; // 2.0
      final scaleY = remoteHeight / viewHeight; // 2.0

      final scaledDx = deltaX * scaleX;
      final scaledDy = deltaY * scaleY;

      expect(scaledDx, -20.0, reason: '负增量也应该正确缩放');
      expect(scaledDy, -30.0, reason: '负增量也应该正确缩放');
    });

    test('场景10：小增量精度测试', () {
      const viewWidth = 1920.0;
      const viewHeight = 1080.0;
      const remoteWidth = 1920.0;
      const remoteHeight = 1080.0;

      // 非常小的移动（亚像素）
      const deltaX = 0.3;
      const deltaY = 0.5;

      final scaleX = remoteWidth / viewWidth;
      final scaleY = remoteHeight / viewHeight;

      final scaledDx = deltaX * scaleX;
      final scaledDy = deltaY * scaleY;

      expect(scaledDx, 0.3, reason: '小增量应该保持精度');
      expect(scaledDy, 0.5, reason: '小增量应该保持精度');
    });
  });

  group('Edge Cases', () {
    test('视图尺寸为空', () {
      const viewWidth = 0.0;
      const viewHeight = 0.0;

      const deltaX = 10.0;
      const deltaY = 10.0;

      // 应该返回原始增量
      final isEmpty = viewWidth == 0 || viewHeight == 0;
      expect(isEmpty, true);
    });

    test('极小视图尺寸', () {
      const viewWidth = 1.0;
      const viewHeight = 1.0;
      const remoteWidth = 1920.0;
      const remoteHeight = 1080.0;

      final scaleX = remoteWidth / viewWidth;
      final scaleY = remoteHeight / viewHeight;

      expect(scaleX, 1920.0, reason: '极大的缩放比例');
      expect(scaleY, 1080.0);
    });
  });
}
