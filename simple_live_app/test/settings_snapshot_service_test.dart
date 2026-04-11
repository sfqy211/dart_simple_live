import 'package:flutter_test/flutter_test.dart';
import 'package:simple_live_app/services/settings_snapshot_service.dart';

void main() {
  test('build snapshot envelope uses expected schema', () {
    final envelope = SettingsSnapshotService.instance.buildSnapshotEnvelope(
      config: {'theme': 2},
      shield: {'foo': 'foo'},
      platform: 'windows',
      timestamp: 123,
    );

    expect(envelope['type'], 'simple_live');
    expect(envelope['platform'], 'windows');
    expect(envelope['version'], 1);
    expect(envelope['time'], 123);
    expect(envelope['config'], {'theme': 2});
    expect(envelope['shield'], {'foo': 'foo'});
  });
}
