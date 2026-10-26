import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanica/main.dart' as app;
import 'package:mechanica/ui/app.dart';
import 'package:mechanica/ui/play_screen.dart';
import 'package:mechanica/ui/widgets.dart';
import 'package:mechanica/core/persistence.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Developer UI opens all twelve scenes without changing player progress',
    (tester) async {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      final c = await app.bootstrap(audioEnabled: false);
      await c.saveNow();
      final before = c.store.preferences.getString(ProgressStore.key);
      await tester.pumpWidget(MechanicaApp(controller: c));
      Future<void> frames([int n = 8]) async {
        for (var i = 0; i < n; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      Future<void> button(String label) async {
        final f = find.widgetWithText(MetalButton, label);
        await tester.ensureVisible(f);
        await tester.tap(f);
        await frames();
      }

      await frames(20);
      await tester.tap(find.text('Phòng thử máy'));
      await frames(20);
      await binding.convertFlutterSurfaceToImage();
      await frames();
      await binding.takeScreenshot('p2_developer_menu');
      for (var i = 1; i <= 12; i++) {
        final target = find.byKey(ValueKey('dev_level_$i'));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await frames(20);
        expect(c.isDeveloper, true);
        expect(c.session!.definition.number, i);
        final game = tester
            .state<PlayScreenState>(find.byType(PlayScreen))
            .game;
        for (var wait = 0; !game.initialized && wait < 100; wait++) {
          await frames(2);
        }
        expect(game.initialized, true);
        expect(game.assetError, isNull);
        if (find.text('Đã rõ').evaluate().isNotEmpty) {
          await button('Đã rõ');
        }
        await button('Thử');
        if (i == 1) {
          await button('Hiện vùng chạm');
          expect(c.showHotspots, true);
          await button('Đóng');
          await binding.takeScreenshot('p2_hotspot_overlay');
          await button('Thử');
          await button('Đặt lại máy');
          expect(c.session!.state.moves, 0);
        }
        expect(tester.takeException(), isNull);
      }
      await button('Về hành trình thật');
      expect(c.isDeveloper, false);
      expect(c.store.preferences.getString(ProgressStore.key), before);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
