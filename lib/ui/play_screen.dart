import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app/controller.dart';
import '../game/mechanica_game.dart';
import '../game/puzzles/model.dart';
import '../game/rendering/drawing.dart';
import 'settings.dart';
import 'widgets.dart';
import 'room_ui.dart';
import 'developer_menu.dart';
import 'guidance_overlay.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.controller});
  final GameController controller;
  @override
  State<PlayScreen> createState() => PlayScreenState();
}

class PlayScreenState extends State<PlayScreen> {
  late MechanicaGame game;
  final GlobalKey gameKey = GlobalKey();
  bool toolsVisible = true;
  GameController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    game = MechanicaGame(
      c,
      onInspect: () => _note(),
      onHotspot: (h) => showRoomHotspot(context, c, h),
    );
  }

  void _note() {
    c.running = false;
    unawaited(showJournal(context, c));
  }

  void _dropItem(String id, Offset global) {
    if (c.zoom || c.paused) return;
    final box = gameKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(global),
        scale = math.min(box.size.width / 1280, box.size.height / 720);
    final x = (local.dx - (box.size.width - 1280 * scale) / 2) / scale;
    final y = (local.dy - (box.size.height - 720 * scale) / 2) / scale;
    for (final h in c.session!.definition.room!.hotspots) {
      if (h.contains(x, y)) {
        c.selectItem(id);
        c.useSelectedItem(h.id);
        return;
      }
    }
  }

  @override
  void dispose() {
    game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = c.session!, l = s.definition, accent = chapterColors[l.chapter];
    if (c.paused) {
      game.pauseEngine();
    } else if (game.paused) {
      game.resumeEngine();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        GameWidget(
          key: gameKey,
          game: game,
          loadingBuilder: (_) => const Center(child: Text('Đang mở cánh cửa…')),
          errorBuilder: (_, error) => Center(
            child: GamePanel(
              child: Text('Không tải được căn phòng. Hãy quay lại và thử lại.'),
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xe50a1219),
              border: Border(
                bottom: BorderSide(color: accent.withValues(alpha: .5)),
              ),
            ),
            child: Row(
              children: [
                MetalButton(
                  c.zoom ? 'Căn phòng' : 'Tạm dừng',
                  compact: true,
                  icon: c.zoom ? Icons.zoom_out : Icons.pause,
                  onPressed: () => c.zoom ? c.setZoom(false) : c.pause(),
                  accent: accent,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l.number.toString().padLeft(2, '0')}  ${l.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'NotoSerif',
                          fontSize: 18,
                          color: accent,
                        ),
                      ),
                      Text(
                        l.goal,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: cream, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${s.state.moves} lượt · ${s.state.ticks} nhịp',
                      style: const TextStyle(fontSize: 11, color: cream),
                    ),
                    Text(
                      '${l.objectives.where((o) => o.met(s.state)).length}/${l.objectives.length} điều kiện',
                      style: TextStyle(fontSize: 10, color: accent),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                MetalButton(
                  'Ⅱ',
                  compact: true,
                  onPressed: c.pause,
                  accent: accent,
                ),
                const SizedBox(width: 6),
                MetalButton(
                  toolsVisible ? 'Ẩn nút' : 'Công cụ',
                  compact: true,
                  onPressed: () => setState(() => toolsVisible = !toolsVisible),
                ),
                if (c.isDeveloper) ...[
                  const SizedBox(width: 6),
                  MetalButton(
                    'Thử',
                    compact: true,
                    onPressed: () => showDeveloperMenu(context, c),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (toolsVisible)
          Positioned(
            left: 14,
            right: 14,
            bottom: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xdd0a131b),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    c.message,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          c.latestEvents.any(
                            (e) => e.kind == 'failure' || e.kind == 'rejected',
                          )
                          ? const Color(0xffffa68d)
                          : cream,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    if (!c.zoom)
                      MetalButton(
                        'Túi đồ',
                        compact: true,
                        icon: Icons.inventory_2_outlined,
                        onPressed: c.toggleInventory,
                        accent: accent,
                      ),
                    MetalButton(
                      'Nhật ký',
                      compact: true,
                      icon: Icons.menu_book_outlined,
                      onPressed: _note,
                      accent: accent,
                    ),
                    const SizedBox(width: 8),
                    MetalButton(
                      'Hoàn tác',
                      compact: true,
                      onPressed: s.history.isEmpty || s.state.won
                          ? null
                          : c.undo,
                      accent: accent,
                    ),
                    const SizedBox(width: 8),
                    MetalButton(
                      'Đặt lại',
                      compact: true,
                      onPressed: () async {
                        c.running = false;
                        if (await confirm(
                          context,
                          'Đặt lại cỗ máy?',
                          'Cấu hình hiện tại sẽ trở về ban đầu. Tiến trình các màn đã hoàn thành vẫn được giữ.',
                        )) {
                          c.reset();
                        }
                      },
                      accent: accent,
                    ),
                    const SizedBox(width: 8),
                    if (c.zoom && l.number == 12) ...[
                      MetalButton(
                        [
                          'Toàn bộ',
                          'Cơ khí',
                          'Thủy áp',
                          'Quang học',
                        ][c.machineFocus + 1],
                        compact: true,
                        icon: Icons.center_focus_strong,
                        onPressed: c.cycleFocus,
                        accent: accent,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (c.zoom && l.control('ACT_STEP') != null) ...[
                      if (l.number >= 10) ...[
                        MetalButton(
                          'Một nhịp',
                          compact: true,
                          onPressed: () => c.act(PuzzleAction.tick),
                          accent: accent,
                        ),
                        const SizedBox(width: 8),
                      ],
                      MetalButton(
                        c.running ? 'Dừng' : 'Chạy',
                        compact: true,
                        icon: c.running ? Icons.pause : Icons.play_arrow,
                        onPressed: c.toggleRun,
                        accent: accent,
                      ),
                      const SizedBox(width: 8),
                    ],
                    MetalButton(
                      c.assistanceBusy ? 'Đang tìm bước…' : 'Chỉ tôi cách làm',
                      compact: true,
                      onPressed: c.assistanceBusy ? null : c.requestAssistance,
                      accent: accent,
                    ),
                    MetalButton(
                      'Gợi ý · ${s.hintsUsed.clamp(0, 3)}/3',
                      compact: true,
                      icon: Icons.lightbulb_outline,
                      onPressed: () async {
                        c.running = false;
                        if (await confirm(
                          context,
                          'Mở gợi ý tiếp theo?',
                          'Gợi ý giúp định hướng và được tính trong kết quả sao. Bạn vẫn luôn mở màn kế tiếp khi hoàn thành.',
                        )) {
                          if (context.mounted) {
                            unawaited(showReading(context, 'Gợi ý', c.hint()));
                          }
                        }
                      },
                      accent: accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (c.currentGuide != null && !c.paused && !c.showResult)
          GuidanceOverlay(c),
        if (c.tutorial != null &&
            c.currentGuide == null &&
            !c.paused &&
            !c.showResult &&
            !c.inventoryOpen)
          Positioned(
            left: 18,
            right: 18,
            top: 90,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 640),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xf2101a22),
                  border: Border.all(color: accent.withValues(alpha: .6)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.tutorial!,
                        style: const TextStyle(fontSize: 12, color: cream),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MetalButton(
                      'Đã rõ',
                      compact: true,
                      onPressed: c.dismissTutorial,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (c.inventoryOpen && !c.paused && !c.zoom)
          Positioned(
            left: 18,
            bottom: 76,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width - 36,
                maxHeight: MediaQuery.sizeOf(context).height - 160,
              ),
              child: SingleChildScrollView(
                child: InventoryPanel(c, onDrop: _dropItem),
              ),
            ),
          ),
        if (c.paused)
          ColoredBox(
            color: const Color(0xb9000000),
            child: Center(
              child: GamePanel(
                width: 470,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Cỗ máy đang nghỉ',
                      style: TextStyle(
                        fontFamily: 'NotoSerif',
                        fontSize: 26,
                        color: gold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Máy đã dừng. Hành trình của bạn đã được lưu.',
                      style: TextStyle(fontSize: 12, color: cream),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        MetalButton(
                          'Hướng dẫn màn đầu',
                          onPressed: () {
                            c.resume();
                            c.replayOnboarding();
                          },
                        ),
                        MetalButton(
                          'Tiếp tục',
                          primary: true,
                          onPressed: c.resume,
                        ),
                        MetalButton(
                          'Cài đặt',
                          onPressed: () => showSettings(context, c),
                        ),
                        MetalButton(
                          'Về chương',
                          onPressed: () {
                            c.resume();
                            c.navigate(AppPage.levels);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (c.showResult)
          ColoredBox(
            color: const Color(0x9b000000),
            child: Center(
              child: GamePanel(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.number % 3 == 0
                            ? 'KÝ ỨC ĐƯỢC ĐÁNH THỨC'
                            : 'CÁNH CỬA ĐÃ MỞ',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'NotoSerif',
                          fontSize: 26,
                          color: cream,
                        ),
                      ),
                      const SizedBox(height: 12),
                      stars(s.stars, size: 32, color: accent),
                      const SizedBox(height: 12),
                      Text(
                        l.completion,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: cream,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${s.state.moves} lượt · ${s.state.errors} lỗi · ${s.hintsUsed} gợi ý',
                        style: TextStyle(color: accent, fontSize: 12),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          MetalButton('Chơi lại', onPressed: c.reset),
                          MetalButton(
                            l.number == 12
                                ? 'Xem kết thúc'
                                : 'Cánh cửa tiếp theo',
                            primary: true,
                            onPressed: () => l.number == 12
                                ? c.navigate(AppPage.ending)
                                : c.start(l.number),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
