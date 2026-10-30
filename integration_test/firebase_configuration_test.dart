import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanica/core/cloud_service.dart';
import 'package:mechanica/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android initializes the configured real Firebase app without writes',
    (tester) async {
      expect(const bool.fromEnvironment('FIREBASE_EMULATOR'), isFalse);
      expect(const bool.fromEnvironment('FIREBASE_OFFLINE'), isFalse);
      final cloud = await CloudService.initialize();
      try {
        expect(cloud.available, isTrue, reason: cloud.status);
        expect(cloud.auth!.app.name, '[DEFAULT]');
        expect(cloud.auth!.app.options.projectId, 'mechanica-e9e41');
        expect(
          cloud.auth!.app.options.appId,
          DefaultFirebaseOptions.android.appId,
        );
        expect(cloud.db!.app.name, cloud.auth!.app.name);
        // No registration, sign-in, sign-out or document write in this smoke test.
      } finally {
        cloud.dispose();
      }
    },
  );
}
