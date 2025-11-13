# RealDesk - Flutter WebRTC 远程控制客户端

RealDesk 是一个基于 Flutter 和 flutter_webrtc 的跨平台远程控制客户端，支持低延迟的远程桌面和云游戏体验。

## 功能特性

- ✅ **跨平台支持**：Android、iOS、Windows、macOS、Linux
- ✅ **低延迟视频流**：基于 WebRTC 的实时视频/音频传输
- ✅ **实时输入控制**：支持鼠标、键盘、触摸和滚轮输入
- ✅ **双模式鼠标**：绝对坐标模式和相对移动模式
- ✅ **数据通道**：通过 RTCDataChannel 发送输入事件
- ✅ **连接统计**：实时显示 FPS、码率、RTT、丢包率等指标
- ✅ **自动重连**：网络中断时自动尝试重连
- ✅ **现代化 UI**：Material Design 3 风格界面

## 系统要求

- Flutter SDK 3.0+
- Dart 3.0+
- 对应平台的开发环境（Android Studio / Xcode / Visual Studio）

## 安装

1. **克隆项目**
```bash
cd d:/WorkSpaces/momo-project/realdesk
```

2. **安装依赖**
```bash
flutter pub get
```

3. **生成代码**（如需要）
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **运行应用**
```bash
# 运行在 Windows
flutter run -d windows

# 运行在 Android
flutter run -d android

# 运行在 iOS
flutter run -d ios
```

## 项目结构

```
lib/
├── app/                          # 应用程序配置
│   ├── main.dart                # 应用入口
│   ├── routes.dart              # 路由配置
│   └── di.dart                  # 依赖注入
├── signaling/                   # 信令客户端
│   ├── signaling_client.dart   # WebSocket 信令客户端
│   └── models/                  # 信令消息模型
│       └── signaling_messages.dart
├── webrtc/                      # WebRTC 管理
│   ├── peer_manager.dart       # PeerConnection 管理器
│   ├── data_channel.dart       # DataChannel 管理器
│   └── media_renderer.dart     # 媒体渲染器
├── input/                       # 输入控制
│   ├── mouse_controller.dart   # 鼠标控制器
│   ├── keyboard_controller.dart # 键盘控制器
│   ├── touch_controller.dart   # 触摸控制器
│   ├── gamepad_controller.dart # 游戏手柄控制器
│   └── schema/                  # 输入消息模型
│       └── input_messages.dart
├── ui/                          # 用户界面
│   ├── pages/                   # 页面
│   │   ├── connect_page.dart   # 连接页面
│   │   └── session_page.dart   # 会话页面
│   └── widgets/                 # 组件
│       ├── control_bar.dart     # 控制栏
│       └── metrics_overlay.dart # 统计叠加层
└── metrics/                     # 统计收集
    ├── stats_collector.dart    # 统计收集器
    └── qos_models.dart         # QoS 模型
```

## 使用说明

### 1. 启动远程主机

确保您的远程主机正在运行并且启用了 WebRTC 信令服务器。

例如，使用 Ayame 信令服务器：
```bash
cd d:/WorkSpaces/momo-project/ayame
./ayame
```

### 2. 配置连接

在连接页面输入以下信息：
- **信令服务器地址**：WebSocket 地址，例如 `ws://localhost:3000/signaling`
- **房间 ID**：房间标识符，例如 `test-room`
- **访问令牌**：可选，如果服务器需要身份验证

### 3. 连接到远程桌面

点击"连接"按钮，应用将：
1. 连接到信令服务器
2. 建立 WebRTC peer connection
3. 创建数据通道用于发送输入事件
4. 接收远程视频流并显示

### 4. 控制远程桌面

- **鼠标控制**：点击和拖动视频画面
- **键盘控制**：焦点在视频画面时按键
- **滚轮控制**：在视频画面上滚动
- **切换鼠标模式**：点击控制栏中的鼠标图标
- **查看统计**：点击控制栏中的分析图标

## 信令协议

### WebSocket 消息格式

**客户端 → 服务器**
```json
{
  "type": "join",
  "roomId": "test-room",
  "token": "optional-token",
  "clientCaps": {
    "inputTypes": ["mouse", "keyboard", "touch", "wheel"],
    "videoCodecs": ["h264", "vp8", "vp9"],
    "audioCodecs": ["opus"],
    "dataChannel": true,
    "version": "1.0"
  }
}
```

**服务器 → 客户端**
```json
{
  "type": "offer",
  "sdp": "..."
}
```

### DataChannel 协议

**输入事件格式**
```json
{
  "protoVersion": 1,
  "ts": 1730265600000,
  "type": "mouse",
  "payload": {
    "x": 0.5,
    "y": 0.5,
    "buttons": ["l"],
    "down": true
  }
}
```

