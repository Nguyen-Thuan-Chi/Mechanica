import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mechanica/main.dart' as app;
import 'package:mechanica/ui/app.dart';
import 'package:mechanica/ui/widgets.dart';
import 'package:mechanica/core/persistence.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Account forms validate and perform real emulator registration, reset, logout and login',
    (tester) async {
      expect(
        const bool.fromEnvironment('FIREBASE_EMULATOR'),
        isTrue,
        reason:
            'This test creates accounts; run only with FIREBASE_EMULATOR=true.',
      );
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ProgressStore.key);
      await prefs.remove(ProgressStore.backupKey);
      final c = await app.bootstrap(audioEnabled: false, cloudEnabled: true);
      await c.cloud.signOut();
      await tester.pumpWidget(MechanicaApp(controller: c));
      Future<void> frames([int n = 8]) async {
        for (var i = 0; i < n; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      Future<void> button(String text) async {
        final f = find.widgetWithText(MetalButton, text).first;
        await tester.ensureVisible(f);
        await tester.tap(f);
        await frames();
      }

      Future<void> input(String key, String value) async {
        final f = find.byKey(ValueKey(key));
        await tester.ensureVisible(f);
        await tester.enterText(f, value);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await frames(3);
      }

      Future<void> ready() async {
        for (
          var i = 0;
          (find.byType(LinearProgressIndicator).evaluate().isNotEmpty ||
                  c.cloud.busy) &&
              i < 200;
          i++
        ) {
          await frames(2);
        }
      }

      await frames(15);
      await button('Tài khoản');
      await input('account_email', 'bad');
      await input('account_password', '123');
      await button('Đăng nhập');
      expect(find.text('Nhập địa chỉ email hợp lệ.'), findsOneWidget);
      await button('Đăng ký');
      final email = 'ui${DateTime.now().microsecondsSinceEpoch}@example.com';
      await input('account_name', 'Thợ máy thử nghiệm');
      await input('account_email', email);
      await input('account_password', 'Mechanical123!');
      await input('account_confirmation', 'Mechanical123!');
      await binding.convertFlutterSurfaceToImage();
      await frames();
      await binding.takeScreenshot('v3_account_registration');
      await button('Tạo tài khoản');
      await ready();
      expect(c.cloud.user?.email, email);
      expect(find.text('Hồ sơ người chơi'), findsOneWidget);
      expect(c.store.uid, c.cloud.user!.uid);
      await binding.takeScreenshot('v3_account_profile');
      await button('Đăng xuất');
      await ready();
      expect(c.cloud.user, isNull);
      await button('Đã có tài khoản');
      await button('Quên mật khẩu');
      await ready();
      expect(find.textContaining('hướng dẫn đặt lại mật khẩu'), findsOneWidget);
      await input('account_password', 'Mechanical123!');
      await button('Đăng nhập');
      await ready();
      expect(c.cloud.user?.email, email);
      expect(tester.takeException(), isNull);
      await button('Trở về game');
      await c.signOutAccount();
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
