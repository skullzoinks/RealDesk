import 'package:flutter/material.dart';

import '../../settings/settings_model.dart';
import '../../settings/settings_store.dart';

const _codecOptions = [
  {'value': 'H264', 'label': 'H.264 / AVC'},
  {'value': 'H265', 'label': 'H.265 / HEVC'},
  {'value': 'VP9', 'label': 'VP9'},
  {'value': 'VP8', 'label': 'VP8'},
  {'value': 'AV1', 'label': 'AV1'},
];

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  RealDeskSettings _s = RealDeskSettings();
  final _iceController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SettingsStore.load();
    setState(() {
      _s = s;
      _loading = false;
      _iceController.text = s.iceServersJson;
    });
  }

  Future<void> _save() async {
    _s.iceServersJson = _iceController.text.trim();
    await SettingsStore.save(_s);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存设置')),
    );
  }

  @override
  void dispose() {
    _iceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
            tooltip: '保存',
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('网络'),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('允许不安全连接 (insecure WSS/TLS 验证放宽)'),
                  value: _s.insecure,
                  onChanged: (v) => setState(() => _s.insecure = v),
                ),
                SwitchListTile(
                  title: const Text('禁用 Google STUN (no_google_stun)'),
                  value: _s.noGoogleStun,
                  onChanged: (v) => setState(() => _s.noGoogleStun = v),
                ),
                SwitchListTile(
                  title: const Text('自定义 ICE 服务器（覆盖 Ayame 返回的列表）'),
                  value: _s.overrideIce,
                  onChanged: (v) => setState(() => _s.overrideIce = v),
                ),
                TextField(
                  controller: _iceController,
                  enabled: _s.overrideIce,
                  decoration: const InputDecoration(
                    labelText: 'ICE Servers JSON',
                    hintText: '[{"urls":"stun:stun.l.google.com:19302"}]',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: 6,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('心跳与重连'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _numField(
                        label: '心跳间隔 (秒)',
                        value: _s.heartbeatSeconds,
                        onChanged: (v) => _s.heartbeatSeconds = v,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numField(
                        label: '重连延迟 (秒)',
                        value: _s.reconnectDelaySeconds,
                        onChanged: (v) => _s.reconnectDelaySeconds = v,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numField(
                        label: '最大重连次数',
                        value: _s.maxReconnectAttempts,
                        onChanged: (v) => _s.maxReconnectAttempts = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('默认行为'),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('默认显示统计叠加'),
                  value: _s.defaultShowMetrics,
                  onChanged: (v) => setState(() => _s.defaultShowMetrics = v),
                ),
                SwitchListTile(
                  title: const Text('默认使用相对鼠标模式'),
                  value: _s.defaultMouseRelative,
                  onChanged: (v) => setState(() => _s.defaultMouseRelative = v),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('视频编解码'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _s.preferredVideoCodec,
                  decoration: const InputDecoration(
                    labelText: '优先视频编码器',
                    helperText: '仅对接收端可用的编码器生效，Android 上优先尝试 MediaCodec 硬件解码',
                    border: OutlineInputBorder(),
                  ),
                  items: _codecOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option['value']!,
                          child: Text(option['label']!),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _s.preferredVideoCodec = value;
                    });
                  },
                ),
              ],
            ),
    );
  }

  Widget _numField({
    required String label,
    required int value,
    required void Function(int) onChanged,
  }) {
    final c = TextEditingController(text: value.toString());
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (t) {
        final v = int.tryParse(t) ?? value;
        onChanged(v);
      },
    );
  }
}
