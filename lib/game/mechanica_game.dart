import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/cache.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app/controller.dart';
import 'puzzles/model.dart';
import 'puzzles/reducer.dart';
import 'rendering/drawing.dart';
import 'mechanics/device_motion.dart';

class MechanicaGame extends FlameGame {
  MechanicaGame(
    this.controller, {
    required this.onInspect,
    this.onHotspot,
    Images? imagesCache,
  }) : session = controller.session!,
       super(
         camera: CameraComponent.withFixedResolution(width: 1280, height: 720),
       ) {
    images = imagesCache ?? Images();
  }
  final GameController controller;
  final PuzzleSession session;
  final VoidCallback onInspect;
  final void Function(RoomHotspot)? onHotspot;
  late RoomScene room;
  String? assetError;
  bool initialized = false;
  double simulationClock = 0;
  Future<Sprite> loadArt(String path) async {
    if (images.containsKey(path)) return Sprite(images.fromCache(path));
    // Decode before inserting into Flame's cache. Its pending-image cache
    // attaches a second Future without an error handler on failed loads.
    final bytes = await images.bundle.load('${images.prefix}$path');
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    try {
      final frame = await codec.getNextFrame();
      images.add(path, frame.image);
      return Sprite(frame.image);
    } finally {
      codec.dispose();
    }
  }

  @override
  void onDispose() {
    // Each room owns its textures; switching chapters releases the old cache.
    images.clearCache();
    super.onDispose();
  }

  @override
  Color backgroundColor() => const Color(0xff080e13);
  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    room = RoomScene(this);
    await world.add(room);
    initialized = true;
  }

  @override
  void update(double dt) {
    // A scene can receive one last frame while Flutter removes its widget.
    if (!identical(controller.session, session) ||
        controller.page != AppPage.play) {
      return;
    }
    super.update(dt.clamp(0, .05));
    if (controller.running && !controller.paused && controller.zoom) {
      simulationClock += dt;
      if (simulationClock >= .85) {
        simulationClock = 0;
        controller.act(PuzzleAction.tick);
      }
    } else {
      simulationClock = 0;
    }
  }

  Offset worldPoint(Offset p) => Offset(
    p.dx * size.x / 1280 + (size.x - 1280 * (size.x / 1280)) / 2,
    p.dy * size.x / 1280,
  );
}

class RoomScene extends PositionComponent with TapCallbacks {
  RoomScene(this.game) : super(size: Vector2(1280, 720));
  final MechanicaGame game;
  GameController get ctrl => game.controller;
  PuzzleDefinition get level => game.session.definition;
  PuzzleState get state => game.session.state;
  late Sprite background;
  final List<Sprite> art = [];
  final Map<String, Sprite> deviceArt = {};
  final Map<String, Sprite> roomArt = {};
  late MachineAssembly machine;
  double time = 0, zoom = 0, door = 0;
  double alarm = 0, flowTime = 0;
  double drawer = 0, installed = 0, repairFlash = 0;
  int seenRevision = -1;
  bool _sent = false;
  @override
  Future<void> onLoad() async {
    try {
      background = await game.loadArt('chapters/${level.biome}/room.png');
      for (var k = 0; k < 4; k++) {
        art.add(await game.loadArt('chapters/${level.biome}/prop$k.png'));
      }
      deviceArt['gear'] = await game.loadArt('chapters/brass/prop0.png');
      deviceArt['valve'] = await game.loadArt('chapters/water/prop0.png');
      deviceArt['mirror'] = await game.loadArt('chapters/prism/prop0.png');
      for (final h in level.room?.hotspots ?? <RoomHotspot>[]) {
        if (h.image.isNotEmpty) {
          roomArt[h.id] = await game.loadArt(
            roomAsset(h.image).replaceFirst('assets/images/', ''),
          );
        }
      }
    } catch (e) {
      art.clear();
      game.assetError =
          'Không tải được hình ảnh của khu vực. Hãy cài lại bản đầy đủ.';
    }
    machine = MachineAssembly(this);
    await add(machine);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (ctrl.paused) return;
    time += dt;
    alarm = math.max(0, alarm - dt);
    flowTime = math.max(0, flowTime - dt);
    repairFlash = math.max(0, repairFlash - dt);
    drawer += (state['cabinetOpen'] - drawer) * math.min(1, dt * 6);
    installed += (state['repairReady'] - installed) * math.min(1, dt * 5);
    if (seenRevision != ctrl.revision) {
      seenRevision = ctrl.revision;
      if (ctrl.latestEvents.any(
        (e) => e.kind == 'failure' || e.kind == 'rejected',
      )) {
        alarm = 1.4;
      }
      if (ctrl.latestEvents.any((e) => e.kind == 'flow')) flowTime = .9;
      if (ctrl.latestEvents.any((e) => e.kind == 'room_repair')) {
        repairFlash = 2;
      }
    }
    final reduced = ctrl.store.settings.reducedMotion;
    final target = ctrl.zoom ? 1.0 : 0.0;
    zoom += (target - zoom) * math.min(1, dt * (reduced ? 30 : 5));
    final focused = ctrl.zoom && ctrl.machineFocus >= 0;
    final scale = .60 + (focused ? .50 : .30) * zoom;
    machine.scale = Vector2.all(scale);
    final focusX = focused ? [145.0, 425.0, 785.0][ctrl.machineFocus] : 500.0;
    final targetPosition = Vector2(640 - focusX * scale, 330 - 230 * scale);
    machine.position +=
        (targetPosition - machine.position) *
        math.min(1, dt * (reduced ? 30 : 7));
    if (state.won) {
      door = math.min(1, door + dt / (reduced ? 0.5 : 3.8));
      if (door >= 1 && !_sent) {
        _sent = true;
        scheduleMicrotask(ctrl.resultReady);
      }
    } else {
      door = 0;
      _sent = false;
    }
  }

