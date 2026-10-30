import 'guidance.dart';
import 'model.dart';

class Onboarding {
  static const intro = 'v3_intro',
      skipped = 'v3_skipped',
      completed = 'v3_completed';
  static bool active(Set<String> flags, int level) =>
      level == 1 && !flags.contains(skipped) && !flags.contains(completed);
  static Guidance step(
    PuzzleDefinition l,
    PuzzleState s,
    Set<String> flags, {
    required bool inventoryOpen,
    required bool selected,
    required bool zoom,
  }) {
    if (!flags.contains(intro)) {
      return const Guidance(
        'intro',
        'Máy phát điện đã ngừng hoạt động. Bạn cần sửa nó để mở cánh cửa phía trước.',
        'Mỗi bước sẽ chỉ rõ đồ vật cần chạm. Bạn có thể xem lại hoặc bỏ qua trong menu hướng dẫn.',
      );
    }
    if (s.won) {
      return const Guidance(
        'done',
        'Bạn đã sửa thành công cỗ máy đầu tiên!',
        'Những căn phòng tiếp theo sẽ cần bạn tự tìm manh mối và vận dụng những gì đã học.',
      );
    }
    if (s['inspected'] == 0 || s['clueFound'] == 0 || s['itemA'] == 0) {
      return GuidanceEngine.solve(l, s);
    }
    if (s['repairReady'] == 0) {
      if (!inventoryOpen && !selected) {
        return const Guidance(
          'inventory',
          'Bấm Túi đồ ở thanh dưới để xem linh kiện vừa nhặt.',
          'Vật phẩm bạn nhặt được nằm trong túi, không mất khi đóng hộp quan sát.',
        );
      }
      if (!selected) {
        return Guidance(
          l.room!.items.first.id,
          'Chạm khớp nối trong túi để chọn nó.',
          'Viền vàng cho biết món đang được chọn.',
        );
      }
      return Guidance(
        'repair',
        'Cất túi rồi chạm ổ trục đang sáng bên phải. Bạn cũng có thể kéo linh kiện tới đó.',
        'Khớp nối sẽ lấp chỗ trống và truyền lực vào máy.',
      );
    }
    if (!zoom) {
      return const Guidance(
        'machine',
        'Chạm bộ máy ở giữa phòng để đến gần.',
        'Hai bánh răng chạm nhau sẽ quay ngược chiều. Bạn sẽ thử thay bánh và nhìn trục truyền lực.',
      );
    }
    return GuidanceEngine.solve(l, s);
  }
}
