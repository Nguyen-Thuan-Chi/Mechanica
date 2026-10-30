import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanica/main.dart';
import 'package:mechanica/core/persistence.dart';
import 'package:mechanica/game/puzzles/model.dart';
import 'package:mechanica/ui/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Firebase emulator real Auth, Firestore, offline outbox and two UID isolation',
    (tester) async {
      expect(
        const bool.fromEnvironment('FIREBASE_EMULATOR'),
        isTrue,
        reason:
            'This test creates accounts; run only with FIREBASE_EMULATOR=true.',
      );
      final c = await bootstrap(audioEnabled: false, cloudEnabled: true);
      expect(c.cloud.available, true, reason: c.cloud.status);
      await c.cloud.signOut();
      final nonce = DateTime.now().microsecondsSinceEpoch;
      final emailA = 'a$nonce@example.com', emailB = 'b$nonce@example.com';
      const password = 'Mechanical123!';
      await tester.pumpWidget(MechanicaApp(controller: c));
      await c.cloud.authenticate(emailA, password, name: 'Người gác A');
      final uidA = c.cloud.user!.uid;
      await c.activateAccount();
      expect(c.cloud.profile['tutorialCompleted'], false);
      expect(c.cloud.profile['email'], emailA);
      final guestBefore = c.store.preferences.getString(ProgressStore.key);
      c.start(0);
      c.beginOnboarding();
      for (final id in c.levels.first.solution) {
        c.act(PuzzleAction(id));
      }
      await c.saveNow();
      await c.cloud.sync(c.store);
      expect(c.store.bestStars['LV01'], 3);
      expect(c.cloud.profile['tutorialCompleted'], true);
      expect(c.cloud.results.single['attempts'], 1);
      final last = c.cloud.results.single;
      await c.cloud.record(c.store, 'LV01', 1, 99, 999, 'worse_$nonce');
      await c.cloud.sync(c.store);
      expect(c.cloud.results.single['bestStars'], last['bestStars']);
      expect(c.cloud.results.single['bestMoves'], last['bestMoves']);
      await c.cloud.record(c.store, 'LV01', 1, 99, 999, 'worse_$nonce');
      await c.cloud.sync(c.store);
      expect(c.cloud.results.single['attempts'], 2);
      // Turn off native networking: writes stay in the durable local outbox.
      await c.cloud.setNetworkEnabled(false);
      await c.cloud.record(c.store, 'LV01', 2, 40, 90, 'offline_$nonce');
      await c.cloud.sync(c.store);
      expect(c.store.outbox, isNotEmpty);
      await c.cloud.setNetworkEnabled(true);
      await c.cloud.sync(c.store);
      expect(c.store.outbox, isEmpty);
      expect(c.cloud.results.single['attempts'], 3);
      await c.cloud.resetPassword(emailA);
      await c.signOutAccount();
      await c.cloud.authenticate(emailB, password, name: 'Người gác B');
      await c.activateAccount();
      expect(c.cloud.user!.uid, isNot(uidA));
      expect(c.store.unlocked, 1);
      expect(c.store.bestStars, isEmpty);
      expect(c.store.preferences.getString(ProgressStore.key), guestBefore);
      await c.signOutAccount();
      await c.cloud.authenticate(emailA, password);
      await c.activateAccount();
      expect(c.cloud.user!.uid, uidA);
      expect(c.store.bestStars['LV01'], 3);
      // Download to a second fresh local namespace snapshot for the same UID.
      final fresh = ProgressStore(c.store.preferences, uid: uidA);
      await c.cloud.download(fresh);
      expect(fresh.bestStars['LV01'], 3);
      expect(fresh.unlocked, 2);
      await c.setDeveloper(true);
      c.developerJump(11);
      for (final id in c.levels.last.solution) {
        c.act(PuzzleAction(id));
      }
      await c.saveNow();
      await c.setDeveloper(false);
      await c.cloud.sync(c.store);
      expect(c.cloud.results.any((r) => r['level'] == 'LV12'), false);
      expect(c.cloud.user!.uid, uidA);
      await c.signOutAccount();
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
