# 光标替换调试指南

## 问题描述
光标没有被替换成远程光标图像，仍然显示 macOS 默认光标。

## 调试步骤

### 1. 检查是否收到光标图像消息
运行应用后，查看日志中是否有以下信息：
```
收到光标图像消息: width=XX, height=XX, dataLength=XXXX
```

**如果没有收到此消息**：
- 问题在被控端，被控端没有发送光标图像数据
- 检查被控端是否实现了光标捕获功能
- 检查 DataChannel 连接是否正常

**如果收到此消息**：继续下一步

### 2. 检查光标图像是否成功解码
查看日志中是否有：
```
光标图像已设置: WxH, hotspot=(X,Y), visible=true
```

**如果有警告信息**：
- `收到的 cursorImage 消息字段缺失或非法` - 检查消息格式
- `收到不支持的 cursorImage 格式` - 仅支持 BGRA 格式
- `cursorImage 数据 base64 解码失败` - 数据损坏
- `cursorImage 数据长度不足` - 数据不完整
- `cursorImage 像素解码失败` - 像素数据格式错误

**如果成功设置**：继续下一步

### 3. 检查指针是否在视频区域内
移动鼠标进入视频区域，查看日志：
```
指针进入/离开视频区域: inside=true, 光标状态: image=true, visible=true, shouldShow=true, shouldHide=true
```

**关键状态说明**：
- `inside=true` - 指针在视频内
- `image=true` - 有远程光标图像
- `visible=true` - 远程光标可见（非FPS模式）
- `shouldShow=true` - 应该显示远程光标图像
- `shouldHide=true` - 应该隐藏本地系统光标

**如果 `shouldShow=false`**：
- 检查 `inside` 是否为 true（鼠标是否真的在视频内）
- 检查 `image` 是否为 true（是否收到光标图像）
- 检查 `visible` 是否为 true（是否FPS模式）

### 4. 检查光标位置更新
移动鼠标，查看日志：
```
远程光标位置更新: (X.X, Y.Y)
```

**如果看到位置更新**：
- 光标图像应该跟随鼠标移动
- 检查UI层是否正确渲染了 RawImage widget

**如果没有位置更新**：
- 可能移动距离太小（小于0.5像素）
- 或者 `shouldShow=false`

## 当前实现说明

### 光标显示逻辑
```dart
// 判断是否显示远程光标图像
bool get _shouldShowRemoteCursor =>
    _remoteCursorImage != null &&      // 有光标图像数据
    _remoteCursorVisible &&            // 光标可见（非FPS模式）
    _isPointerInsideVideo;             // 指针在视频内

// 判断是否隐藏本地系统光标
bool get _shouldHideLocalCursor =>
    _remoteCursorImage != null &&      // 有光标图像数据
    _isPointerInsideVideo;             // 指针在视频内
```

### UI 渲染结构
```dart
MouseRegion(
  cursor: _shouldHideLocalCursor        // 隐藏系统光标
      ? SystemMouseCursors.none
      : MouseCursor.defer,
  child: Stack(
    children: [
      // 视频渲染
      RemoteMediaRenderer(...),
      
      // 远程光标图像（使用 Positioned 定位）
      if (_shouldShowRemoteCursor && _remoteCursorImage != null)
        Positioned(
          left: _pointerPosition.dx - _cursorHotspot.dx,
          top: _pointerPosition.dy - _cursorHotspot.dy,
          child: RawImage(
            image: _remoteCursorImage,
            filterQuality: FilterQuality.high,
          ),
        ),
    ],
  ),
)
```

## 常见问题排查

### 问题1：看到光标消息但光标不显示
**可能原因**：
1. `_isPointerInsideVideo = false` - 鼠标不在视频区域
2. `_remoteCursorVisible = false` - FPS模式，光标被隐藏
3. UI层 `Stack` 的 `clipBehavior` 设置错误

**解决方法**：
- 确保鼠标在视频窗口内
- 检查 `clipBehavior: Clip.none`（已设置）
- 查看完整日志确认所有状态

### 问题2：系统光标没有隐藏
**可能原因**：
1. `MouseRegion.cursor` 设置不正确
2. 有其他Widget覆盖了光标设置

**解决方法**：
- 检查日志中的 `shouldHide` 状态
- 确认 `cursor: SystemMouseCursors.none` 生效

### 问题3：光标图像位置不对
**可能原因**：
1. `hotspot` 偏移计算错误
2. 视频宽高比映射问题

**解决方法**：
- 检查 `_cursorHotspot` 值
- 检查 `_clampPointerToVideo` 计算逻辑

## 手动测试方法

### 测试1：模拟光标消息
在 DataChannel 消息处理中添加测试代码：
```dart
// 发送测试光标图像（32x32 白色箭头）
final testCursorData = {
  'type': 'cursorImage',
  'w': 32,
  'h': 32,
  'fmt': 'BGRA',
  'data': base64Encode(Uint8List(32 * 32 * 4)..fillRange(0, 32 * 32 * 4, 255)),
  'hotspotX': 0,
  'hotspotY': 0,
  'visible': true,
};
_handleCursorImageMessage(testCursorData);
```

### 测试2：强制显示状态
临时修改 getter 强制显示：
```dart
bool get _shouldShowRemoteCursor => true;  // 强制显示
bool get _shouldHideLocalCursor => true;   // 强制隐藏系统光标
```

## 下一步行动

1. **运行应用并查看日志**
   ```bash
   flutter run -d macos
   ```

2. **移动鼠标到视频区域**
   - 观察控制台日志输出
   - 记录所有相关状态信息

3. **根据日志判断问题**
   - 如果没收到光标消息 → 检查被控端
   - 如果收到但不显示 → 检查状态条件
   - 如果状态正确但不显示 → 检查UI渲染

4. **提供调试信息**
   - 完整的日志输出
   - `_shouldShowRemoteCursor` 的值
   - `_shouldHideLocalCursor` 的值
   - `_remoteCursorImage` 是否为 null
   - `_remoteCursorVisible` 的值
   - `_isPointerInsideVideo` 的值

## 相关文件

- `lib/ui/pages/session_page.dart` - 主要实现
- `test/remote_cursor_replacement_test.dart` - 功能测试
- `test/cursor_visibility_test.dart` - 可见性逻辑测试
