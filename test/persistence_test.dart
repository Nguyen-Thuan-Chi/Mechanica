import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mechanica/core/persistence.dart';
import 'package:mechanica/game/puzzles/model.dart';
import 'package:mechanica/game/puzzles/reducer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final levels = PuzzleDefinition.decode(
    File('assets/data/levels.json').readAsStringSync(),
  );
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'Damaged primary cannot leave partial fields in restored backup',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final store = ProgressStore(prefs);
      await store.complete(levels.first, 2, 15);
      await store.save();
      final broken = store.snapshot();
      broken['unlocked'] = 12;
      broken['best_stars'] = {'LV12': 3};
      broken['settings'] = {'music': 'invalid type'};
      await prefs.setString(ProgressStore.key, jsonEncode(broken));
      final loaded = ProgressStore(prefs)..load();
      expect(loaded.unlocked, 2);
      expect(loaded.bestStars, {'LV01': 2});
      expect(loaded.warning, isNotNull);
    },
  );
  test('Resume rejects negative resources and impossible fluid mass', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = ProgressStore(prefs);
    final level = levels[3];
    final session = PuzzleSession(level);
    session.act(PuzzleAction.inspect);
    for (final invalid in [-1, 999]) {
      await store.saveSession(level, session.state, 0, 0);
      final state = object(store.resume!['state']);
      final values = Map<String, int>.from(state['values'] as Map);
      values[level.massFields.first] = invalid;
      state['values'] = values;
      store.resume!['state'] = state;
      expect(store.restore(level), isNull);
      expect(store.warning, isNotNull);
    }
  });
  test(
    'Progress, settings and halfway state survive serialized reload',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final store = ProgressStore(prefs);
      final session = PuzzleSession(levels.last);
      for (final a in levels.last.solution.take(8)) {
        session.act(PuzzleAction(a));
      }
      store.settings.music = .17;
      store.settings.reducedMotion = true;
      await store.complete(levels[4], 3, 12);
      await store.saveSession(levels.last, session.state, 2, 1);
      final loaded = ProgressStore(prefs)..load();
      expect(loaded.unlocked, 6);
      expect(loaded.bestStars['LV05'], 3);
      expect(loaded.settings.music, .17);
      expect(loaded.settings.reducedMotion, true);
      final restored = loaded.restore(levels.last)!;
      expect(restored.values, session.state.values);
    },
  );
  test('Backup recovers invalid JSON, reset removes old backup', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = ProgressStore(prefs);
    await store.complete(levels[1], 2, 10);
    await store.save();
    await prefs.setString(ProgressStore.key, 'broken');
    final loaded = ProgressStore(prefs)..load();
    expect(loaded.unlocked, 3);
    expect(loaded.warning, isNotNull);
    await loaded.resetProgress();
    final reset = ProgressStore(prefs)..load();
    expect(reset.unlocked, 1);
    expect(reset.bestStars, isEmpty);
    expect(prefs.getString(ProgressStore.backupKey), isNull);
  });
  test(
    'Sequential save queue does not lose latest result or overwrite best stars',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final store = ProgressStore(prefs);
      final pending = <Future<void>>[];
      for (final l in levels) {
        pending.add(store.complete(l, 3, 12));
      }
      pending.add(store.complete(levels.first, 1, 40));
      await Future.wait(pending);
      final loaded = ProgressStore(prefs)..load();
      expect(loaded.unlocked, 12);
      expect(loaded.bestStars.length, 12);
      expect(loaded.bestStars['LV01'], 3);
      expect(loaded.bestMoves['LV01'], 12);
    },
  );
}