  @override
  void render(Canvas canvas) {
    final c = canvas;
    if (art.isEmpty) {
      c.drawRect(
        const Rect.fromLTWH(0, 0, 1280, 720),
        Paint()..color = const Color(0xff101a20),
      );
      textAt(
        c,
        game.assetError ?? 'Đang đánh thức cỗ máy…',
        const Offset(640, 360),
        size: 24,
      );
      return;
    }
    final reduced = ctrl.store.settings.reducedMotion;
    c.save();
    final drift = reduced ? 0.0 : math.sin(time * .13) * 3;
    background.render(
      c,
      position: Vector2(-8 + drift, -5),
      size: Vector2(1296, 730),
    );
    c.restore();
    c.drawRect(
      const Rect.fromLTWH(0, 0, 1280, 720),
      Paint()..color = Color.fromRGBO(3, 8, 12, .10 + zoom * .22),
    );
    final accent = chapterColors[level.chapter];
    // Four independently composited props, not baked into the room painting.
    art[2].render(c, position: Vector2(5, 455), size: Vector2(230, 230));
    art[1].render(c, position: Vector2(1030, 330), size: Vector2(210, 300));
    art[3].render(c, position: Vector2(30, 80), size: Vector2(155, 200));
    art[3].render(c, position: Vector2(1100, 85), size: Vector2(150, 200));
    glow(
      c,
      const Offset(110, 205),
      100,
      accent,
      strength: .13 + (reduced ? 0 : math.sin(time * 1.4) * .02),
    );
    // Ambient particles are bounded and generated analytically, no allocation growth.
    if (!reduced) {
      for (var i = 0; i < 22; i++) {
        final x = (i * 61.0 + math.sin(time * .3 + i) * 16) % 1280;
        final y = (i * 93.0 - time * (level.chapter == 1 ? 13 : 4)) % 720;
        c.drawCircle(
          Offset(x, y),
          level.chapter == 1 ? 2.3 : 1.2,
          Paint()
            ..color = accent.withValues(alpha: .16 + (i % 4) * .035)
            ..style = level.chapter == 1
                ? PaintingStyle.stroke
                : PaintingStyle.fill,
        );
      }
    }
    if (!ctrl.zoom && level.room != null) {
      _renderExploration(c);
    } else if (!ctrl.zoom) {
      metalPanel(c, const Rect.fromLTWH(100, 518, 255, 102), accent);
      textAt(
        c,
        'BẢN KHẮC KỸ SƯ',
        const Offset(227, 548),
        size: 18,
        color: accent,
        serif: true,
      );
      textAt(
        c,
        state['inspected'] == 1 ? 'Chạm để đọc lại' : 'Chạm để khám phá',
        const Offset(227, 582),
        size: 15,
      );
      if (state['inspected'] == 0) {
        glow(c, const Offset(227, 560), 140, accent, strength: .13);
      }
      metalPanel(
        c,
        const Rect.fromLTWH(510, 559, 260, 56),
        accent,
        rivets: false,
      );
      textAt(
        c,
        'TIẾP CẬN CƠ CẤU',
        const Offset(640, 588),
        size: 18,
        color: accent,
      );
    }
    if (door > 0) {
      final r = Rect.fromLTWH(1020, 225, 150, 360);
      glow(c, r.center, 130 * door, accent, strength: .6 * door);
      c.drawRect(r, Paint()..color = accent.withValues(alpha: .5 * door));
      c.save();
      c.clipRect(r);
      metalPanel(c, r.shift(Offset(-r.width * .52 * door, 0)), accent);
      metalPanel(c, r.shift(Offset(r.width * .52 * door, 0)), accent);
      c.restore();
      if (level.number == 12) {
        for (var i = 0; i < 4; i++) {
          glow(
            c,
            Offset(350 + i * 190, 350),
            140 * door,
            chapterColors[i],
            strength: .4 * door,
          );
        }
        textAt(
          c,
          'KHU VƯỜN ĐANG THỨC DẬY',
          const Offset(640, 95),
          size: 25,
          serif: true,
          color: const Color(0xffffe7b1),
        );
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final e = event;
    if (ctrl.paused || ctrl.zoom || state.won) return;
    final p = e.localPosition;
    if (level.room != null) {
      for (final h in level.room!.hotspots) {
        if (h.contains(p.x, p.y)) {
          if (ctrl.heldItem != null && h.kind != 'machine') {
            ctrl.useSelectedItem(h.id);
            return;
          }
          if (h.kind == 'machine') {
            ctrl.setZoom(true);
            return;
          }
          game.onHotspot?.call(h);
          return;
        }
      }
      return;
    }
    if (p.x >= 80 && p.x <= 380 && p.y >= 500) {
      ctrl.inspect();
      game.onInspect();
    } else if (p.x > 340 && p.x < 960 && p.y > 170 && p.y < 640) {
      if (state['inspected'] == 0) {
        ctrl.inspect();
        game.onInspect();
      } else {
        ctrl.setZoom(true);
      }
    }
  }

  void _renderExploration(Canvas c) {
    final accent = chapterColors[level.chapter];
    for (final h in level.room!.hotspots) {
      final r = Rect.fromLTWH(h.rect[0], h.rect[1], h.rect[2], h.rect[3]);
      if (!ctrl.zoom && ctrl.guideTarget == h.id) {
        final opacity = .6 + .3 * math.sin(time * 3).abs();
        c.drawRRect(
          RRect.fromRectAndRadius(r.inflate(8), const Radius.circular(12)),
          Paint()
            ..color = const Color(0xffffd780).withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6,
        );
        textAt(
          c,
          '↓ CHẠM VÀO ĐÂY',
          Offset(r.center.dx, r.top - 20),
          size: 19,
          color: const Color(0xffffdf99),
        );
      }
      if (h.kind == 'machine') {
        if (ctrl.isDeveloper && ctrl.showHotspots) {
          c.drawRect(r, Paint()..color = const Color(0x3333ff66));
        }
        continue;
      }
      final collected =
          h.kind == 'aux' && level.room!.combine && state['itemB'] > 0;
      final offset = h.kind == 'cabinet'
          ? drawer * 14
          : h.kind == 'repair'
          ? (1 - installed) * 7
          : 0.0;
      if (h.kind == 'cabinet' && drawer > .1) {
        c.drawRRect(
          RRect.fromRectAndRadius(r.deflate(20), const Radius.circular(5)),
          Paint()..color = Colors.black,
        );
      }
      roomArt[h.id]?.render(
        c,
        position: Vector2(r.left, r.top + offset),
        size: Vector2(r.width, r.height),
        overridePaint: Paint()
          ..color = Color.fromRGBO(255, 255, 255, collected ? .22 : 1),
      );
      if (h.kind == 'repair') {
        glow(
          c,
          r.center,
          65,
          installed > .8 ? const Color(0xff8af5b0) : accent,
          strength: .1 + repairFlash * .1,
        );
        if (installed < .8 && level.chapter == 1) {
          for (var i = 0; i < 5; i++) {
            c.drawCircle(
              Offset(
                r.center.dx + math.sin(i * 2.0) * 20,
                r.bottom - 25 + (time * 55 + i * 17) % 45,
              ),
              2,
              Paint()..color = accent.withValues(alpha: .5),
            );
          }
        }
      }
      final label = h.kind == 'repair' && state['repairReady'] == 1
          ? 'Đã sửa · ${h.title}'
          : collected
          ? 'Đã lấy bộ phận'
          : h.title;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(r.center.dx, r.bottom + 4),
            width: r.width + 20,
            height: 30,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xdc0b141b),
      );
      textAt(
        c,
        label,
        Offset(r.center.dx, r.bottom + 4),
        size: 14,
        width: r.width + 12,
        color: accent,
      );
      if (ctrl.isDeveloper && ctrl.showHotspots) {
        c.drawRect(
          r,
          Paint()
            ..color = const Color(0xff44ff99)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        textAt(
          c,
          h.id,
          Offset(r.center.dx, r.top),
          size: 13,
          color: const Color(0xff44ff99),
        );
      }
    }
  }
}

class MachineAssembly extends PositionComponent {
  MachineAssembly(this.room) : super(size: Vector2(1000, 460));
  final RoomScene room;
  GameController get ctrl => room.ctrl;
  PuzzleDefinition get level => room.level;
  PuzzleState get state => room.state;
  final List<InteractiveDevice> devices = [];
  final Map<String, double> displayed = {};
  Color get accent => chapterColors[level.chapter];
  Rect get opticalRect => level.chapter == 2
      ? const Rect.fromLTWH(70, 35, 820, 345)
      : const Rect.fromLTWH(665, 100, 270, 240);
  Offset opticalPoint(int x, int y) => Offset(
    opticalRect.left + x * opticalRect.width / 10,
    opticalRect.top + y * opticalRect.height / 6,
  );
  Offset controlPoint(ControlDefinition control) {
    if (level.optics != null && ['mirror', 'filter'].contains(control.kind)) {
      for (final n in array(level.optics!['nodes']).map(object)) {
        if (n['field'] == control.field) {
          return opticalPoint(n['x']! as int, n['y']! as int);
        }
      }
    }
    // Core has separate mechanical / coolant / optical stations, with a shared
    // simulation lever and visible cross-system indicators.
    if (level.number >= 11) {
      final positions = level.number == 11
          ? <String, Offset>{
              'ACT_GEAR': const Offset(140, 155),
              'ACT_MECH': const Offset(140, 340),
              'ACT_PUMP': const Offset(420, 220),
              'ACT_STEP': const Offset(420, 370),
              'ACT_HYDRO': const Offset(420, 370),
              'ACT_LIGHT': const Offset(680, 370),
              'ACT_LOCK': const Offset(900, 370),
            }
          : <String, Offset>{
              'ACT_GEAR': const Offset(120, 110),
              'ACT_CALIBRATE': const Offset(120, 350),
              'ACT_VALVE': const Offset(410, 140),
              'ACT_PUMP': const Offset(320, 350),
              'ACT_POWER': const Offset(510, 350),
              'ACT_SHUTTER': const Offset(650, 75),
              'ACT_LIGHT': const Offset(660, 350),
              'ACT_ARM': const Offset(860, 75),
              'ACT_STEP': const Offset(410, 420),
              'ACT_LOCK': const Offset(875, 410),
            };
      if (positions.containsKey(control.id)) return positions[control.id]!;
    }
    return Offset(control.x * 1000, control.y * 460);
  }

