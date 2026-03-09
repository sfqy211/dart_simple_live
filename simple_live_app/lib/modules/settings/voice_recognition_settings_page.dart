import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/services/voice_model_manager.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_number.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';
import 'package:url_launcher/url_launcher_string.dart';

class VoiceRecognitionSettingsPage extends StatefulWidget {
  const VoiceRecognitionSettingsPage({super.key});

  @override
  State<VoiceRecognitionSettingsPage> createState() =>
      _VoiceRecognitionSettingsPageState();
}

class _VoiceRecognitionSettingsPageState
    extends State<VoiceRecognitionSettingsPage> {
  final VoiceModelManager _modelManager = VoiceModelManager();
  late Future<_VoiceModelCatalog> _catalogFuture;
  late TextEditingController _apiUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _apiKeyHeaderController;

  @override
  void initState() {
    super.initState();
    _catalogFuture = _loadCatalog();
    _apiUrlController = TextEditingController(
      text: AppSettingsController.instance.subtitleOnlineApiUrl.value,
    );
    _apiKeyController = TextEditingController(
      text: AppSettingsController.instance.subtitleOnlineApiKey.value,
    );
    _apiKeyHeaderController = TextEditingController(
      text: AppSettingsController.instance.subtitleOnlineApiKeyHeader.value,
    );
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _apiKeyHeaderController.dispose();
    super.dispose();
  }

  Future<_VoiceModelCatalog> _loadCatalog({bool refresh = false}) async {
    final models = await _modelManager.loadLocalModels(refresh: refresh);
    final current =
        AppSettingsController.instance.subtitleModelName.value.trim();
    if (models.isNotEmpty &&
        (current.isEmpty || !models.any((model) => model.name == current))) {
      AppSettingsController.instance.setSubtitleModelName(models.first.name);
    }
    return _VoiceModelCatalog(models: models);
  }

  void _refreshCatalog() {
    setState(() {
      _catalogFuture = _loadCatalog(refresh: true);
    });
  }

  Future<void> _selectModel(LocalVoiceModel model) async {
    AppSettingsController.instance.setSubtitleModelName(model.name);
    _refreshCatalog();
  }

  String _formatLastModified(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return "${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}";
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      SmartDialog.showToast("无法打开链接: $e");
    }
  }

  String _modeLabel(SubtitleRecognitionMode mode) {
    if (mode == SubtitleRecognitionMode.online) {
      return "在线 API";
    }
    return "本地引擎";
  }

  String _providerLabel(SubtitleOnlineProvider provider) {
    switch (provider) {
      case SubtitleOnlineProvider.customWebSocket:
        return "自定义 WebSocket";
    }
  }

  void _selectRecognitionMode() {
    Get.dialog(
      RadioGroup(
        groupValue:
            AppSettingsController.instance.subtitleRecognitionMode.value.index,
        onChanged: (value) {
          Get.back();
          final mode = SubtitleRecognitionMode.values[value ?? 0];
          AppSettingsController.instance.setSubtitleRecognitionMode(mode);
        },
        child: SimpleDialog(
          title: const Text("识别模式"),
          children: SubtitleRecognitionMode.values
              .map(
                (mode) => RadioListTile<int>(
                  title: Text(_modeLabel(mode)),
                  value: mode.index,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _selectOnlineProvider() {
    Get.dialog(
      RadioGroup(
        groupValue:
            AppSettingsController.instance.subtitleOnlineProvider.value.index,
        onChanged: (value) {
          Get.back();
          final provider = SubtitleOnlineProvider.values[value ?? 0];
          AppSettingsController.instance.setSubtitleOnlineProvider(provider);
        },
        child: SimpleDialog(
          title: const Text("在线服务"),
          children: SubtitleOnlineProvider.values
              .map(
                (provider) => RadioListTile<int>(
                  title: Text(_providerLabel(provider)),
                  value: provider.index,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String title,
    required TextEditingController controller,
    String? hintText,
    bool obscureText = false,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: AppStyle.edgeInsetsH12.copyWith(top: 8, bottom: 8),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: title,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: AppStyle.radius12,
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.withAlpha(25),
          contentPadding: AppStyle.edgeInsetsH12,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _testOnlineConnection() async {
    final url =
        AppSettingsController.instance.subtitleOnlineApiUrl.value.trim();
    if (url.isEmpty) {
      SmartDialog.showToast("请先填写在线识别地址");
      return;
    }
    SmartDialog.showLoading(msg: "测试连接中");
    try {
      final headers = <String, dynamic>{};
      final apiKey =
          AppSettingsController.instance.subtitleOnlineApiKey.value.trim();
      if (apiKey.isNotEmpty) {
        final headerName = AppSettingsController
            .instance.subtitleOnlineApiKeyHeader.value
            .trim();
        final normalizedHeader =
            headerName.isEmpty ? "Authorization" : headerName;
        if (normalizedHeader == "Authorization" &&
            !apiKey.startsWith("Bearer ")) {
          headers[normalizedHeader] = "Bearer $apiKey";
        } else {
          headers[normalizedHeader] = apiKey;
        }
      }
      final socket = await WebSocket.connect(
        url,
        headers: headers.isEmpty ? null : headers,
      );
      await socket.close();
      SmartDialog.dismiss();
      SmartDialog.showToast("连接成功");
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast("连接失败: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("字幕设置"),
      ),
      body: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          SettingsCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => SettingsSwitch(
                    title: "字幕开关",
                    value: AppSettingsController.instance.subtitleEnable.value,
                    onChanged: AppSettingsController.instance.setSubtitleEnable,
                  ),
                ),
                AppStyle.divider,
                Obx(
                  () => SettingsNumber(
                    title: "字体大小",
                    value: AppSettingsController.instance.subtitleFontSize.value
                        .toInt(),
                    min: 10,
                    max: 32,
                    onChanged: (value) {
                      AppSettingsController.instance
                          .setSubtitleFontSize(value.toDouble());
                    },
                  ),
                ),
                AppStyle.divider,
                Obx(
                  () => ListTile(
                    title: const Text("识别模式"),
                    subtitle: Text(
                      _modeLabel(AppSettingsController
                          .instance.subtitleRecognitionMode.value),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectRecognitionMode,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Visibility(
              visible: AppSettingsController
                      .instance.subtitleRecognitionMode.value ==
                  SubtitleRecognitionMode.online,
              child: Column(
                children: [
                  Padding(
                    padding: AppStyle.edgeInsetsA12.copyWith(top: 24),
                    child: Text(
                      "在线识别",
                      style: Get.textTheme.titleSmall,
                    ),
                  ),
                  SettingsCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text("在线服务"),
                          subtitle: Obx(
                            () => Text(
                              _providerLabel(AppSettingsController
                                  .instance.subtitleOnlineProvider.value),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _selectOnlineProvider,
                        ),
                        _buildTextField(
                          title: "API 地址",
                          hintText: "wss://example.com/asr",
                          controller: _apiUrlController,
                          onChanged: (value) {
                            AppSettingsController.instance
                                .setSubtitleOnlineApiUrl(value);
                          },
                        ),
                        _buildTextField(
                          title: "API Key",
                          controller: _apiKeyController,
                          obscureText: true,
                          onChanged: (value) {
                            AppSettingsController.instance
                                .setSubtitleOnlineApiKey(value);
                          },
                        ),
                        _buildTextField(
                          title: "API Key Header",
                          hintText: "Authorization",
                          controller: _apiKeyHeaderController,
                          onChanged: (value) {
                            AppSettingsController.instance
                                .setSubtitleOnlineApiKeyHeader(value);
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: AppStyle.edgeInsetsH12.copyWith(bottom: 8),
                            child: TextButton.icon(
                              onPressed: _testOnlineConnection,
                              icon: const Icon(Icons.wifi_tethering, size: 18),
                              label: const Text("测试连接"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(
            () => Visibility(
              visible: AppSettingsController
                      .instance.subtitleRecognitionMode.value ==
                  SubtitleRecognitionMode.local,
              child: Column(
                children: [
                  Padding(
                    padding: AppStyle.edgeInsetsA12.copyWith(top: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "本地模型",
                          style: Get.textTheme.titleSmall,
                        ),
                        TextButton.icon(
                          onPressed: _refreshCatalog,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text("重新扫描"),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<_VoiceModelCatalog>(
                    future: _catalogFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text("模型加载失败"),
                          ),
                        );
                      }
                      final catalog = snapshot.data!;
                      if (catalog.models.isEmpty) {
                        return SettingsCard(
                          child: Padding(
                            padding: AppStyle.edgeInsetsA12,
                            child: Text(
                              "未检测到本地模型，请先下载 sherpa-onnx 模型并放入simple_live_app\\models",
                              style: Get.textTheme.bodyMedium,
                            ),
                          ),
                        );
                      }
                      return SettingsCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: catalog.models.map((model) {
                            return Obx(
                              () => ListTile(
                                title: Text(model.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${model.sizeText} · ${_formatLastModified(model.lastModified)}",
                                    ),
                                    Text(
                                      "官方下载: ${model.downloadUrl}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                selected: AppSettingsController
                                        .instance.subtitleModelName.value ==
                                    model.name,
                                onTap: () => _selectModel(model),
                                onLongPress: () => _openUrl(model.downloadUrl),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: AppStyle.edgeInsetsA12.copyWith(top: 24),
                    child: Text(
                      "下载来源",
                      style: Get.textTheme.titleSmall,
                    ),
                  ),
                  SettingsCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text("sherpa-onnx 模型下载页"),
                          subtitle: const Text(
                            "https://k2-fsa.github.io/sherpa/onnx/pretrained_models/",
                          ),
                          trailing: const Icon(Icons.open_in_new, size: 20),
                          onTap: () => _openUrl(
                            "https://k2-fsa.github.io/sherpa/onnx/pretrained_models/",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceModelCatalog {
  final List<LocalVoiceModel> models;

  _VoiceModelCatalog({
    required this.models,
  });
}
