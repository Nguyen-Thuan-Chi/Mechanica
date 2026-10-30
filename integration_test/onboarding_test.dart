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
import 'package:mechanica/core/persistence.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'New player follows only highlighted onboarding actions to win level 01',
    (tester) async {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ProgressStore.key);
      await prefs.remove(ProgressStore.backupKey);
      final c = await app.bootstrap();
      await tester.pumpWidget(MechanicaApp(controller: c));
      Future<void> frames([int n = 8]) async {
        for (var i = 0; i < n; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      Future<void> button(String label) async {
        final f = find.widgetWithText(MetalButton, label).first;
        await tester.ensureVisible(f);
        await tester.tap(f);
        await frames();
      }

      await frames(20);
      await button('Bắt đầu hành trình');
      await frames(20);
      final game = tester.state<PlayScreenState>(find.byType(PlayScreen)).game;
      for (var i = 0; !game.initialized && i < 100; i++) {
        await frames(2);
      }
      await binding.convertFlutterSurfaceToImage();
      await frames();
      await binding.takeScreenshot('v3_onboarding_intro');
      expect(c.guideTarget, 'intro');
      await button('Bắt đầu sửa máy');
      Offset world(double x, double y) {
        final box = tester.getRect(
          find.byWidgetPredicate((w) => w is GameWidget),
        );
        final scale = math.min(box.width / 1280, box.height / 720);
        return box.topLeft +
            Offset(
              (box.width - 1280 * scale) / 2 + x * scale,
              (box.height - 720 * scale) / 2 + y * scale,
            );
      }

      for (var step = 0; !c.session!.state.won && step < 30; step++) {
        final target = c.guideTarget!;
        if (target == 'inventory') {
          await button('Mở túi đồ');
        } else if (target == 'LV01_ITEM_A') {
          await tester.tap(find.byKey(const ValueKey('LV01_ITEM_A')));
          await frames();
        } else if ([
          'journal',
          'clue',
          'cabinet',
          'repair',
          'machine',
        ].contains(target)) {
          if (target == 'repair' && c.inventoryOpen) await button('Cất túi');
          final h = c.session!.definition.room!.hotspots.firstWhere(
            (h) => h.id == target,
          );
          await tester.tapAt(
            world(h.rect[0] + h.rect[2] / 2, h.rect[1] + h.rect[3] / 2),
          );
          await frames(12);
          if (target == 'journal' || target == 'clue') {
            await button('Trở lại phòng');
          }
          if (target == 'cabinet') await button('Nhặt vật phẩm');
          if (target == 'machine') {
            await frames(25);
            await binding.takeScreenshot('v3_onboarding_gears');
          }
        } else if (target.startsWith('ACT_')) {
          final machine = game.room.machine;
          final d = machine.devices.firstWhere((d) => d.control.id == target);
          await tester.tapAt(
            world(
              machine.position.x + d.position.x * machine.scale.x,
              machine.position.y + d.position.y * machine.scale.y,
            ),
          );
          await frames(10);
        } else {
          fail('Unusable visible tutorial target: $target');
        }
        expect(tester.takeException(), isNull);
      }
      expect(c.session!.state.won, true);
      expect(c.session!.stars, 3);
      expect(c.store.tutorials.contains('v3_completed'), true);
      await frames(100);
      await binding.takeScreenshot('v3_onboarding_complete');
      await c.saveNow();
      await c.audio.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
