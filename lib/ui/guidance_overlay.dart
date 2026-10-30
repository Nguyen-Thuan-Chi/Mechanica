import 'package:flutter/material.dart';

import '../app/controller.dart';
import 'widgets.dart';

class GuidanceOverlay extends StatelessWidget {
  const GuidanceOverlay(this.c, {super.key});
  final GameController c;
  @override
  Widget build(BuildContext context) {
    final guide = c.currentGuide;
    if (guide == null) return const SizedBox.shrink();
    final roomTarget = [
      'journal',
      'clue',
      'cabinet',
      'aux',
      'repair',
    ].contains(guide.target);
    var targetX = 300.0;
    if (guide.target.startsWith('ACT_')) {
      targetX = c.session!.definition.control(guide.target)?.x ?? .5;
      targetX = 640 + (targetX * 1000 - 500) * .9;
    } else {
      for (final h in c.session!.definition.room!.hotspots) {
        if (h.id == guide.target) targetX = h.rect[0] + h.rect[2] / 2;
      }
    }
    // Put the coach on the opposite side of the actual target, leaving that
    // device and the footer touch controls available on narrow landscapes.
    return Positioned(
      top: 92,
      left: targetX >= 640 ? 12 : null,
      right: targetX < 640 ? 12 : null,
      child: Container(
        key: const ValueKey('guidance_overlay'),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .34,
          maxHeight: MediaQuery.sizeOf(context).height - 180,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xf70d1b23),
          border: Border.all(color: gold, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.onboardingActive
                    ? 'Cùng sửa cỗ máy đầu tiên'
                    : 'Chỉ tôi cách làm',
                style: const TextStyle(
                  color: gold,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                guide.instruction,
                style: const TextStyle(
                  color: cream,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              Text(
                guide.reason,
                style: const TextStyle(
                  color: Color(0xffc6c2ad),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 8,
                runSpacing: 5,
                children: [
                  if (guide.target == 'intro')
                    MetalButton(
                      'Bắt đầu sửa máy',
                      compact: true,
                      primary: true,
                      onPressed: c.beginOnboarding,
                    ),
                  if (roomTarget && c.zoom)
                    MetalButton(
                      'Về căn phòng',
                      compact: true,
                      onPressed: () => c.setZoom(false),
                    ),
                  if (guide.target.startsWith('ACT_') && !c.zoom)
                    MetalButton(
                      'Đến gần máy',
                      compact: true,
                      onPressed: () => c.setZoom(true),
                    ),
                  if (guide.target == 'inventory' ||
                      (guide.target == 'repair' && c.heldItem == null))
                    MetalButton(
                      'Mở túi đồ',
                      compact: true,
                      onPressed: c.inventoryOpen ? null : c.toggleInventory,
                    ),
                  if (guide.target == 'repair' && c.inventoryOpen)
                    MetalButton(
                      'Cất túi',
                      compact: true,
                      onPressed: c.toggleInventory,
                    ),
                  if (guide.target == 'undo' && c.session!.history.isNotEmpty)
                    MetalButton(
                      'Hoàn tác bước vừa rồi',
                      compact: true,
                      onPressed: () {
                        c.undo();
                        c.requestAssistance();
                      },
                    ),
                  if (c.onboardingActive)
                    MetalButton(
                      'Bỏ qua hướng dẫn',
                      compact: true,
                      onPressed: () async {
                        if (await confirm(
                          context,
                          'Tự khám phá từ đây?',
                          'Bạn có thể mở lại hướng dẫn cỗ máy đầu tiên trong menu tạm dừng.',
                        )) {
                          c.skipOnboarding();
                        }
                      },
                    ),
                  if (!c.onboardingActive)
                    MetalButton(
                      'Đóng chỉ dẫn',
                      compact: true,
                      onPressed: c.closeAssistance,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
