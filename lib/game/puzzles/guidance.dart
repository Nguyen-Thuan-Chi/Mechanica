import 'dart:collection';
import 'dart:isolate';

import 'model.dart';
import 'reducer.dart';

class Guidance {
  const Guidance(
    this.target,
    this.instruction,
    this.reason, {
    this.recovery = false,
  });
  final String target, instruction, reason;
  final bool recovery;
}

/// All proposed puzzle actions are validated by the same reducer as gameplay.
/// Search has both a node and wall-clock budget and runs outside the UI isolate.
class GuidanceEngine {
  static Future<Guidance> next(PuzzleDefinition level, PuzzleState state) =>
      Isolate.run(() => solve(level, state));

  static Guidance solve(
    PuzzleDefinition l,
    PuzzleState s, {
    int maxStates = 3500,
    int milliseconds = 220,
  }) {
    if (s.won) {
      return const Guidance(
        'done',
        'Cỗ máy đã chạy đúng. Hãy đợi cửa mở.',
        'Mọi bộ phận đã phối hợp với nhau.',
      );
    }
    if (s['inspected'] == 0) {
      return const Guidance(
        'journal',
        'Chạm tờ giấy bên trái căn phòng.',
        'Lời nhắn cho biết vì sao cánh cửa bị giữ.',
      );
    }
    if (s['clueFound'] == 0) {
      return const Guidance(
        'clue',
        'Đọc tờ ghi chú bên phải căn phòng.',
        'Những dấu trên đó giúp hiểu cách vận hành máy.',
      );
    }
    final room = l.room;
    if (room != null && s['repairReady'] == 0) {
      if (s['itemA'] == 0) {
        if (evaluate(l.control('ACT_SEARCH')!.guard, s.values) == 0) {
          return action(l, s, 'ACT_CASE');
        }
        return action(l, s, 'ACT_SEARCH');
      }
      if (room.combine && s['itemB'] == 0) return action(l, s, 'ACT_SECOND');
      if (room.combine && s['itemC'] == 0) return action(l, s, 'ACT_COMBINE');
      return action(l, s, 'ACT_REPAIR');
    }
    if (l.number == 1) {
      if (s['jam'] == 1) return action(l, s, 'ACT_RELEASE');
      if (s['powered'] == 1) return action(l, s, 'ACT_START');
      for (final pair in [
        ('gearA', 2, 'ACT_GEAR_A'),
        ('gearB', 1, 'ACT_GEAR_B'),
        ('reverse', 0, 'ACT_REVERSE'),
        ('safety', 1, 'ACT_SAFETY'),
      ]) {
        if (s[pair.$1] != pair.$2) return action(l, s, pair.$3);
      }
      return action(l, s, 'ACT_START');
    }
    final reducer = PuzzleReducer(l);
    final fields =
        l.initial.keys.where((k) => k != 'flow' && k != 'fault').toList()
          ..sort();
    String key(PuzzleState x) => fields.map((k) => x[k]).join(',');
    // The verified solution suffix is inexpensive and includes late-game stages.
    var cursor = reducer.initial();
    final verified = <String>{};
    for (final id in l.solution) {
      verified.add(key(cursor));
      if (key(cursor) == key(s)) return action(l, s, id);
      cursor = reducer.apply(cursor, PuzzleAction(id)).state;
    }
    final clock = Stopwatch()..start();
    final queue = Queue<(PuzzleState, String)>()..add((s, ''));
    final seen = <String>{key(s)};
    final actions = l.controls.where((c) => !c.isRoomAction).toList();
    while (queue.isNotEmpty &&
        seen.length < maxStates &&
        clock.elapsedMilliseconds < milliseconds) {
      final node = queue.removeFirst();
      for (final c in actions) {
        final result = reducer.apply(node.$1, PuzzleAction(c.id));
        if (!result.accepted || result.events.any((e) => e.kind == 'failure')) {
          continue;
        }
        final first = node.$2.isEmpty ? c.id : node.$2;
        if (result.state.won || verified.contains(key(result.state))) {
          return action(l, s, first);
        }
        if (seen.add(key(result.state))) queue.add((result.state, first));
      }
    }
    return const Guidance(
      'undo',
      'Bấm Hoàn tác để quay lại trước lần đổi vừa rồi. Nếu không còn bước hoàn tác, dùng Đặt lại.',
      'Chưa xác minh được đường mở cửa từ cấu hình này trong thời gian cho phép. Đặt lại sẽ trả vật phẩm và tài nguyên về đầu màn, giữ các màn đã mở.',
      recovery: true,
    );
  }