  @override
  Future<void> onLoad() async {
    for (final control in level.controls) {
      if (control.isRoomAction) continue;
      if (level.number >= 10 && control.id == 'ACT_STEP') continue;
      final device = InteractiveDevice(this, control)
        ..position = controlPoint(control).toVector2();
      devices.add(device);
      await add(device);
    }
    if (level.number == 1) {
      await add(TrayGear(this, 2, Vector2(70, 53)));
      await add(TrayGear(this, 1, Vector2(140, 53)));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (ctrl.paused) return;
    for (final e in state.values.entries) {
      displayed[e.key] =
          (displayed[e.key] ?? e.value.toDouble()) +
          (e.value - (displayed[e.key] ?? e.value.toDouble())) *
              math.min(1, dt * 7);
    }
  }

  double value(String key) => displayed[key] ?? state[key].toDouble();
  @override
  void render(Canvas canvas) {
    final c = canvas;
    if (room.art.isEmpty) return;
    metalPanel(c, const Rect.fromLTWH(-10, -15, 1020, 490), accent, radius: 22);
    // Reuse the painted room's central material, not its machinery or controls.
    // This gives the mounting surface actual patina while every moving part
    // remains an independent component.
    c.save();
    c.clipRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, -5, 1000, 470),
        const Radius.circular(18),
      ),
    );
    final image = room.background.image;
    c.drawImageRect(
      image,
      Rect.fromLTWH(
        image.width * .36,
        image.height * .27,
        image.width * .28,
        image.height * .40,
      ),
      const Rect.fromLTWH(0, -5, 1000, 470),
      Paint()..color = const Color(0xbfffffff),
    );
    c.drawRect(
      const Rect.fromLTWH(0, -5, 1000, 470),
      Paint()..color = const Color(0x69080d15),
    );
    c.restore();
    if (level.chapter == 0) {
      for (final y in [198.0, 300.0]) {
        pipe(c, [Offset(30, y), Offset(970, y)], accent, width: 5);
      }
    } else if (level.chapter == 2) {
      for (final radius in [110.0, 195.0, 285.0]) {
        c.drawCircle(
          const Offset(500, 230),
          radius,
          Paint()
            ..color = accent.withValues(alpha: .12)
            ..style = PaintingStyle.stroke,
        );
      }
    }
    if (level.chapter == 0) _mechanical(c);
    if (level.chapter == 1) _hydraulic(c);
    if (level.optics != null) _optical(c);
    if (level.chapter == 3) _reactor(c);
    for (final gauge in level.gauges) {
      _gauge(c, gauge);
    }
    if (state['jam'] == 1 || room.alarm > 0 && room.time % .4 < .2) {
      glow(c, const Offset(967, 20), 24, const Color(0xffff593d), strength: .6);
    }
    if (level.number == 1) {
      metalPanel(
        c,
        const Rect.fromLTWH(25, 10, 150, 85),
        accent,
        rivets: false,
      );
      room.art[0].render(c, position: Vector2(38, 20), size: Vector2(64, 64));
      room.art[0].render(c, position: Vector2(105, 31), size: Vector2(45, 45));
      textAt(
        c,
        'KÉO VÀO CHỐT',
        const Offset(100, 106),
        size: 13,
        color: accent,
      );
      if (state['gearA'] == 0 && state.moves == 0 && room.ctrl.zoom) {
        final t = room.ctrl.store.settings.reducedMotion
            ? .55
            : (room.time / 2.5) % 1;
        final p = Offset.lerp(const Offset(70, 53), const Offset(300, 198), t)!;
        c.drawCircle(p, 13, Paint()..color = accent.withValues(alpha: .18));
        c.drawCircle(
          p,
          9,
          Paint()
            ..color = accent.withValues(alpha: .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _mechanical(Canvas c) {
    if (level.number == 1) {
      final points = [
        const Offset(120, 205),
        const Offset(300, 198),
        const Offset(540, 198),
        const Offset(780, 198),
      ];
      pipe(
        c,
        points,
        accent,
        active: state['powered'] == 1,
        time: room.time,
        width: 10,
      );
      // The intermediate wheel performs the second reversal in the real
      // tooth-ratio graph. Its teeth bridge the two removable wheels.
      c.save();
      c.translate(420, 198);
      if (state['powered'] == 1) c.rotate(-room.time * 2);
      room.art[0].render(c, position: Vector2(-47, -47), size: Vector2.all(94));
      c.restore();
      for (final x in [120.0, 780.0]) {
        c.save();
        c.translate(x, 198);
        if (state['powered'] == 1) {
          c.rotate(room.time * (state['direction'] == -1 ? -1 : 1));
        }
        room.art[0].render(
          c,
          position: Vector2(-70, -70),
          size: Vector2(140, 140),
        );
        c.restore();
      }
    } else if (level.number == 2) {
      for (final x in [250.0, 500.0, 750.0]) {
        pipe(
          c,
          [const Offset(500, 300), Offset(x, 300), Offset(x, 140)],
          accent,
          active: state['powered'] == 1,
          time: room.time,
        );
      }
    } else {
      room.art[1].render(
        c,
        position: Vector2(
          25,
          45 + math.sin(room.time * 6) * (state['powered'] == 1 ? 6 : 0),
        ),
        size: Vector2(200, 290),
      );
      pipe(
        c,
        [
          const Offset(250, 250),
          const Offset(430, 250),
          const Offset(430, 120),
          const Offset(660, 120),
          const Offset(660, 250),
        ],
        accent,
        active: state['pressure'] > 0,
        time: room.time,
      );
      if (state['steam'] > 0 && !ctrl.store.settings.reducedMotion) {
        for (var i = 0; i < 8; i++) {
          final phase = (room.time * .5 + i / 8) % 1;
          glow(
            c,
            Offset(180 + math.sin(i + room.time) * 12, 150 - phase * 100),
            12 + phase * 16,
            Colors.white,
            strength: (1 - phase) * .12,
          );
        }
      }
    }
  }

  void _hydraulic(Canvas c) {
    final gauges = level.gauges.where((g) => g['kind'] == 'tank').toList();
    final points = gauges
        .map(
          (g) => Offset(
            (g['x']! as num).toDouble() * 1000,
            (g['y']! as num).toDouble() * 460 + 82,
          ),
        )
        .toList();
    if (points.length >= 2) {
      for (var i = 0; i < points.length - 1; i++) {
        pipe(
          c,
          [
            points[i],
            Offset(points[i].dx, 290),
            Offset(points[i + 1].dx, 290),
            points[i + 1],
          ],
          accent,
          active: state['flow'] == 1 && room.flowTime > 0,
          time: room.time,
        );
      }
    }
    if (level.number == 5) {
      textAt(
        c,
        'MÀNG LỌC · ${state['charge']} LƯỢT',
        const Offset(610, 210),
        size: 16,
        color: accent,
      );
    }
    if (level.number == 6) {
      textAt(
        c,
        'BỂ THU KÍN · ${state['drain']}',
        const Offset(820, 270),
        size: 17,
        color: accent,
      );
    }
  }

  void _optical(Canvas c) {
    final layout = level.optics!;
    final r = opticalRect;
    if (level.chapter == 2) {
      // Engraved star map, not a debug grid.
      for (var i = 0; i < 25; i++) {
        final p = Offset(
          r.left + (i * 127) % r.width,
          r.top + (i * 71) % r.height,
        );
        c.drawCircle(
          p,
          i % 4 == 0 ? 2 : 1,
          Paint()..color = const Color(0xff777193),
        );
      }
      room.art[2].render(
        c,
        position: Vector2(760, 235),
        size: Vector2(230, 230),
        overridePaint: Paint()..color = const Color(0x77ffffff),
      );
    }
    for (final beam in state.beams) {
      final from = opticalPoint(beam.x1, beam.y1),
          to = opticalPoint(beam.x2, beam.y2);
      final color = switch (beam.color) {
        1 => const Color(0xffff6c6c),
        2 => const Color(0xff85ffad),
        4 => const Color(0xff8daeff),
        _ => const Color(0xffdbf9ff),
      };
      c.drawLine(
        from,
        to,
        Paint()
          ..color = color.withValues(alpha: .25)
          ..strokeWidth = 11
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      c.drawLine(
        from,
        to,
        Paint()
          ..color = color
          ..strokeWidth = beam.power == 2 ? 3.5 : 2,
      );
    }
    for (final node in array(layout['nodes']).map(object)) {
      final p = opticalPoint(node['x']! as int, node['y']! as int);
      switch (node['type']) {
        case 'sensor':
          final on = state[node['field']! as String] == 1;
          c.drawCircle(p, 18, Paint()..color = const Color(0xff756f87));
          c.drawCircle(
            p,
            13,
            Paint()..color = on ? accent : const Color(0xff171a27),
          );
          if (on) glow(c, p, 32, accent, strength: .6);
          final direction = node['direction']! as int;
          textAt(
            c,
            ['→', '↓', '←', '↑'][direction],
            p,
            size: 21,
            color: on ? Colors.white : accent,
          );
          final colorName = switch (node['color']) {
            1 => 'ĐỎ',
            2 => 'LỤC',
            4 => 'LAM',
            _ => 'MẮT',
          };
          textAt(
            c,
            colorName,
            p + const Offset(0, -28),
            size: 12,
            color: accent,
          );
        case 'splitter':
          room.art[1].render(
            c,
            position: (p - const Offset(32, 32)).toVector2(),
            size: Vector2.all(64),
          );
        case 'fragile':
          room.art[1].render(
            c,
            position: (p - const Offset(25, 25)).toVector2(),
            size: Vector2.all(50),
          );
          textAt(
            c,
            'MỎNG · ≤1',
            p + const Offset(0, 35),
            size: 12,
            color: const Color(0xffff9e9e),
          );
        case 'shutter':
          final open = state[node['field']! as String] == 1;
          c.drawLine(
            p - Offset(open ? 18 : 13, open ? 12 : 0),
            p + Offset(open ? 18 : 13, open ? 12 : 0),
            Paint()
              ..color = open ? accent : const Color(0xffef7777)
              ..strokeWidth = 7,
          );
      }
    }
    final emitter = opticalPoint(0, 3);
    c.drawCircle(emitter, 19, Paint()..color = const Color(0xff555668));
    glow(c, emitter, 35, accent, strength: state['light'] == 1 ? 0.6 : .08);
  }

  void _reactor(Canvas c) {
    if (level.number == 10) {
      c.save();
      c.translate(505, 190);
      if (state['powered'] == 1) c.rotate(room.time * .8);
      room.art[0].render(
        c,
        position: Vector2(-145, -145),
        size: Vector2.all(290),
      );
      c.restore();
      glow(
        c,
        const Offset(505, 190),
        75,
        accent,
        strength: state['power'] * .1,
      );
    } else {
      for (final x in [275.0, 585.0]) {
        pipe(c, [Offset(x, 30), Offset(x, 425)], accent, width: 7);
      }
      textAt(c, 'TRUYỀN ĐỘNG', const Offset(145, 15), size: 15, color: accent);
      textAt(c, 'THỦY ÁP', const Offset(425, 15), size: 15, color: accent);
      textAt(c, 'QUANG NĂNG', const Offset(790, 15), size: 15, color: accent);
    }
    pipe(
      c,
      [
        const Offset(120, 220),
        const Offset(120, 430),
        const Offset(560, 430),
        const Offset(560, 210),
      ],
      const Color(0xff8adbd4),
      active: state['cooling'] > 0,
      time: room.time,
    );
  }

  void _gauge(Canvas c, Json g) {
    final field = g['field']! as String;
    var p = Offset(
      (g['x']! as num).toDouble() * 1000,
      (g['y']! as num).toDouble() * 460,
    );
    if (level.number == 11 && field == 'pressure') p = const Offset(420, 130);
    if (level.number == 12) {
      p = switch (field) {
        'pressure' => const Offset(125, 235),
        'heat' => const Offset(525, 60),
        'stable' => const Offset(525, 245),
        _ => p,
      };
    }
    final max = (g['max']! as num).toDouble(), v = value(field);
    if (g['kind'] == 'tank') {
      final rect = Rect.fromCenter(center: p, width: 86, height: 146);
      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        Paint()..color = const Color(0xff142c31),
      );
      c.save();
      c.clipRRect(
        RRect.fromRectAndRadius(rect.deflate(8), const Radius.circular(10)),
      );
      final water = Rect.fromLTRB(
        rect.left + 8,
        rect.bottom - 8 - (rect.height - 16) * (v / max).clamp(0, 1),
        rect.right - 8,
        rect.bottom - 8,
      );
      final dirty = state['${field}Dirty'] == 1 || field == 'dirty';
      c.drawRect(
        water,
        Paint()
          ..color = (dirty ? const Color(0xffa78945) : const Color(0xff39bdbb))
              .withValues(alpha: .75),
      );
      c.drawLine(
        water.topLeft,
        water.topRight,
        Paint()
          ..color = const Color(0xffd1ffff)
          ..strokeWidth = 2,
      );
      if (!ctrl.store.settings.reducedMotion) {
        for (var i = 0; i < 6; i++) {
          final yy =
              water.bottom -
              ((room.time * 18 + i * 21) % math.max(1, water.height));
          c.drawCircle(
            Offset(rect.left + 20 + i * 9, yy),
            2,
            Paint()
              ..color = const Color(0x88bbffff)
              ..style = PaintingStyle.stroke,
          );
        }
      }
      c.restore();
      room.art[1].render(
        c,
        position: Vector2(p.dx - 90, p.dy - 100),
        size: Vector2(180, 200),
      );
      for (var i = 0; i <= max.toInt(); i++) {
        final y = rect.bottom - 8 - i * (130 / max);
        c.drawLine(
          Offset(p.dx - 31, y),
          Offset(p.dx - 21, y),
          Paint()
            ..color = const Color(0xffebeee1)
            ..strokeWidth = 1,
        );
      }
      metalPanel(
        c,
        Rect.fromCenter(
          center: p + const Offset(0, 105),
          width: 140,
          height: 44,
        ),
        accent,
        rivets: false,
        radius: 6,
      );
      textAt(
        c,
        '${g['label']} · ${state[field]}${dirty ? ' !' : ''}',
        p + const Offset(0, 105),
        size: 14,
        width: 135,
      );
    } else {
      dial(
        c,
        p,
        g['kind'] == 'dial' ? 57 : 40,
        v,
        max,
        accent,
        label: g['label']! as String,
        target: (g['target'] as num?)?.toDouble(),
      );
    }
  }
}

extension OffsetVector on Offset {
  Vector2 toVector2() => Vector2(dx, dy);
}

/// A visible component follows the pointer and snaps only onto a real shaft.
/// Tapping a shaft remains an accessible alternative to drag-and-drop.
class TrayGear extends PositionComponent with DragCallbacks {
  TrayGear(this.machine, this.gearSize, this.origin)
    : super(
        position: origin.clone(),
        size: Vector2.all(70),
        anchor: Anchor.center,
        priority: 20,
      );
  final MachineAssembly machine;
  final int gearSize;
  final Vector2 origin;
  bool dragging = false;
  @override
  void render(Canvas canvas) {
    final sprite = machine.room.deviceArt['gear'];
    if (sprite == null) return;
    final side = gearSize == 2 ? 70.0 : 50.0;
    sprite.render(
      canvas,
      position: Vector2.all((70 - side) / 2),
      size: Vector2.all(side),
    );
    if (dragging) {
      glow(canvas, const Offset(35, 35), 50, machine.accent, strength: .25);
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    dragging = machine.ctrl.zoom && !machine.ctrl.paused;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (dragging) position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (dragging) {
      for (final device in machine.devices.where(
        (d) => d.control.id == 'ACT_GEAR_A' || d.control.id == 'ACT_GEAR_B',
      )) {
        if (position.distanceTo(device.position) < 80) {
          final field = device.control.field!;
          var steps = 0;
          while (machine.state[field] != gearSize && steps++ < 3) {
            machine.ctrl.act(PuzzleAction(device.control.id));
          }
          break;
        }
      }
    }
    position = origin.clone();
    dragging = false;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    position = origin.clone();
    dragging = false;
  }
}

class InteractiveDevice extends PositionComponent
    with TapCallbacks, DragCallbacks {
  InteractiveDevice(this.machine, this.control)
    : super(size: Vector2.all(90), anchor: Anchor.center);
  final MachineAssembly machine;
  final ControlDefinition control;
  GameController get ctrl => machine.ctrl;
  PuzzleState get state => machine.state;
  double rotorAngle = 0, press = 0, lastTap = -10;
  final DeviceMotion motion = DeviceMotion();
  int lastValue = -1;
  bool hasSpun = false;
  Vector2? dragOrigin;
  Vector2? dragPoint;
  @override
  bool containsLocalPoint(Vector2 point) =>
      ctrl.zoom && point.distanceTo(Vector2(45, 42)) <= 44;
  @override
  void update(double dt) {
    super.update(dt);
    if (ctrl.paused) return;
    final value = control.field == null ? 0 : state[control.field!];
    if (value != lastValue) {
      lastValue = value;
      hasSpun = false;
      press = 1;
    }
    press = math.max(0, press - dt * 4);
    final moving =
        control.kind == 'gear' &&
        state['powered'] == 1 &&
        machine.level.number != 2;
    if (moving) hasSpun = true;
    motion.update(
      dt,
      driven: moving,
      jammed: state['jam'] == 1,
      overloaded: machine.room.alarm > 0 && state['heat'] >= 8,
      ratio: control.field == 'gearB' ? 2 : 1,
      direction: state['direction'] == -1 ? -1 : 1,
      reduced: ctrl.store.settings.reducedMotion,
    );
    final target = control.kind == 'mirror'
        ? value * math.pi / 2
        : control.kind == 'lever'
        ? (value == 0 ? -.4 : .4)
        : value * math.pi / 2;
    if (control.kind == 'gear' &&
        (hasSpun ||
            moving ||
            motion.velocity != 0 ||
            motion.phase == MotionPhase.blocked)) {
      rotorAngle = motion.angle;
    } else {
      rotorAngle += (target - rotorAngle) * math.min(1, dt * 9);
    }
  }

  @override
  void render(Canvas canvas) {
    if (machine.room.art.isEmpty) return;
    final c = canvas, accent = machine.accent;
    c.save();
    c.translate(45 + motion.shake, 42 + press * 2);
    if (ctrl.zoom && ctrl.guideTarget == control.id) {
      c.drawCircle(
        Offset.zero,
        57,
        Paint()
          ..color = const Color(0xffffd681)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      textAt(
        c,
        '↓ CHẠM',
        const Offset(0, -72),
        size: 16,
        color: const Color(0xffffdf99),
      );
    }
    final enabled = evaluate(control.guard, state.values) != 0;
    final radius = control.kind == 'mirror' ? 27.0 : 38.0;
    glow(c, Offset.zero, radius + 12, Colors.black, strength: .8);
    if (ctrl.zoom) {
      c.drawCircle(
        Offset.zero,
        radius + 3,
        Paint()
          ..color = accent.withValues(alpha: enabled ? 0.7 : .22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    }
    switch (control.kind) {
      case 'gear':
      case 'valve':
        if (control.field != null &&
            state[control.field!] == 0 &&
            control.label.startsWith('Chốt truyền')) {
          c.drawCircle(
            Offset.zero,
            24,
            Paint()..color = const Color(0xff12171b),
          );
          c.drawCircle(
            Offset.zero,
            9,
            Paint()..color = const Color(0xff9f9b81),
          );
          textAt(c, '+', const Offset(0, -1), size: 25, color: accent);
        } else {
          c.save();
          c.rotate(rotorAngle);
          final sprite = machine.room.deviceArt[control.kind]!;
          final size = control.field == 'gearA' && state['gearA'] == 2
              ? 112.0
              : 96.0;
          sprite.render(
            c,
            position: Vector2.all(-size / 2),
            size: Vector2.all(size),
          );
          c.restore();
        }
      case 'mirror':
        // The mount stays fixed; the reflective line rotates independently.
        machine.room.deviceArt['mirror']!.render(
          c,
          position: Vector2.all(-36),
          size: Vector2.all(72),
        );
        c.save();
        c.rotate(rotorAngle);
        c.drawLine(
          const Offset(-18, 18),
          const Offset(18, -18),
          Paint()
            ..color = const Color(0xffdbf9ff)
            ..strokeWidth = 4,
        );
        c.restore();
      case 'filter':
        final v = state[control.field!];
        final col = [
          const Color(0xffeefaff),
          const Color(0xfffb7676),
          const Color(0xff7ee9a2),
          const Color(0xff7da4ff),
        ][v % 4];
        c.drawCircle(Offset.zero, 29, Paint()..color = const Color(0xff7b7380));
        c.drawCircle(
          Offset.zero,
          24,
          Paint()..color = col.withValues(alpha: .7),
        );
        c.drawLine(
          const Offset(-15, -9),
          const Offset(12, -17),
          Paint()
            ..color = const Color(0x99ffffff)
            ..strokeWidth = 3,
        );
      case 'lever':
        metalPanel(
          c,
          const Rect.fromLTWH(-27, -37, 54, 76),
          accent,
          radius: 8,
          rivets: false,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-7, -25, 14, 52),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xff080e10),
        );
        c.save();
        c.rotate(rotorAngle);
        c.drawLine(
          const Offset(0, 18),
          const Offset(0, -22),
          Paint()
            ..color = const Color(0xffb6b9b4)
            ..strokeWidth = 8,
        );
        c.drawCircle(const Offset(0, -22), 12, Paint()..color = accent);
        c.drawCircle(
          const Offset(-3, -25),
          4,
          Paint()..color = const Color(0x66ffffff),
        );
        c.restore();
      case 'shutter':
        metalPanel(c, const Rect.fromLTWH(-30, -26, 60, 52), accent, radius: 6);
        final open = control.field != null && state[control.field!] != 0;
        for (var i = 0; i < 4; i++) {
          c.drawRect(
            Rect.fromLTWH(-22 + i * 12, -17, open ? 3 : 10, 34),
            Paint()..color = const Color(0xffa29c87),
          );
        }
      default:
        c.drawCircle(
          Offset.zero,
          29,
          Paint()
            ..shader = RadialGradient(
              colors: [
                const Color(0xff62676a),
                const Color(0xff20292e),
                accent,
              ],
            ).createShader(const Rect.fromLTWH(-30, -30, 60, 60)),
        );
        c.drawCircle(
          Offset.zero,
          21,
          Paint()..color = accent.withValues(alpha: enabled ? 0.75 : .25),
        );
        textAt(
          c,
          control.id == 'ACT_STEP'
              ? '▷'
              : control.id == 'ACT_LOCK'
              ? '◇'
              : '•',
          Offset.zero,
          size: 24,
          color: const Color(0xff101820),
        );
    }
    final labelWidth = control.kind == 'mirror'
        ? 105.0
        : (control.label.length * 8.0 + 20).clamp(150.0, 184.0);
    final labelY = control.kind == 'mirror' || control.id == 'ACT_BLUE'
        ? 0.0
        : machine.level.chapter <= 1 || machine.level.number == 11
        ? 57.0
        : machine.level.number == 12 &&
              [
                'ACT_CALIBRATE',
                'ACT_PUMP',
                'ACT_POWER',
                'ACT_LIGHT',
              ].contains(control.id)
        ? 57.0
        : position.y > 330
        ? -65.0
        : 57.0;
    final labelX = control.kind == 'mirror'
        ? 85.0
        : control.id == 'ACT_BLUE'
        ? -130.0
        : 0.0;
    c.save();
    c.translate(labelX, 0);
    // Dark engraved nameplates keep Vietnamese glyphs legible over textures.
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, labelY + 8),
          width: labelWidth,
          height: 44,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xe80b1116),
    );
    textAt(
      c,
      control.label,
      Offset(0, labelY),
      size: control.kind == 'mirror' ? 15 : 17,
      width: labelWidth,
      color: enabled ? const Color(0xfff0e4cd) : const Color(0xff888d8e),
    );
    textAt(
      c,
      control.valueLabel(state),
      Offset(0, labelY + 17),
      size: 15,
      width: labelWidth,
      color: accent,
    );
    c.restore();
    c.restore();
  }

  void _activate() {
    if (!ctrl.zoom || ctrl.paused || state.won) return;
    if (machine.room.time - lastTap < .16) return;
    lastTap = machine.room.time;
    press = 1;
    ctrl.act(PuzzleAction(control.id));
  }

  @override
  void onTapUp(TapUpEvent event) => _activate();
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!ctrl.zoom) return;
    dragOrigin = position.clone();
    dragPoint = event.localPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (dragOrigin == null) return;
    dragPoint = event.localEndPosition.clone();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (dragOrigin != null) {
      _activate();
      dragOrigin = null;
      dragPoint = null;
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    dragOrigin = null;
    dragPoint = null;
  }
}
