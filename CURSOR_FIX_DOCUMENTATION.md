# 光标显示修复说明

## 修复的问题

### 1. Flutter 本地鼠标光标未被远程光标图像替换
**原因分析**：
- 之前的实现使用 `_shouldShowRemoteCursor` 来控制是否隐藏本地光标
- `_shouldShowRemoteCursor` 要求 `remoteCursorImage != null && remoteCursorVisible && isPointerInsideVideo`
- 这个逻辑在正常模式下工作正常

**解决方案**：
- 保持 `_shouldShowRemoteCursor` 用于控制是否显示远程光标图像
- 新增 `_shouldHideLocalCursor` 用于控制是否隐藏本地光标
- `_shouldHideLocalCursor = remoteCursorImage != null && isPointerInsideVideo`
- 这样只要有远程光标数据且指针在视频内，就隐藏本地光标

### 2. FPS 射击游戏模式下，远程光标无值时需要隐藏光标
**原因分析**：
- FPS 游戏中，服务器会发送 `visible: false` 的光标消息
- 此时应该隐藏所有光标（包括本地和远程），给用户无光标的游戏体验
- 之前的逻辑在 `visible=false` 时会显示默认的 Flutter 光标

**解决方案**：
- 使用新的 `_shouldHideLocalCursor` 逻辑
- 当 `remoteCursorImage != null && visible=false && isPointerInsideVideo` 时：
  - `_shouldShowRemoteCursor = false`（不显示远程光标图像）
  - `_shouldHideLocalCursor = true`（隐藏本地光标）
  - 结果：屏幕上无任何光标显示

## 代码更改

### session_page.dart

```dart
// 添加新的getter
bool get _shouldHideLocalCursor =>
    _remoteCursorImage != null && _isPointerInsideVideo;

// 使用新的逻辑控制光标
cursor: _shouldHideLocalCursor
    ? SystemMouseCursors.none
    : MouseCursor.defer,
```

## 光标显示逻辑表

| 场景              | remoteCursorImage | remoteCursorVisible | isPointerInside | 本地光标 | 远程光标图像 |
| ----------------- | ----------------- | ------------------- | --------------- | -------- | ------------ |
| 1. 无远程光标数据 | null              | -                   | true            | 显示     | 不显示       |
| 2. 正常模式       | 有值              | true                | true            | 隐藏     | 显示         |
| 3. FPS模式        | 有值              | false               | true            | 隐藏     | 不显示       |
| 4. 指针在外       | 有值              | true                | false           | 显示     | 不显示       |

## 测试验证

创建了 `test/cursor_visibility_test.dart` 测试文件，验证了以下场景：
1. ✅ 无远程光标数据时显示默认光标
2. ✅ 正常模式下隐藏本地光标，显示远程光标
3. ✅ FPS模式下隐藏本地光标，不显示远程光标
4. ✅ 指针在视频外时显示默认光标
5. ✅ 光标hotspot定位计算正确

所有测试均通过。

## 构建验证

```bash
flutter build macos --debug
# ✓ Built build/macos/Build/Products/Debug/realdesk.app
```

构建成功，无编译错误。

## 使用说明

### 正常桌面应用模式
1. 当远程端发送光标图像时，本地 Flutter 光标会自动隐藏
2. 远程光标图像会显示在正确的位置（考虑hotspot偏移）
3. 移动鼠标时，远程光标图像会跟随移动

### FPS游戏模式
1. 当远程端发送 `visible: false` 的光标消息时
2. 本地 Flutter 光标和远程光标图像都会隐藏
3. 屏幕上不显示任何光标，适合第一人称射击游戏

### 退出视频区域
1. 当鼠标移出视频显示区域时
2. 自动恢复显示默认的 Flutter 光标
3. 远程光标图像自动隐藏

## 技术细节

### 光标位置计算
```dart
Positioned(
  left: _pointerPosition.dx - _cursorHotspot.dx,
  top: _pointerPosition.dy - _cursorHotspot.dy,
  child: RawImage(
    image: _remoteCursorImage,
    filterQuality: FilterQuality.high,
  ),
)
```

- `_pointerPosition`：本地鼠标在视频控件中的位置
- `_cursorHotspot`：光标图像的热点偏移（通常是光标的点击位置）
- 通过减去hotspot偏移，确保光标的点击点对齐实际鼠标位置

### 光标数据接收
```dart
void _handleCursorImageMessage(Map<String, dynamic> payload) {
  final width = payload['w'];
  final height = payload['h'];
  final data = payload['data'];  // base64 BGRA8888 格式
  final hotspotX = payload['hotspotX'];
  final hotspotY = payload['hotspotY'];
  final visible = payload['visible'] != false;  // 默认为true
  
  // 解码并设置光标图像
  ui.decodeImageFromPixels(raw, width, height, ui.PixelFormat.bgra8888, ...);
}
```

## 注意事项

1. **性能优化**：光标图像更新使用版本号 `_cursorImageVersion` 避免过时的异步更新
2. **内存管理**：旧的光标图像会在设置新图像后自动释放 (`previous?.dispose()`)
3. **坐标转换**：`_clampPointerToVideo` 确保光标位置在视频内容区域内正确映射
4. **视频比例**：考虑了视频和视图的宽高比差异，正确处理letterbox/pillarbox情况

## 相关文件

- `lib/ui/pages/session_page.dart` - 主要修改文件
- `test/cursor_visibility_test.dart` - 光标可见性逻辑测试
- `lib/input/mouse_controller.dart` - 鼠标输入处理（未修改）

## 已知限制

1. 光标图像格式仅支持 BGRA8888
2. 光标图像在每次更新时需要完整传输（未实现增量更新）
3. 高刷新率光标更新可能影响性能（已通过版本号优化）
