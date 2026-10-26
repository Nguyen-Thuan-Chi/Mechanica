import 'dart:async';

import 'package:flutter/material.dart';

import '../app/controller.dart';
import 'menus.dart';
import 'ending_screen.dart';
import 'play_screen.dart';
import 'widgets.dart';

class MechanicaApp extends StatefulWidget {
  const MechanicaApp({super.key, required this.controller});
  final GameController controller;
  @override
  State<MechanicaApp> createState() => _MechanicaAppState();
}

class _MechanicaAppState extends State<MechanicaApp>
    with WidgetsBindingObserver {
  GameController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (c.page == AppPage.play) c.pause();
      unawaited(c.audio.pause());
      unawaited(c.saveNow());
    } else if (!c.paused) {
      unawaited(c.audio.resume());
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mechanica — Bí Ẩn Cỗ Máy Cuối Cùng',
    debugShowCheckedModeBanner: false,
    builder: (context, child) => UiSoundScope(
      onSound: (s) => unawaited(c.audio.effect(s)),
      child: child!,
    ),
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      fontFamily: 'NotoSans',
      colorScheme: const ColorScheme.dark(primary: gold, surface: ink),
      textTheme: const TextTheme(bodyMedium: TextStyle(color: cream)),
    ),
    home: AnimatedBuilder(
      animation: c,
      builder: (context, _) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (c.page == AppPage.play) {
            if (c.inventoryOpen) {
              c.toggleInventory();
            } else if (c.zoom) {
              c.setZoom(false);
            } else {
              c.pause();
            }
          } else if (c.page == AppPage.levels) {
            c.navigate(AppPage.chapters);
          } else {
            c.navigate(AppPage.home);
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: switch (c.page) {
              AppPage.home => HomeScreen(c),
              AppPage.chapters => ChapterScreen(c),
              AppPage.levels => LevelScreen(c),
              AppPage.play => PlayScreen(
                key: ValueKey('${c.session!.definition.id}_${c.sceneSerial}'),
                controller: c,
              ),
              AppPage.ending => EndingScreen(c),
            },
          ),
        ),
      ),
    ),
  );
}
