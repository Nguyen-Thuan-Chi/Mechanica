import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mechanica/main.dart' as app;
import 'package:mechanica/ui/app.dart';
import 'package:mechanica/ui/play_screen.dart';
import 'package:mechanica/ui/widgets.dart';
import 'package:mechanica/app/controller.dart';
import 'package:mechanica/core/persistence.dart';
import 'package:mechanica/game/puzzles/model.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Phase 2 normal progression: exploration, inventory, twelve machines and ending',
    (tester) async {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ProgressStore.key);
      await prefs.remove(ProgressStore.backupKey);
      final c = await app.bootstrap();
      const first = int.fromEnvironment('TEST_FROM', defaultValue: 1);
      if (first > 1) c.store.unlocked = first;
      await tester.pumpWidget(MechanicaApp(controller: c));
      Future<void> frames([int n = 10]) async {
        for (var k = 0; k < n; k++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      Future<void> button(String label) async {
        final f = find.widgetWithText(MetalButton, label);
        await tester.ensureVisible(f);
        await tester.tap(f);
        await frames(5);
      }

      Future<void> dismissTutorial() async {
        if (find.text('Bắt đầu sửa máy').evaluate().isNotEmpty) {
          await button('Bắt đầu sửa máy');
        }
        if (find.text('Đã rõ').evaluate().isNotEmpty) {
          await button('Đã rõ');
        }
      }

      await frames(20);
      await binding.convertFlutterSurfaceToImage();
      await frames(3);
      await binding.takeScreenshot('p2_home');
      await button('Bắt đầu hành trình');
      await frames(20);
      for (var i = first - 1; i < 12; i++) {
        if (i > first - 1) {
          await button('Cánh cửa tiếp theo');
          await frames(20);
        }
        expect(c.isDeveloper, false);
        expect(c.session!.definition.number, i + 1);
        final l = c.session!.definition;
        final play = tester.state<PlayScreenState>(find.byType(PlayScreen));
        final game = play.game;
        for (var wait = 0; !game.initialized && wait < 100; wait++) {
          await frames(2);
        }
        expect(game.initialized, true);
        expect(game.assetError, isNull);
        Offset world(Offset p) {
          final b = tester.getRect(
            find.byWidgetPredicate((w) => w is GameWidget),
          );
          final scale = math.min(b.width / 1280, b.height / 720);
          return b.topLeft +
              Offset(
                (b.width - 1280 * scale) / 2,
                (b.height - 720 * scale) / 2,
              ) +
              p * scale;
        }

        Future<void> hotspot(String id) async {
          final h = l.room!.hotspots.firstWhere((h) => h.id == id);
          await tester.tapAt(
            world(Offset(h.rect[0] + h.rect[2] / 2, h.rect[1] + h.rect[3] / 2)),
          );
          await frames(5);
        }

        await dismissTutorial();
        if (i % 3 == 0 || i == 11) {
          await binding.takeScreenshot('p2_room${i + 1}');
        }
        await hotspot('journal');
        await button('Trở lại phòng');
        expect(c.session!.state['inspected'], 1);
        await hotspot('clue');
        await button('Trở lại phòng');
        expect(c.session!.state['clueFound'], 1);
        await hotspot('cabinet');
        for (final _ in l.room!.solution.where((a) => a == 'ACT_CASE')) {
          await tester.tap(find.byKey(const ValueKey('room_dial')));
          await frames(4);
        }
        await button('Nhặt vật phẩm');
        expect(c.session!.state['itemA'], 1);
        if (l.room!.combine) {
          await hotspot('aux');
          await button('Nhặt vật phẩm');
          expect(c.session!.state['itemB'], 1);
        }
        await button('Túi đồ');
        final itemA = l.room!.items.first;
        await tester.tap(find.byKey(ValueKey(itemA.id)));
        await frames(3);
        if (l.room!.combine) {
          await tester.tap(find.byKey(ValueKey(l.room!.items[1].id)));
          await frames(4);
          expect(c.session!.state['itemC'], 1);
          if (i == 1) await binding.takeScreenshot('p2_inventory_combined');
        }
        if (i == 0) {
          final h = l.room!.hotspots.firstWhere((h) => h.id == 'repair');
          final from = tester.getCenter(find.byKey(ValueKey(itemA.id)));
          await tester.timedDragFrom(
            from,
            world(
                  Offset(h.rect[0] + h.rect[2] / 2, h.rect[1] + h.rect[3] / 2),
                ) -
                from,
            const Duration(milliseconds: 800),
          );
          await frames(5);
        } else {
          await button('Cất túi');
          await hotspot('repair');
        }
        expect(
          c.session!.state['repairReady'],
          1,
          reason: 'Physical inventory use ${l.id}',
        );
        await dismissTutorial();
        await hotspot('machine');
        await frames(25);
        expect(c.zoom, true);
        await dismissTutorial();
        if (i == 0) {
          await button('Ⅱ');
          final frozen = game.room.time;
          await frames(10);
          expect(game.room.time, frozen);
          await button('Tiếp tục');
          await tester.binding.handlePopRoute();
          await frames(15);
          expect(c.zoom, false);
          await hotspot('machine');
          await frames(25);
        }
        await binding.takeScreenshot(
          'p2_lv${(i + 1).toString().padLeft(2, '0')}',
        );
        for (final id in l.solution.skip(l.room!.solution.length)) {
          final expected = c.session!.reducer.apply(
            c.session!.state,
            PuzzleAction(id),
          );
          if (i >= 9 && id == 'ACT_STEP') {
            await button('Một nhịp');
          } else {
            final m = game.room.machine;
            final d = m.devices.firstWhere((d) => d.control.id == id);
            await tester.tapAt(
              world(
                Offset(
                  m.position.x + d.position.x * m.scale.x,
                  m.position.y + d.position.y * m.scale.y,
                ),
              ),
            );
            await frames(5);
          }
          expect(
            c.session!.state.values,
            expected.state.values,
            reason: 'Wrong touch ${l.id} $id',
          );
        }
        expect(c.session!.state.won, true, reason: l.id);
        expect(c.session!.state.errors, 0);
        await frames(90);
        expect(c.showResult, true);
        expect(tester.takeException(), isNull);
      }
      await button('Xem kết thúc');
      await frames(180);
      await binding.takeScreenshot('p2_ending');
      await button('Trở về · Tiếp tục khám phá');
      expect(c.page, AppPage.home);
      await c.saveNow();
      final loaded = ProgressStore(prefs)..load();
      expect(loaded.bestStars.length, 13 - first);
      expect(loaded.unlocked, 12);
      expect(c.audio.error, isNull);
      expect(c.audio.musicStarts, lessThanOrEqualTo(4));
      await c.audio.dispose();
    },
    timeout: const Timeout(Duration(minutes: 18)),
  );
}
