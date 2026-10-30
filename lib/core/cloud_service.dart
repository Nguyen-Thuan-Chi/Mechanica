import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'persistence.dart';
import '../game/puzzles/model.dart';
import '../firebase_options.dart';

/// Only the explicit local-emulator build uses demo identifiers. Real builds
/// require the user's Firebase project options; no pretend cloud connection.
class CloudService extends ChangeNotifier {
  FirebaseAuth? auth;
  FirebaseFirestore? db;
  String status = 'Chơi trên thiết bị · chưa cấu hình Firebase';
  bool busy = false;
  bool _closed = false;
  void _changed() {
    if (!_closed) notifyListeners();
  }

  bool get available => auth != null && db != null;
  User? get user => auth?.currentUser;
  final Map<String, Object?> profile = {};
  final List<Json> results = [];
  Future<void> _queue = Future.value();
  Timer? _retry;
  bool networkEnabled = true;
  Future<void> setNetworkEnabled(bool enabled) async {
    networkEnabled = enabled;
    if (enabled) {
      await db?.enableNetwork();
    } else {
      await db?.disableNetwork();
    }
  }

  static Future<CloudService> initialize() async {
    final service = CloudService();
    const emulator = bool.fromEnvironment('FIREBASE_EMULATOR');
    const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if (const bool.fromEnvironment('FIREBASE_OFFLINE')) return service;
    if (!emulator &&
        project.isNotEmpty &&
        (const String.fromEnvironment('FIREBASE_API_KEY').isEmpty ||
            const String.fromEnvironment('FIREBASE_APP_ID').isEmpty ||
            const String.fromEnvironment('FIREBASE_SENDER_ID').isEmpty)) {
      service.status =
          'Thiếu Android client options Firebase. Xem hướng dẫn cấu hình.';
      return service;
    }
    if (emulator && !kDebugMode) {
      service.status = 'Emulator chỉ dùng trong bản debug.';
      return service;
    }
    try {
      final options = emulator
          ? const FirebaseOptions(
              apiKey: 'emulator-only-not-a-real-key',
              appId: '1:1234567890:android:mechanica-emulator',
              messagingSenderId: '1234567890',
              projectId: 'demo-mechanica',
            )
          : project.isEmpty
          ? DefaultFirebaseOptions.currentPlatform
          : const FirebaseOptions(
              apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
              appId: String.fromEnvironment('FIREBASE_APP_ID'),
              messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
              projectId: project,
            );
      // Android auto-initializes the real default app from google-services.
      // A named app keeps local-emulator Auth/cache isolated from that app.
      final app = await Firebase.initializeApp(
        name: emulator
            ? 'mechanica-emulator'
            : project.isNotEmpty
            ? 'mechanica-custom'
            : null,
        options: options,
      );
      service.auth = FirebaseAuth.instanceFor(app: app);
      service.db = FirebaseFirestore.instanceFor(app: app);
      if (emulator) {
        const host = String.fromEnvironment(
          'FIREBASE_EMULATOR_HOST',
          defaultValue: '10.0.2.2',
        );
        await service.auth!.useAuthEmulator(host, 9099);
        service.db!.useFirestoreEmulator(host, 8080);
      }
      service.status = emulator
          ? 'Firebase Emulator · dữ liệu thử'
          : 'Firebase đã khởi tạo';
    } catch (_) {
      service.auth = null;
      service.db = null;
      service.status =
          'Không mở được Firebase. Bạn vẫn có thể chơi trên thiết bị.';
    }
    return service;
  }

