import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mechanica/main.dart';
import 'package:mechanica/game/mechanica_game.dart';

void main() {
  testWidgets('Missing room art produces a Vietnamese recovery message', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final c = (await tester.runAsync(() => bootstrap(audioEnabled: false)))!;
    c.start(0);
    final game = MechanicaGame(
      c,
      onInspect: () {},
      imagesCache: Images(prefix: 'assets/intentionally_missing/'),
    );
    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    await tester.runAsync(() => game.loaded);
    await tester.pump();
    expect(game.initialized, true);
    expect(game.assetError, contains('Không tải được hình ảnh'));
    expect(game.room.art, isEmpty);
    expect(tester.takeException(), isNull);
    // A scene can survive one scheduler frame after developer mode clears it.
    c.session = null;
    game.update(.016);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(c.saveNow);
    c.dispose();
  });
}
