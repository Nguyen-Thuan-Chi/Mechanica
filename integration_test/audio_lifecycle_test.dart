import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanica/main.dart' as app;
import 'package:mechanica/ui/app.dart';
import 'package:mechanica/core/persistence.dart';
import 'package:mechanica/game/puzzles/model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Native audio mixing, settings and app lifecycle save', (
    tester,
  ) async {
    final c = await app.bootstrap();
    await tester.pumpWidget(MechanicaApp(controller: c));
    c.start(0);
    for (final id in c.levels.first.room!.solution) {
      c.act(PuzzleAction(id));
    }
    c.act(const PuzzleAction('ACT_GEAR_A'));
    await c.audio.chapter(0);
    final starts = c.audio.musicStarts;
    await Future.wait([c.audio.initialize(), c.audio.initialize()]);
    c.setZoom(true);
    c.setZoom(false);
    await Future.wait([c.audio.chapter(0), c.audio.chapter(0)]);
    expect(c.audio.musicStarts, starts);
    await tester.pump(const Duration(seconds: 1));
    expect(c.audio.ready, true);
    await c.audio.effect('gear');
    await c.audio.effect('water');
    await tester.pump(const Duration(milliseconds: 350));
    expect(FlameAudio.bgm.audioPlayer.state, PlayerState.playing);
    final before = await FlameAudio.bgm.audioPlayer.getCurrentPosition();
    await tester.pump(const Duration(milliseconds: 450));
    final after = await FlameAudio.bgm.audioPlayer.getCurrentPosition();
    expect(after! > before!, true);
    c.store.settings.music = .2;
    c.store.settings.muted = true;
    await c.audio.configure(c.store.settings);
    expect(FlameAudio.bgm.audioPlayer.volume, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.paused, true);
    expect(FlameAudio.bgm.audioPlayer.state, PlayerState.paused);
    final state = c.session!.state;
    await c.saveNow();
    final restored = ProgressStore(c.store.preferences)..load();
    expect(restored.restore(c.levels.first)!.values, state.values);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      c.paused,
      true,
    ); // Explicit resume is required after an interruption.
    c.store.settings.muted = false;
    await c.audio.configure(c.store.settings);
    c.resume();
    await tester.pump(const Duration(milliseconds: 300));
    expect(FlameAudio.bgm.audioPlayer.state, PlayerState.playing);
    c.store.settings.musicEnabled = false;
    await c.audio.configure(c.store.settings);
    expect(FlameAudio.bgm.audioPlayer.volume, 0);
    c.store.settings.musicEnabled = true;
    await c.audio.configure(c.store.settings);
    await Future.wait([
      c.audio.chapter(1),
      c.audio.chapter(2),
      c.audio.chapter(3),
    ]);
    expect(c.audio.currentChapter, 3);
    expect(c.audio.musicStarts, starts + 1);
    expect(FlameAudio.bgm.audioPlayer.releaseMode, ReleaseMode.loop);
    expect(c.audio.error, isNull);
    await c.audio.dispose();
  });
}
