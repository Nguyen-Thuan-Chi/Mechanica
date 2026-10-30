import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mechanica/main.dart';
import 'package:mechanica/core/persistence.dart';
import 'package:mechanica/core/cloud_service.dart';
import 'package:mechanica/game/puzzles/guidance.dart';
import 'package:mechanica/game/puzzles/onboarding.dart';
import 'package:mechanica/game/puzzles/model.dart';
import 'package:mechanica/game/puzzles/reducer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final levels = PuzzleDefinition.decode(
    File('assets/data/levels.json').readAsStringSync(),
  );
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'Onboarding new player, actual actions, reload, skip and replay',
    () async {
      final c = await bootstrap(audioEnabled: false);
      c.start(0);
      expect(c.guideTarget, 'intro');
      c.beginOnboarding();
      expect(c.guideTarget, 'journal');
      c.act(const PuzzleAction('ACT_START'));
      expect(c.guideTarget, 'journal');
      c.inspect();
      expect(c.guideTarget, 'clue');
      c.act(const PuzzleAction('ACT_CLUE'));
      expect(c.guideTarget, 'cabinet');
      c.act(const PuzzleAction('ACT_SEARCH'));
      expect(c.guideTarget, 'inventory');
      await c.saveNow();
      final next = await bootstrap(audioEnabled: false);
      next.continueGame();
      expect(next.guideTarget, 'inventory');
      next.toggleInventory();
      expect(next.guideTarget, 'LV01_ITEM_A');
      next.selectItem('LV01_ITEM_A');
      expect(next.guideTarget, 'repair');
      next.useSelectedItem('repair');
      expect(next.guideTarget, 'machine');
      next.setZoom(true);
      for (var i = 0; i < 15 && !next.session!.state.won; i++) {
        final help = next.currentGuide!;
        expect(help.target.startsWith('ACT_'), true);
        next.act(PuzzleAction(help.target));
      }
      expect(next.session!.state.won, true);
      expect(next.session!.stars, 3);
      expect(next.store.tutorials.contains(Onboarding.completed), true);
      next.start(0);
      expect(next.onboardingActive, false);
      next.replayOnboarding();
      expect(next.onboardingActive, true);
      next.skipOnboarding();
      expect(next.onboardingActive, false);
      await next.saveNow();
      final reloaded = ProgressStore(next.store.preferences)..load();
      expect(reloaded.tutorials.contains(Onboarding.skipped), true);
      c.dispose();
      next.dispose();
    },
  );
  test('wrong gear/start jam remains recoverable with concrete guidance', () {
    final s = PuzzleSession(levels.first);
    for (final id in levels.first.room!.solution) {
      s.act(PuzzleAction(id));
    }
    s.act(const PuzzleAction('ACT_START'));
    for (var i = 0; i < 30 && !s.state.won; i++) {
      final help = GuidanceEngine.solve(levels.first, s.state);
      expect(help.recovery, false);
      expect(s.act(PuzzleAction(help.target)).accepted, true);
    }
    expect(s.state.won, true);
  });
  for (final l in levels) {
    test(
      '${l.id} assisted solution and off-trace advice is executable or explicit recovery',
      () async {
        final s = PuzzleSession(l);
        for (final id in l.solution) {
          final help = await GuidanceEngine.next(l, s.state);
          expect(help.instruction, isNotEmpty);
          s.act(PuzzleAction(id));
        }
        expect(s.state.won, true);
        final wrong = PuzzleSession(l);
        for (final id in l.wrongTrace) {
          wrong.act(PuzzleAction(id));
        }
        final help = await GuidanceEngine.next(l, wrong.state);
        if (help.target.startsWith('ACT_')) {
          expect(
            wrong.reducer
                .apply(wrong.state, PuzzleAction(help.target))
                .accepted,
            true,
          );
        } else {
          expect(
            help.target,
            anyOf(
              'undo',
              'journal',
              'clue',
              'cabinet',
              'repair',
              'aux',
              'inventory',
            ),
          );
        }
      },
    );
  }
  test(
    'account stores are isolated and guest schema 2 remains unchanged',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final guest = ProgressStore(prefs);
      await guest.complete(levels[2], 3, 12);
      final before = prefs.getString(ProgressStore.key);
      final a = ProgressStore(prefs, uid: 'account-a');
      final b = ProgressStore(prefs, uid: 'account-b');
      await a.complete(levels[8], 2, 20);
      await b.save();
      final reload = ProgressStore(prefs, uid: 'account-a')..load();
      expect(reload.unlocked, 10);
      expect(b.unlocked, 1);
      expect(prefs.getString(ProgressStore.key), before);
      a.outbox.add({'id': 'run1', 'kind': 'result'});
      await a.save();
      expect(
        (ProgressStore(prefs, uid: 'account-a')..load()).outbox.single['id'],
        'run1',
      );
      expect((ProgressStore(prefs, uid: 'account-b')..load()).outbox, isEmpty);
      expect(jsonDecode(before!)['save_version'], 2);
    },
  );
  test('authentication validation never needs or stores a password', () {
    expect(CloudService.validate('bad', 'secret'), isNotNull);
    expect(CloudService.validate('player@example.com', '123'), isNotNull);
    expect(
      CloudService.validate(
        'player@example.com',
        'abcdef',
        confirmation: 'other',
      ),
      isNotNull,
    );
    expect(
      CloudService.validate(
        'player@example.com',
        'abcdef',
        confirmation: 'abcdef',
      ),
      isNull,
    );
  });
}
