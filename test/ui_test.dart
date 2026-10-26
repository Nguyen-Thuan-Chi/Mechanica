import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mechanica/main.dart';
import 'package:mechanica/ui/app.dart';
import 'package:mechanica/app/controller.dart';
import 'package:mechanica/game/puzzles/model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final size in [
    const Size(960, 540),
    const Size(1170, 540),
    const Size(914, 411),
  ]) {
    testWidgets(
      'Vietnamese menus and settings fit ${size.width}/${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final c = (await tester.runAsync(
          () => bootstrap(audioEnabled: false),
        ))!;
        await tester.pumpWidget(MechanicaApp(controller: c));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('MECHANICA'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cài đặt'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Giảm chuyển động'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Đóng'));
        await tester.tap(find.text('Đóng'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('Cách chơi'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Nhìn quanh căn phòng'), findsOneWidget);
        for (var page = 0; page < 6; page++) {
          await tester.ensureVisible(find.text('Trang sau'));
          await tester.tap(find.text('Trang sau'));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
        expect(find.text('Cho máy thời gian'), findsOneWidget);
        await tester.ensureVisible(find.text('Trở lại'));
        await tester.tap(find.text('Trở lại'));
        await tester.pump(const Duration(milliseconds: 400));
        c.navigate(AppPage.chapters);
        await tester.pump();
        expect(tester.takeException(), isNull);
        c.selectedChapter = 0;
        c.navigate(AppPage.levels);
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(c.saveNow);
        c.dispose();
      },
    );
  }
  test('Controller pause blocks actions; undo and reset preserve deterministic state', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await bootstrap(audioEnabled: false);
    c.start(0);
    for (final id in c.levels.first.room!.solution) {
      c.act(PuzzleAction(id));
    }
    c.act(const PuzzleAction('ACT_GEAR_A'));
    final before = c.session!.state;
    c.pause();
    c.act(const PuzzleAction('ACT_GEAR_A'));
    expect(c.session!.state.values, before.values);
    c.resume();
    c.undo();
    expect(c.session!.state['gearA'], 0);
    c.reset();
    expect(c.session!.state.moves, 0);
    expect(c.running, false);
    expect(c.zoom, false);
    await c.saveNow();
    c.dispose();
  });
}
