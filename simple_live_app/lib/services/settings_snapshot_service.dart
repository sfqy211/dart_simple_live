import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/services/local_storage_service.dart';

class SettingsSnapshotService {
  const SettingsSnapshotService._();

  static const instance = SettingsSnapshotService._();

  LocalStorageService get _storage => LocalStorageService.instance;

  Map<String, dynamic> buildSnapshotEnvelope({
    required Map<dynamic, dynamic> config,
    required Map<dynamic, dynamic> shield,
    required String platform,
    required int timestamp,
    int version = 1,
  }) {
    return {
      "type": "simple_live",
      "platform": platform,
      "version": version,
      "time": timestamp,
      "config": Map<dynamic, dynamic>.from(config),
      "shield": Map<dynamic, dynamic>.from(shield),
    };
  }

  Map<String, dynamic> exportSnapshot({
    required String platform,
    required int timestamp,
  }) {
    return buildSnapshotEnvelope(
      config: _storage.settingsBox.toMap(),
      shield: _storage.shieldBox.toMap(),
      platform: platform,
      timestamp: timestamp,
    );
  }

  Map<dynamic, dynamic> exportSettingsMap() {
    return Map<dynamic, dynamic>.from(_storage.settingsBox.toMap());
  }

  List<String> exportShieldList() {
    return AppSettingsController.instance.shieldList.toList();
  }

  Future<void> importSnapshot(Map<String, dynamic> data) async {
    await resetAll();
    await importSettingsMap(data["config"]);
    await importShieldMap(data["shield"]);
  }

  Future<void> importSettingsMap(dynamic data) async {
    if (data is! Map) {
      return;
    }
    await _storage.settingsBox.putAll(Map<dynamic, dynamic>.from(data));
  }

  Future<void> importShieldMap(dynamic data) async {
    if (data is! Map) {
      return;
    }
    await AppSettingsController.instance.clearShieldList();
    final entries = Map<String, String>.from(
      data.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
    await _storage.shieldBox.putAll(entries);
    final shieldList = AppSettingsController.instance.shieldList;
    shieldList.clear();
    shieldList.addAll(entries.values);
  }

  Future<void> importShieldList(
    Iterable<dynamic> keywords, {
    bool clearExisting = false,
  }) async {
    if (clearExisting) {
      await AppSettingsController.instance.clearShieldList();
    }
    for (final keyword in keywords) {
      final trimmed = keyword.toString().trim();
      if (trimmed.isEmpty) {
        continue;
      }
      AppSettingsController.instance.addShieldList(trimmed);
    }
  }

  Future<void> resetAll() async {
    await _storage.settingsBox.clear();
    await _storage.shieldBox.clear();
    AppSettingsController.instance.shieldList.clear();
  }
}
