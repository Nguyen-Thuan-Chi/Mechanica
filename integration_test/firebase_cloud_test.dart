import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mechanica/core/cloud_service.dart';
import 'package:mechanica/core/persistence.dart';
import 'package:mechanica/firebase_options.dart';

// Explicit opt-in: creates temporary users on the existing TEST project.
// Firestore documents must subsequently be removed by the authorized CLI
// operator using only the MECHANICA_CLOUD_QA_UID values printed by this test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Real test-project Auth, transactions and UID security', (
    tester,
  ) async {
    expect(const bool.fromEnvironment('FIREBASE_CLOUD_TEST'), isTrue);
    expect(const bool.fromEnvironment('FIREBASE_EMULATOR'), isFalse);
    expect(DefaultFirebaseOptions.android.projectId, 'mechanica-e9e41');
    final nonce = DateTime.now().microsecondsSinceEpoch;
    final password = 'M3ch!QA${Random.secure().nextInt(1 << 32)}xYz';
    final preferences = await SharedPreferences.getInstance();
    final guestBefore = preferences.getString(ProgressStore.key);
    final apps = <FirebaseApp>[];
    final clouds = <CloudService>[];
    final stores = <ProgressStore>[];
    final emails = <String>[];
    final uids = <String>[];
    try {
      for (var i = 0; i < 2; i++) {
        final app = await Firebase.initializeApp(
          name: 'mechanica-cloud-qa-$nonce-$i',
          options: DefaultFirebaseOptions.android,
        );
        apps.add(app);
        final cloud = CloudService()
          ..auth = FirebaseAuth.instanceFor(app: app)
          ..db = FirebaseFirestore.instanceFor(app: app);
        clouds.add(cloud);
        final email = 'mechanica-qa-$nonce-$i@example.com';
        emails.add(email);
        await cloud.authenticate(email, password, name: 'Mechanica QA $nonce');
        final uid = cloud.user!.uid;
        uids.add(uid);
        // UID is not a credential. Used to scope administrator cleanup.
        // ignore: avoid_print
        print('MECHANICA_CLOUD_QA_UID=$uid');
        await cloud.ensureProfile();
        expect(cloud.profile['email'], email);
        expect(cloud.profile['schemaVersion'], 3);
        stores.add(ProgressStore(preferences, uid: uid));
      }
      final cloud = clouds.first;
      final store = stores.first
        ..unlocked = 2
        ..bestStars['LV01'] = 3
        ..bestMoves['LV01'] = 20
        ..tutorials.add('v3_completed');
      await cloud.record(store, 'LV01', 3, 20, 60, 'cloud_qa_$nonce');
      await cloud.sync(store);
      expect(store.outbox, isEmpty, reason: cloud.status);
      expect(cloud.results.single['bestStars'], 3);
      expect(cloud.results.single['attempts'], 1);
      expect(cloud.profile['tutorialCompleted'], true);
      await cloud.record(store, 'LV01', 1, 99, 999, 'cloud_qa_worse_$nonce');
      await cloud.sync(store);
      await cloud.record(store, 'LV01', 1, 99, 999, 'cloud_qa_worse_$nonce');
      await cloud.sync(store);
      expect(store.outbox, isEmpty, reason: cloud.status);
      expect(cloud.results.single['attempts'], 2);
      expect(cloud.results.single['bestStars'], 3);
      expect(cloud.results.single['bestMoves'], 20);
      final fresh = ProgressStore(preferences, uid: uids.first);
      await cloud.download(fresh);
      expect(fresh.unlocked, 2);
      expect(fresh.bestStars['LV01'], 3);
      final foreign = clouds.last.db!.collection('users').doc(uids.first);
      final denied = isA<FirebaseException>().having(
        (error) => error.code,
        'code',
        'permission-denied',
      );
      await expectLater(
        foreign.get(const GetOptions(source: Source.server)),
        throwsA(denied),
      );
      await expectLater(
        foreign.update({'displayName': 'Forbidden'}),
        throwsA(denied),
      );
      await clouds.last.auth!.signOut();
      await expectLater(
        foreign.get(const GetOptions(source: Source.server)),
        throwsA(denied),
      );
      await cloud.signOut();
      await cloud.authenticate(emails.first, password);
      expect(cloud.user!.uid, uids.first);
      expect(preferences.getString(ProgressStore.key), guestBefore);
    } finally {
      for (var i = 0; i < clouds.length; i++) {
        final cloud = clouds[i];
        cloud.dispose();
        try {
          if (i < uids.length) {
            if (cloud.user == null) {
              await cloud.auth!.signInWithEmailAndPassword(
                email: emails[i],
                password: password,
              );
            }
            await cloud.user!.delete();
            // ignore: avoid_print
            print('MECHANICA_CLOUD_QA_AUTH_DELETED=${uids[i]}');
          }
        } finally {
          if (i < stores.length) {
            await preferences.remove(stores[i].storageKey);
            await preferences.remove(stores[i].storageBackupKey);
          }
          await apps[i].delete();
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