  static String? validate(
    String email,
    String password, {
    String? confirmation,
  }) {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) {
      return 'Nhập địa chỉ email hợp lệ.';
    }
    if (password.length < 6) {
      return 'Mật khẩu cần ít nhất 6 ký tự; project có thể yêu cầu mạnh hơn.';
    }
    if (confirmation != null && confirmation != password) {
      return 'Hai mật khẩu chưa giống nhau.';
    }
    return null;
  }

  static String explain(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' =>
          'Email này đã có tài khoản. Hãy đăng nhập hoặc đặt lại mật khẩu.',
        'invalid-email' => 'Địa chỉ email chưa hợp lệ.',
        'weak-password' => 'Mật khẩu chưa đủ mạnh theo yêu cầu của hệ thống.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Email hoặc mật khẩu chưa đúng.',
        'too-many-requests' =>
          'Bạn đã thử nhiều lần. Vui lòng chờ một lát rồi thử lại.',
        'network-request-failed' =>
          'Chưa kết nối được mạng. Tiến trình trên máy vẫn được giữ.',
        'operation-not-allowed' =>
          'Project chưa bật đăng nhập bằng email và mật khẩu.',
        _ => 'Chưa thực hiện được yêu cầu tài khoản. Hãy thử lại.',
      };
    }
    return 'Chưa đồng bộ được. Dữ liệu trên máy vẫn được giữ; hãy thử lại khi có mạng.';
  }

  Future<void> authenticate(
    String email,
    String password, {
    String? name,
  }) async {
    if (!available || busy) return;
    busy = true;
    _changed();
    try {
      if (name == null) {
        await auth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } else {
        await auth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await user!.updateDisplayName(name.trim());
      }
      // Auth succeeds even if profile creation waits for a later online retry.
      try {
        await ensureProfile();
      } catch (_) {
        status = 'Đã đăng nhập · hồ sơ chờ kết nối';
      }
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> resetPassword(String email) async {
    if (!available || busy) return;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) {
      throw const FormatException('Nhập địa chỉ email hợp lệ.');
    }
    busy = true;
    _changed();
    try {
      await auth!.sendPasswordResetEmail(email: email.trim());
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> ensureProfile() async {
    final u = user;
    if (u == null) return;
    final ref = db!.collection('users').doc(u.uid);
    await db!
        .runTransaction((tx) async {
          final doc = await tx.get(ref);
          if (!doc.exists) {
            tx.set(ref, {
              'displayName': u.displayName ?? 'Người gác máy',
              'email': u.email ?? '',
              'createdAt': FieldValue.serverTimestamp(),
              'lastPlayedAt': FieldValue.serverTimestamp(),
              'tutorialCompleted': false,
              'schemaVersion': 3,
            });
          }
        })
        .timeout(const Duration(seconds: 12));
    final doc = await ref.get();
    if (user?.uid == u.uid) {
      profile
        ..clear()
        ..addAll(doc.data() ?? {});
    }
  }

  Future<void> signOut() async {
    _retry?.cancel();
    await _queue;
    _retry?.cancel();
    await auth?.signOut();
    profile.clear();
    results.clear();
    _changed();
  }

  String operationId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';

  /// Persisted operations are scoped to one UID. Nothing is uploaded per tick.
  Future<void> checkpoint(ProgressStore store) async {
    if (store.development || store.uid == null || user?.uid != store.uid) {
      return;
    }
    // Coalesce progress checkpoints; completion operations retain unique IDs.
    store.outbox.removeWhere((o) => o['kind'] == 'progress');
    store.outbox.add({
      'id': operationId(),
      'kind': 'progress',
      'unlockedLevel': store.unlocked,
      'currentLevel':
          store.resume?['level'] ??
          'LV${store.unlocked.toString().padLeft(2, '0')}',
      'tutorialCompleted':
          store.tutorials.contains('v3_completed') ||
          store.tutorials.contains('v3_skipped'),
    });
    await store.save();
    unawaited(sync(store));
  }

  Future<void> record(
    ProgressStore store,
    String level,
    int stars,
    int moves,
    int seconds,
    String runId,
  ) async {
    if (store.development || store.uid == null || user?.uid != store.uid) {
      return;
    }
    if (!store.outbox.any((o) => o['id'] == runId)) {
      store.outbox.add({
        'id': runId,
        'kind': 'result',
        'level': level,
        'bestStars': stars,
        'bestMoves': moves,
        'bestTimeSeconds': seconds.clamp(0, 86400),
      });
    }
    await checkpoint(store);
  }

  Future<void> sync(ProgressStore store) {
    _queue = _queue.catchError((Object _) {}).then((_) async {
      if (!available ||
          !networkEnabled ||
          store.uid == null ||
          store.development ||
          user?.uid != store.uid) {
        return;
      }
      try {
        await ensureProfile();
        while (!_closed && store.outbox.isNotEmpty && user?.uid == store.uid) {
          final op = Map<String, Object?>.of(store.outbox.first);
          await _upload(store, op).timeout(const Duration(seconds: 14));
          store.outbox.removeWhere((o) => o['id'] == op['id']);
          await store.save();
        }
        await download(store);
        status = 'Đã đồng bộ với tài khoản';
        _retry?.cancel();
      } catch (_) {
        status = 'Chờ đồng bộ · tiến trình vẫn lưu trên máy';
        _retry?.cancel();
        _retry = Timer(
          const Duration(seconds: 20),
          () => unawaited(sync(store)),
        );
      }
      _changed();
    });
    return _queue;
  }

  Future<void> _upload(ProgressStore store, Json op) async {
    final base = db!.collection('users').doc(store.uid);
    final receipt = base.collection('syncEvents').doc(op['id']! as String);
    final progress = base.collection('progress').doc('current');
    final result = op['kind'] == 'result'
        ? base.collection('levelResults').doc(op['level']! as String)
        : null;
    await db!.runTransaction((tx) async {
      final seen = await tx.get(receipt);
      if (seen.exists) return;
      if (result != null) {
        final old = (await tx.get(result)).data() ?? {};
        int n(String k, int fallback) => (old[k] as num?)?.toInt() ?? fallback;
        tx.set(result, {
          'completed': true,
          'bestStars': max(n('bestStars', 0), op['bestStars']! as int),
          'bestMoves': min(n('bestMoves', 100000), op['bestMoves']! as int),
          'bestTimeSeconds': min(
            n('bestTimeSeconds', 86400),
            op['bestTimeSeconds']! as int,
          ),
          'attempts': n('attempts', 0) + 1,
          'lastCompletedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final old = (await tx.get(progress)).data() ?? {};
        tx.set(progress, {
          'unlockedLevel': max(
            (old['unlockedLevel'] as num?)?.toInt() ?? 1,
            op['unlockedLevel']! as int,
          ),
          'currentLevel': op['currentLevel'],
          'completedLevels': FieldValue.arrayUnion(
            store.bestStars.keys.toList(),
          ),
          'lastSavedAt': FieldValue.serverTimestamp(),
          'saveVersion': 3,
        });
        tx.update(base, {
          'lastPlayedAt': FieldValue.serverTimestamp(),
          if (op['tutorialCompleted'] == true) 'tutorialCompleted': true,
        });
      }
      tx.set(receipt, {
        'kind': op['kind'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> download(ProgressStore store) async {
    final uid = store.uid;
    if (uid == null || user?.uid != uid) return;
    final base = db!.collection('users').doc(uid);
    final p = await base.collection('progress').doc('current').get();
    // Query of per-level documents, also used to display account achievements.
    final query = await base
        .collection('levelResults')
        .where('completed', isEqualTo: true)
        .get();
    final u = await base.get();
    if (user?.uid != uid) return;
    store.unlocked = max(
      store.unlocked,
      (p.data()?['unlockedLevel'] as num?)?.toInt() ?? 1,
    ).clamp(1, 12);
    results.clear();
    for (final doc in query.docs) {
      final d = doc.data();
      results.add({'level': doc.id, ...d});
      final stars = (d['bestStars']! as num).toInt();
      store.bestStars[doc.id] = max(store.bestStars[doc.id] ?? 0, stars);
      store.bestMoves[doc.id] = min(
        store.bestMoves[doc.id] ?? 100000,
        (d['bestMoves']! as num).toInt(),
      );
      store.bestSeconds[doc.id] = min(
        store.bestSeconds[doc.id] ?? 86400,
        (d['bestTimeSeconds']! as num).toInt(),
      );
    }
    profile
      ..clear()
      ..addAll(u.data() ?? {});
    if (profile['tutorialCompleted'] == true &&
        !store.tutorials.contains('v3_completed')) {
      store.tutorials.add('v3_skipped');
    }
    await store.save();
  }

  @override
  void dispose() {
    _closed = true;
    _retry?.cancel();
    super.dispose();
  }
}
