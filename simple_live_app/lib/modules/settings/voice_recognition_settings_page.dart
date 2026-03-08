import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/services/voice_model_manager.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_number.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

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

  Future<_VoiceModelCatalog> _loadCatalog() async {
    final models = await _modelManager.loadPreferredModels();
    final downloaded = <String, bool>{};
    for (final model in models) {
      downloaded[model.name] = await _modelManager.isModelAvailable(model.name);
    }
    return _VoiceModelCatalog(models: models, downloaded: downloaded);
  }

  void _refreshCatalog() {
    setState(() {
      _catalogFuture = _loadCatalog();
    });
  }

  Future<void> _selectModel(
    LanguageModelDescription model,
    bool downloaded,
  ) async {
    if (!downloaded) {
      SmartDialog.showLoading(msg: "模型下载中");
      try {
        await _modelManager.ensureModel(model);
      } catch (e) {
        SmartDialog.dismiss();
        SmartDialog.showToast("模型下载失败: $e");
        return;
      }
      SmartDialog.dismiss();
    }
    AppSettingsController.instance.setSubtitleModelName(model.name);
    _refreshCatalog();
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
                    value:
                        AppSettingsController.instance.subtitleEnable.value,
                    onChanged:
                        AppSettingsController.instance.setSubtitleEnable,
                  ),
                ),
                AppStyle.divider,
                Obx(
                  () => SettingsNumber(
                    title: "字体大小",
                    value: AppSettingsController.instance.subtitleFontSize
                        .value
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
            child: Text(
              "语言模型",
              style: Get.textTheme.titleSmall,
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
              return SettingsCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: catalog.models.map((model) {
                    final downloaded =
                        catalog.downloaded[model.name] ?? false;
                    return Obx(
                      () => ListTile(
                        title: Text(model.langText),
                        subtitle: Text(model.sizeText),
                        trailing: downloaded
                            ? const Icon(Icons.check_circle, size: 20)
                            : const Icon(Icons.cloud_download_outlined, size: 20),
                        selected: AppSettingsController
                                .instance.subtitleModelName.value ==
                            model.name,
                        onTap: () => _selectModel(model, downloaded),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VoiceModelCatalog {
  final List<LanguageModelDescription> models;
  final Map<String, bool> downloaded;

  _VoiceModelCatalog({
    required this.models,
    required this.downloaded,
  });
}
