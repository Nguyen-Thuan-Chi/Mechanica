import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mechanica/main.dart';
import 'package:mechanica/core/persistence.dart';
import 'package:mechanica/game/puzzles/model.dart';
import 'package:mechanica/game/puzzles/reducer.dart';
import 'package:mechanica/game/mechanics/device_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final levels = PuzzleDefinition.decode(
    File('assets/data/levels.json').readAsStringSync(),
  );
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final l in levels) {
    test(
      '${l.id}: repair requires an actual inventory part, independent room clues persist',
      () {
        final s = PuzzleSession(l);
        s.act(PuzzleAction.inspect);
        expect(s.act(const PuzzleAction('ACT_REPAIR')).accepted, false);
        expect(s.state['repairReady'], 0);
        for (final c in l.controls.where((c) => !c.isRoomAction)) {
          expect(s.act(PuzzleAction(c.id)).accepted, false);
        }
        s.reset();
        for (final id in l.room!.solution) {
          expect(s.act(PuzzleAction(id)).accepted, true, reason: id);
        }
        expect(s.state['clueFound'], 1);
        expect(s.state['repairReady'], 1);
        final item = l.room!.items.last;
        expect(s.state[item.field], 2);
        s.undo();
        expect(s.state['repairReady'], 0);
        expect(s.state[item.field], 1);
        expect(s.act(const PuzzleAction('ACT_REPAIR')).accepted, true);
        final before = s.state.values;
        expect(s.act(const PuzzleAction('ACT_SEARCH')).accepted, false);
        expect(s.state.values, before);
      },
    );
  }
  for (final l in levels.where((l) => l.room!.combine)) {
    test(
      '${l.id}: combine consumes two held parts atomically and undo returns them',
      () {
        final s = PuzzleSession(l);
        for (final id in l.room!.solution.takeWhile(
          (id) => id != 'ACT_COMBINE',
        )) {
          s.act(PuzzleAction(id));
        }
        expect(s.state['itemA'], 1);
        expect(s.state['itemB'], 1);
        s.act(const PuzzleAction('ACT_COMBINE'));
        expect(s.state['itemA'], 2);
        expect(s.state['itemB'], 2);
        expect(s.state['itemC'], 1);
        expect(s.act(const PuzzleAction('ACT_COMBINE')).accepted, false);
        s.undo();
        expect(s.state['itemA'], 1);
        expect(s.state['itemB'], 1);
        expect(s.state['itemC'], 0);
      },
    );
  }
  test(
    'Developer entry, all 12 direct jumps and reset never mutate player save',
    () async {
      final c = await bootstrap(audioEnabled: false);
      c.start(0);
      c.inspect();
      await c.saveNow();
      final before = c.store.preferences.getString(ProgressStore.key);
      c.start(11);
      expect(c.session!.definition.number, 1);
      await c.setDeveloper(true);
      for (var i = 0; i < 12; i++) {
        c.developerJump(i);
        expect(c.session!.definition.number, i + 1);
        expect(c.store.bestStars, isEmpty);
      }
      for (final id in c.levels.last.solution) {
        c.act(PuzzleAction(id));
      }
      await c.saveNow();
      expect(c.store.bestStars['LV12'], isNotNull);
      expect(c.store.preferences.getString(ProgressStore.key), before);
      c.developerHotspots();
      expect(c.showHotspots, true);
      await c.developerResetSave();
      expect(c.store.bestStars, isEmpty);
      await c.setDeveloper(false);
      expect(c.isDeveloper, false);
      expect(c.store.unlocked, 1);
      c.continueGame();
      expect(c.session!.definition.number, 1);
      expect(c.session!.state['inspected'], 1);
      await c.saveNow();
      c.dispose();
    },
  );
  test('v1 migration keeps achievements and machine fields while adding room state', () async {
    final prefs = await SharedPreferences.getInstance();
    final old = Map<String, int>.of(levels.first.initial)
      ..removeWhere(
        (k, v) => [
          'clueFound',
          'repairReady',
          'itemA',
          'itemB',
          'itemC',
          'caseDial',
          'cabinetOpen',
        ].contains(k),
      );
    old['inspected'] = 1;
    old['gearA'] = 2;
    await prefs.setString(
      ProgressStore.key,
      jsonEncode({
        'save_version': 1,
        'unlocked': 5,
        'best_stars': {'LV01': 3},
        'best_moves': {},
        'hint_usage': {},
        'tutorials': [],
        'settings': {},
        'resume': {
          'level': 'LV01',
          'state': {'values': old, 'moves': 2, 'errors': 0, 'ticks': 0},
          'hints': 0,
          'undo': 0,
        },
      }),
    );
    final store = ProgressStore(prefs)..load();
    // Settings may be saved before the old in-progress level is opened.
    store.settings.music = .2;
    await store.save();
    final reloaded = ProgressStore(prefs)..load();
    final restored = reloaded.restore(levels.first)!;
    expect(store.unlocked, 5);
    expect(store.bestStars['LV01'], 3);
    expect(restored['gearA'], 2);
    expect(restored['repairReady'], 0);
    await store.saveSession(levels.first, restored, 0, 0);
    expect(jsonDecode(prefs.getString(ProgressStore.key)!)['save_version'], 2);
  });
  test('Room inventory controller rejects wrong use, combines and restores after process-like reload', () async {
    final c = await bootstrap(audioEnabled: false);
    await c.setDeveloper(true);
    c.developerJump(3);
    for (final id in c.session!.definition.room!.solution.takeWhile(
      (id) => id != 'ACT_COMBINE',
    )) {
      c.act(PuzzleAction(id));
    }
    final items = c.inventory;
    c.selectItem(items.first.id);
    c.useSelectedItem('repair');
    expect(c.session!.state['repairReady'], 0);
    expect(c.session!.state['itemA'], 1);
    c.combineItems(items[1].id);
    expect(c.heldItem!.field, 'itemC');
    c.useSelectedItem('repair');
    expect(c.session!.state['repairReady'], 1);
    expect(c.heldItem, isNull);
    await c.saveNow();
    final loaded = ProgressStore(c.store.preferences, development: true)
      ..load();
    expect(
      loaded.restore(c.session!.definition)!.values,
      c.session!.state.values,
    );
    c.setZoom(true);
    expect(c.zoom, true);
    c.setZoom(false);
    expect(c.zoom, false);
    c.dispose();
  });
  test('Motion responds to start, inertia, jam and reduced motion without changing rules', () {
    final m = DeviceMotion();
    m.update(.02, driven: true, jammed: false, overloaded: false);
    expect(m.phase, MotionPhase.starting);
    for (var i = 0; i < 100; i++) {
      m.update(.02, driven: true, jammed: false, overloaded: false);
    }
    expect(m.phase, MotionPhase.running);
    final angle = m.angle;
    m.update(.02, driven: false, jammed: false, overloaded: false);
    expect(m.phase, MotionPhase.stopping);
    m.update(.02, driven: true, jammed: true, overloaded: false);
    expect(m.phase, MotionPhase.blocked);
    m.update(.02, driven: true, jammed: false, overloaded: true);
    expect(m.phase, MotionPhase.overloaded);
    final a = m.angle;
    m.update(
      .02,
      driven: true,
      jammed: false,
      overloaded: false,
      reduced: true,
    );
    expect(m.angle, a);
    expect(angle, greaterThan(0));
  });
}
