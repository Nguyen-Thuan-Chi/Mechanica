import 'package:flutter/material.dart';

import '../app/controller.dart';
import 'widgets.dart';

Future<void> showGuide(BuildContext context) async {
  const pages = [
    (
      Icons.touch_app,
      'Nhìn quanh căn phòng',
      'Chạm vào tờ giấy, ngăn kéo hoặc bộ máy để nhìn gần hơn. Những dấu vết ở một góc phòng có thể giúp bạn hiểu thiết bị ở góc khác.',
    ),
    (
      Icons.backpack,
      'Mang theo thứ hữu ích',
      'Mở Túi đồ để xem món vừa nhặt. Chọn vật phẩm rồi chạm chỗ cần sửa, hoặc kéo món đó tới thiết bị. Giữ ngón tay trên món đồ để đọc mô tả.',
    ),
    (
      Icons.build,
      'Ghép những phần còn thiếu',
      'Nếu hai món có đầu nối phù hợp, chọn món thứ nhất rồi chọn món thứ hai trong túi. Món đã dùng vẫn ở đó, nhưng được đánh dấu để bạn nhớ.',
    ),
    (
      Icons.rotate_right,
      'Thử và quan sát',
      'Chạm bánh răng hoặc van để xoay một nấc; kéo cần lên hoặc xuống để gạt. Nhìn đường nước, tia sáng và kim đồng hồ sau mỗi lần thao tác.',
    ),
    (
      Icons.zoom_in,
      'Đến gần bộ máy',
      'Chạm bộ máy giữa phòng để xem chi tiết. Nút Căn phòng đưa bạn trở lại. Có thể ẩn thanh nút nếu muốn nhìn máy rõ hơn.',
    ),
    (
      Icons.menu_book,
      'Không cần nhớ mọi thứ',
      'Nhật ký giữ các manh mối đã tìm thấy. Gợi ý giúp bạn theo từng bước. Khi máy kẹt, đọc lời báo rồi thử Hoàn tác; Đặt lại đưa cả màn về ban đầu.',
    ),
    (
      Icons.pause_circle,
      'Cho máy thời gian',
      'Ở lõi máy, Một nhịp cho máy chạy từng bước. Chạy để quan sát nhiều nhịp; Dừng để suy nghĩ. Tiến trình được lưu trên thiết bị khi bạn rời game.',
    ),
  ];
  var page = 0;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, change) => Dialog(
        backgroundColor: Colors.transparent,
        child: GamePanel(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(pages[page].$1, size: 48, color: gold),
                const SizedBox(height: 10),
                Text(
                  pages[page].$2,
                  style: const TextStyle(
                    fontFamily: 'NotoSerif',
                    fontSize: 23,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  pages[page].$3,
                  style: const TextStyle(
                    fontSize: 16,
                    color: cream,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${page + 1} / ${pages.length}',
                  style: const TextStyle(color: gold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (page > 0)
                      MetalButton(
                        'Trang trước',
                        onPressed: () => change(() => page--),
                      ),
                    if (page < pages.length - 1)
                      MetalButton(
                        'Trang sau',
                        onPressed: () => change(() => page++),
                      ),
                    MetalButton(
                      'Trở lại',
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

Future<void> showSettings(BuildContext context, GameController c) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 70, vertical: 20),
        child: GamePanel(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cài đặt',
                  style: TextStyle(
                    fontFamily: 'NotoSerif',
                    fontSize: 25,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Bật nhạc nền',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: c.store.settings.musicEnabled,
                  onChanged: (v) {
                    setLocal(() => c.store.settings.musicEnabled = v);
                    c.settingsChanged();
                  },
                ),
                _volume('Nhạc nền', c.store.settings.music, (v) {
                  setLocal(() => c.store.settings.music = v);
                  c.settingsChanged();
                }),
                _volume('Âm thanh thao tác', c.store.settings.sfx, (v) {
                  setLocal(() => c.store.settings.sfx = v);
                  c.settingsChanged();
                }),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Tắt toàn bộ âm thanh',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: c.store.settings.muted,
                  onChanged: (v) {
                    setLocal(() => c.store.settings.muted = v);
                    c.settingsChanged();
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Giảm chuyển động',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: c.store.settings.reducedMotion,
                  onChanged: (v) {
                    setLocal(() => c.store.settings.reducedMotion = v);
                    c.settingsChanged();
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    MetalButton('Cách chơi', onPressed: () => showGuide(ctx)),
                    MetalButton(
                      'Xóa tiến trình',
                      onPressed: () async {
                        if (await confirm(
                          ctx,
                          'Xóa toàn bộ tiến trình?',
                          c.store.uid == null
                              ? 'Tất cả sao, màn đã mở và trạng thái đang chơi sẽ bị xóa trên thiết bị này. Cài đặt âm thanh được giữ.'
                              : 'Chỉ xóa bản lưu trên thiết bị. Thành tích trên tài khoản sẽ được tải lại khi đồng bộ; thao tác này không xóa dữ liệu Firestore.',
                        )) {
                          await c.store.resetProgress();
                          c.session = null;
                          c.navigate(AppPage.home);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                    ),
                    MetalButton(
                      'Đóng',
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

Widget _volume(String label, double value, ValueChanged<double> callback) =>
    Row(
      children: [
        SizedBox(
          width: 145,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Slider(value: value, onChanged: callback, activeColor: gold),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 100).round()}%',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
