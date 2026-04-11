import 'package:flutter_test/flutter_test.dart';
import 'package:simple_live_app/modules/live_room/player/ghost_bridge.dart';

void main() {
  test('build update payload only includes changed fields', () {
    expect(
      GhostBridge.buildUpdatePayload(opacity: 0.8),
      {'opacity': 0.8},
    );
    expect(
      GhostBridge.buildUpdatePayload(locked: true),
      {'locked': true},
    );
  });

  test('build subtitle payload keeps text and partial state', () {
    expect(
      GhostBridge.buildSubtitlePayload('hello', true),
      {'text': 'hello', 'partial': true},
    );
  });

  test('normalize map list drops invalid items', () {
    expect(
      GhostBridge.normalizeMapList([
        {'a': 1},
        'invalid',
        {'b': 2}
      ]),
      [
        {'a': 1},
        {'b': 2},
      ],
    );
  });
}