  static Guidance action(PuzzleDefinition l, PuzzleState s, String id) {
    final room = l.room!;
    switch (id) {
      case 'ACT_INSPECT':
        return const Guidance(
          'journal',
          'Chạm tờ giấy bên trái.',
          'Đọc lời nhắn trước khi vận hành.',
        );
      case 'ACT_CLUE':
        return const Guidance(
          'clue',
          'Chạm ghi chú bên phải.',
          'Tìm dấu để đối chiếu với máy.',
        );
      case 'ACT_SEARCH':
        return const Guidance(
          'cabinet',
          'Mở ngăn dụng cụ bên trái rồi bấm Nhặt vật phẩm.',
          'Bên trong có bộ phận thay cho chỗ hỏng.',
        );
      case 'ACT_CASE':
        return const Guidance(
          'cabinet',
          'Mở ngăn dụng cụ. Bấm Xoay khóa đến hình được ghi ở cuối tờ manh mối, rồi Nhặt vật phẩm.',
          'Hình trên giấy và mặt khóa là cùng một dấu.',
        );
      case 'ACT_SECOND':
        return const Guidance(
          'aux',
          'Chạm hộp nhỏ dưới máy rồi nhặt bộ phận thứ hai.',
          'Hai đầu nối phải đủ cả hai phần mới dùng được.',
        );
      case 'ACT_COMBINE':
        return const Guidance(
          'inventory',
          'Mở Túi đồ. Chọn món thứ nhất rồi chọn món thứ hai để ghép.',
          'Một món còn thiếu đầu nối của món kia.',
        );
      case 'ACT_REPAIR':
        return Guidance(
          'repair',
          'Mở Túi đồ, chọn ${room.items.last.name.toLowerCase()}, cất túi rồi chạm ${room.repairTitle.toLowerCase()} bên phải.',
          'Hoặc kéo món đồ tới ổ đang sáng để nối lại bộ máy.',
        );
    }
    final c = l.control(id)!;
    final nextLabel = c.field != null && c.options.isNotEmpty
        ? c.options[(s[c.field!] + 1) % c.options.length]
        : '';
    final instruction = id == 'ACT_RELEASE'
        ? 'Bấm Nhả khóa trên máy để gỡ trục đang kẹt.'
        : 'Chạm ${c.label.toLowerCase()}${nextLabel.isEmpty ? '' : ' một lần để chuyển sang $nextLabel'}.';
    final reason = switch (c.kind) {
      'gear' => 'Bánh lớn kéo bánh nhỏ làm trục sau quay nhanh hơn. Hai bánh chạm nhau đổi chiều quay; hãy nhìn kim và các răng đang ăn khớp.',
      'mirror' => 'Gương đổi hướng tia tới con mắt tiếp theo. Hãy nhìn đường sáng sau thao tác.',
      'valve' => 'Van chọn đường đi. Quan sát đường ống trước khi cho nước hoặc hơi chạy.',
      'filter' => 'Bộ lọc giữ màu hoặc giữ cặn tùy máy. Kiểm tra vật đi vào và phần đi ra.',
      _ => switch (id) {
        'ACT_START' =>
          'Chỉ chạy khi hai bánh đã lắp, chiều nguồn đúng và chốt an toàn mở.',
        'ACT_REVERSE' => 'Chiều nguồn quyết định hướng quay của cả đường truyền. Mũi tên ở cửa cần quay thuận.',
        'ACT_SAFETY' =>
          'Mở chốt an toàn để trục quay được khi máy bắt đầu chạy.',
        'ACT_CLUTCH' =>
          'Cần này chọn hai đồng hồ cùng tiến; chiếc còn lại sẽ đứng yên.',
        'ACT_STEP' => 'Cho máy chạy đúng một nhịp rồi nhìn lượng nước, kim hoặc bộ nhớ vừa thay đổi.',
        'ACT_POWER' => 'Tăng điện làm lõi nóng hơn; cần nước lạnh để giữ kim trong vùng xanh.',
        'ACT_PUMP' => 'Bơm đưa nước hoặc hơi qua đường đã chọn. Kiểm tra van và nhìn kim sau mỗi nhịp.',
        'ACT_LIGHT' =>
          'Đèn cấp tia vào đường gương. Quan sát mắt nào nhận được ánh sáng.',
        'ACT_CALIBRATE' => 'Chốt giữ nền áp và truyền động để bạn có thể điều chỉnh các nhánh còn lại.',
        'ACT_ARM' =>
          'Giữ bộ đồng bộ khi ánh sáng, điện và nước lạnh đều đã sẵn sàng.',
        'ACT_LOCK' =>
          'Chốt cuối kiểm tra những vạch và đèn đang sáng trước khi nhả cửa.',
        _ => 'Bộ phận này giữ hoặc cấp lực cho nhánh nối với nó. Làm từng bước rồi quan sát đèn và kim trước khi chạy tiếp.',
      },
    };
    return Guidance(id, instruction, reason);
  }
}
