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

  @override
  void initState() {
    super.initState();
    _catalogFuture = _loadCatalog();
  }

  Future<_VoiceModelCatalog> _loadCatalog({bool refresh = false}) async {
    final models = await _modelManager.loadLocalModels(refresh: refresh);
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
              ],
            ),
          ),
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
                      "未检测到本地模型，请先下载并放入simple_live_app\\models",
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
                  title: const Text("Vosk 官方模型下载页"),
                  subtitle: const Text("https://alphacephei.com/vosk/models"),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () => _openUrl("https://alphacephei.com/vosk/models"),
                ),
              ],
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
