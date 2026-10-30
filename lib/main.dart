import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/controller.dart';
import 'core/audio_service.dart';
import 'core/cloud_service.dart';
import 'core/persistence.dart';
import 'game/puzzles/model.dart';
import 'ui/app.dart';

Future<GameController> bootstrap({
  bool audioEnabled = true,
  bool cloudEnabled = false,
}) async {
  final levels = PuzzleDefinition.decode(
    await rootBundle.loadString('assets/data/levels.json'),
  );
  final store = ProgressStore(await SharedPreferences.getInstance())..load();
  final audio = AudioService(enabled: audioEnabled);
  await audio.initialize();
  await audio.configure(store.settings);
  if (audioEnabled) unawaited(audio.chapter(0));
  final cloud = cloudEnabled ? await CloudService.initialize() : CloudService();
  final controller = GameController(levels, store, audio, cloud: cloud);
  if (cloud.user != null) await controller.activateAccount(waitForSync: false);
  return controller;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const LoadingApp());
  try {
    runApp(MechanicaApp(controller: await bootstrap(cloudEnabled: true)));
  } catch (error, stack) {
    debugPrint('$error\n$stack');
    runApp(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xff101820),
          body: Center(
            child: Text(
              'Không tải được dữ liệu Mechanica.\nHãy cài lại bản game đầy đủ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingApp extends StatelessWidget {
  const LoadingApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const Scaffold(
      backgroundColor: Color(0xff0a1116),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MECHANICA',
              style: TextStyle(
                fontFamily: 'NotoSerif',
                fontSize: 36,
                letterSpacing: 8,
                color: Color(0xffe1ac60),
              ),
            ),
            SizedBox(height: 20),
            Text('Đang đánh thức cỗ máy…'),
          ],
        ),
      ),
    ),
  );
}