**事件类型**
- `mouse`：鼠标事件（绝对/相对坐标）
- `key`：键盘事件
- `wheel`：滚轮事件
- `touch`：触摸事件
- `gamepad`：游戏手柄事件
- `system`：系统命令

## 性能目标

- 端到端延迟 ≤ 80ms (P50)
- 流畅的 60 FPS 播放
- 自适应码率和帧率
- 优雅处理网络重连

## 配置选项

### ICE 服务器配置

在 `peer_manager.dart` 中配置 STUN/TURN 服务器：

```dart
final peerManager = PeerManager(
  iceServers: [
    {'urls': 'stun:stun.l.google.com:19302'},
    {
      'urls': 'turn:turn.example.com:3478',
      'username': 'user',
      'credential': 'pass',
    },
  ],
);
```

### 统计收集间隔

在 `stats_collector.dart` 中配置收集间隔：

```dart
final statsCollector = StatsCollector(
  peerConnection: peerConnection,
  collectInterval: Duration(seconds: 1),
);
```

### Android MediaCodec 硬件编解码

- `lib/webrtc/sdp_utils.dart` 会重写 SDP，将 H264 排在视频 `m=` 行最前面，这样 Android 端就会优先协商出 MediaCodec 可直接处理的 H264。
- `PeerManager` 在 `createOffer` / `createAnswer` 里调用该工具，因此无论是主叫还是被叫都能触发硬编解码。
- 运行在 Android 上时，如果看到日志 `Applied Android H264 codec preference for hardware acceleration`，说明已经切到硬件路径；若日志提示 `Remote SDP does not advertise H264`，表示远端没有提供 H264，只能退回软编解码。
- 使用 `flutter logs` 或 `adb logcat | grep PeerManager` 可以确认当前设备是否已经启用硬编解码。

### 视频编码优先级

- 在“设置”页新增“优先视频编码器”下拉选择，可在 VP8、VP9、AV1、H264、H265 之间切换。
- `PeerManager` 会读取该偏好，并结合 Android 默认的 MediaCodec 顺序（H265→H264→VP9→VP8→AV1）重写 SDP，尽量优先协商硬件可解码的格式。
- 如果偏好的编码器不在远端 SDP 中，日志会提示 `Preferred codecs [...] not found`，以便快速诊断。

### Android 外设（蓝牙 / OTG 键鼠 / 手柄）

- `android/app/src/main/AndroidManifest.xml` 中声明了蓝牙、USB Host、Gamepad 等可选硬件特性，并请求了 `BLUETOOTH_ADMIN`/`BLUETOOTH_CONNECT` 等权限，确保可以访问外接设备。
- 新增 `HardwareInputPlugin`（Kotlin）通过事件通道 `realdesk/hardware_gamepad` 将 Android 原生的手柄轴/按键数据推送给 Flutter。
- `GamepadController` 订阅该事件流后，立即把硬件状态转换成 `gamepad` DataChannel 消息，远端主机可获得 60Hz 以上的轴与按钮更新。
- Flutter `Listener` + `Focus` 组合继续负责键盘、鼠标（含蓝牙/OTG）事件，确保物理键鼠操作可以零配置直达远端。

## 故障排除

### 无法连接到信令服务器

1. 检查信令服务器地址是否正确
2. 确认信令服务器正在运行
3. 检查防火墙设置

### 无视频流

1. 检查 WebRTC 连接状态
2. 查看统计信息中的码率和丢包率
3. 确认远程主机正在发送视频流

### 输入延迟高

1. 检查网络 RTT（往返时间）
2. 考虑使用相对鼠标模式
3. 检查远程主机性能

### 编译错误

如果遇到 Freezed 生成的代码错误：
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 开发计划

- [ ] 游戏手柄支持（需要平台通道实现）
- [ ] 剪贴板同步
- [ ] 文件传输通道
- [ ] 音频回传（麦克风）
- [ ] 录制和截图功能
- [ ] 触觉反馈

## 技术栈

- **Flutter**: 跨平台 UI 框架
- **flutter_webrtc**: WebRTC 插件
- **web_socket_channel**: WebSocket 客户端
- **freezed**: 不可变数据类生成
- **logger**: 日志记录

## 参考项目

- [WebRTC Momo](https://github.com/shiguredo/momo) - WebRTC 原生媒体引擎
- [Ayame](https://github.com/OpenAyame/ayame) - WebRTC 信令服务器
- [flutter_webrtc](https://github.com/flutter-webrtc/flutter-webrtc) - Flutter WebRTC 插件

## 许可证

本项目参考 remotecontrol 项目实现，仅供学习和研究使用。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 联系方式

如有问题或建议，请提交 Issue。

