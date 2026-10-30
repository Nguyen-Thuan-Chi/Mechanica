import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/controller.dart';
import 'widgets.dart';

Future<void> showDeveloperMenu(BuildContext context, GameController c) async {
  if (!kDebugMode) return;
  if (!c.isDeveloper) await c.setDeveloper(true);
  if (!context.mounted) return;
  c.running = false;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AnimatedBuilder(
      animation: c,
      builder: (ctx, _) => Dialog(
        backgroundColor: Colors.transparent,
        child: GamePanel(
          width: 750,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phòng thử máy · bản phát triển',
                  style: TextStyle(
                    fontFamily: 'NotoSerif',
                    fontSize: 23,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cả 12 màn được truy cập tự do. Dữ liệu thử nằm riêng; không mở khóa hay ghi sao vào hành trình người chơi.',
                  style: TextStyle(color: cream, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final l in c.levels)
                      MetalButton(
                        '${l.number.toString().padLeft(2, '0')} · ${l.title}',
                        compact: true,
                        key: ValueKey('dev_level_${l.number}'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          c.developerJump(l.number - 1);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (c.session != null) ...[
                  Text(
                    'Màn ${c.session!.definition.number} · ${c.session!.state.won ? 'Đã thắng' : 'Đang chơi'} · ${c.session!.state.errors} lỗi',
                    style: const TextStyle(color: gold),
                  ),
                  for (final o in c.session!.definition.objectives)
                    Text(
                      '${o.met(c.session!.state) ? '✓' : '○'} ${o.label}',
                      style: const TextStyle(color: cream, fontSize: 12),
                    ),
                  ExpansionTile(
                    title: const Text(
                      'Giá trị trạng thái',
                      style: TextStyle(color: cream),
                    ),
                    children: [
                      SelectableText(
                        c.session!.state.values.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join(' · '),
                        style: const TextStyle(color: cream, fontSize: 11),
                      ),
                    ],
                  ),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MetalButton(
                      'Thử tutorial từ đầu',
                      compact: true,
                      onPressed: () {
                        Navigator.pop(ctx);
                        c.developerJump(0);
                        c.store.tutorials.removeWhere(
                          (f) => f.startsWith('v3_'),
                        );
                        c.replayOnboarding();
                      },
                    ),
                    MetalButton(
                      'Giả lập đã học xong',
                      compact: true,
                      onPressed: () {
                        c.developerTutorialCompleted();
                      },
                    ),
                    Text(
                      c.cloud.status,
                      style: const TextStyle(color: gold, fontSize: 12),
                    ),
                    if (c.session != null)
                      MetalButton(
                        'Đặt lại máy',
                        compact: true,
                        onPressed: c.reset,
                      ),
                    if (c.session != null)
                      MetalButton(
                        'Hoàn tác thử',
                        compact: true,
                        onPressed: c.undo,
                      ),
                    MetalButton(
                      c.showHotspots ? 'Ẩn vùng chạm' : 'Hiện vùng chạm',
                      compact: true,
                      onPressed: c.developerHotspots,
                    ),
                    MetalButton(
                      'Xóa dữ liệu thử',
                      compact: true,
                      onPressed: () async {
                        if (await confirm(
                          ctx,
                          'Xóa dữ liệu thử?',
                          'Chỉ dữ liệu của phòng thử máy bị xóa. Hành trình thường vẫn được giữ.',
                        )) {
                          await c.developerResetSave();
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                    ),
                    MetalButton(
                      'Về hành trình thật',
                      compact: true,
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await c.setDeveloper(false);
                      },
                    ),
                    MetalButton(
                      'Đóng',
                      compact: true,
                      primary: true,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
