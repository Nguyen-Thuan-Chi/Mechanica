import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanica/firebase_options.dart';

void main() {
  test(
    'Android native and Dart Firebase configurations match the test project',
    () {
      final config = jsonDecode(
        File('android/app/google-services.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final clients = config['client'] as List<dynamic>;
      final client = clients.cast<Map<String, dynamic>>().singleWhere(
        (c) =>
            c['client_info']['android_client_info']['package_name'] ==
            'com.mechanica.mechanica',
      );
      const options = DefaultFirebaseOptions.android;
      expect(options.projectId, 'mechanica-e9e41');
      expect(options.projectId, config['project_info']['project_id']);
      expect(
        options.messagingSenderId,
        config['project_info']['project_number'],
      );
      expect(options.appId, client['client_info']['mobilesdk_app_id']);
      expect(options.apiKey, client['api_key'][0]['current_key']);
      expect(options.appId.split(':'), hasLength(4));
    },
  );
}
