import 'package:flutter/material.dart';

import '../app/controller.dart';
import '../game/puzzles/model.dart';
import 'widgets.dart';

Future<void> showRoomHotspot(
  BuildContext context,
  GameController c,
  RoomHotspot h,
) async {
  c.running = false;
  final s = c.session!;
  if (h.kind == 'intro' && s.state['inspected'] == 0) c.inspect();
  if (h.kind == 'clue' && s.state['clueFound'] == 0) {
    c.act(const PuzzleAction('ACT_CLUE'));
  }
  await showDialog<void>(
    context: context,
    builder: (ctx) => AnimatedBuilder(
      animation: c,
      builder: (ctx, _) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
        child: GamePanel(
          width: 740,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (h.image.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: Image.asset(
                          roomAsset(h.image),
                          width: 125,
                          height: 125,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.title,
                            style: const TextStyle(
                              fontFamily: 'NotoSerif',
                              fontSize: 23,
                              color: gold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            h.text,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: cream,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (h.kind == 'cabinet' || h.kind == 'repair')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      c.message,
                      style: const TextStyle(fontSize: 13, color: gold),
                    ),
                  ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    if (h.kind == 'cabinet' &&
                        s.definition.room!.locked &&
                        s.state['itemA'] == 0)
                      MetalButton(
                        'Xoay khóa · ${s.definition.control('ACT_CASE')!.valueLabel(s.state)}',
                        key: const ValueKey('room_dial'),
                        onPressed: () => c.act(const PuzzleAction('ACT_CASE')),
                      ),
                    if ((h.kind == 'cabinet' && s.state['itemA'] == 0) ||
                        (h.kind == 'aux' &&
                            h.action.isNotEmpty &&
                            s.state['itemB'] == 0))
                      MetalButton(
                        'Nhặt vật phẩm',
                        key: const ValueKey('room_take'),
                        primary: true,
                        onPressed: () {
                          c.act(PuzzleAction(h.action));
                          if (s.state[h.kind == 'cabinet' ? 'itemA' : 'itemB'] >
                              0) {
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    if (h.kind == 'repair' && s.state['repairReady'] == 0)
                      MetalButton(
                        'Mở túi đồ',
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (!c.inventoryOpen) c.toggleInventory();
                        },
                      ),
                    MetalButton(
                      'Trở lại phòng',
                      key: const ValueKey('room_close'),
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

Future<void> showJournal(BuildContext context, GameController c) => showReading(
  context,
  'Nhật ký · ${c.session!.definition.title}',
  '${c.session!.definition.goal}\n\n${c.session!.state['clueFound'] == 1 ? c.session!.definition.room!.hotspots.firstWhere((h) => h.kind == 'clue').text : 'Chưa tìm thấy ghi chú vận hành. Hãy quan sát tờ giấy ở phía bên phải căn phòng.'}\n\n${c.session!.state['repairReady'] == 1 ? 'Chỗ hỏng đã được sửa. Những vật phẩm đã dùng vẫn được ghi lại trong túi đồ.' : 'Máy còn một chỗ hỏng. Quan sát các đồ vật để tìm bộ phận thay thế.'}',
);

class InventoryPanel extends StatelessWidget {
  const InventoryPanel(this.c, {super.key, required this.onDrop});
  final GameController c;
  final void Function(String, Offset) onDrop;
  @override
  Widget build(BuildContext context) {
    final items = c.inventory;
    return GamePanel(
      width: 470,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Túi đồ',
                  style: TextStyle(
                    fontFamily: 'NotoSerif',
                    fontSize: 20,
                    color: gold,
                  ),
                ),
              ),
              MetalButton(
                'Cất túi',
                compact: true,
                onPressed: c.toggleInventory,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              'Chưa có đồ vật nào. Hãy xem ngăn dụng cụ trong phòng.',
              style: TextStyle(color: cream),
            ),
          if (items.isNotEmpty)
            SizedBox(
              height: 108,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [for (final item in items) _slot(context, item)],
              ),
            ),
          if (c.heldItem != null) ...[
            Text(
              c.heldItem!.description,
              style: const TextStyle(fontSize: 12, height: 1.4, color: cream),
            ),
            const SizedBox(height: 5),
            const Text(
              'Kéo món đã chọn tới chỗ cần sửa, hoặc cất túi rồi chạm nơi ấy. Chọn món thứ hai để thử ghép.',
              style: TextStyle(fontSize: 11, color: gold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _slot(BuildContext context, RoomItem item) {
    final used = c.session!.state[item.field] == 2,
        selected = c.selectedItem == item.id;
    final tile = Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xff3d3322) : const Color(0xff101b24),
        border: Border.all(color: selected ? gold : const Color(0xff48504d)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        children: [
          Opacity(
            opacity: used ? .4 : 1,
            child: Image.asset(item.asset, height: 62, width: 80),
          ),
          Text(
            used ? 'Đã dùng · ${item.name}' : item.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 11, color: cream),
          ),
        ],
      ),
    );
    return GestureDetector(
      key: ValueKey(item.id),
      onLongPress: () => showReading(context, item.name, item.description),
      onTap: () {
        if (used) {
          showReading(
            context,
            item.name,
            '${item.description}\n\nMón này đã được sử dụng.',
          );
          return;
        }
        if (c.heldItem != null && c.selectedItem != item.id) {
          c.combineItems(item.id);
        } else {
          c.selectItem(item.id);
        }
      },
      child: used
          ? tile
          : Draggable<String>(
              data: item.id,
              onDragStarted: () => c.selectItem(item.id),
              feedback: Material(
                color: Colors.transparent,
                child: Image.asset(item.asset, width: 72, height: 72),
              ),
              childWhenDragging: Opacity(opacity: .3, child: tile),
              onDragEnd: (details) =>
                  onDrop(item.id, details.offset + const Offset(36, 36)),
              child: tile,
            ),
    );
  }
}
