import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/controller.dart';
import 'widgets.dart';

class EndingScreen extends StatefulWidget {
  const EndingScreen(this.c, {super.key});
  final GameController c;
  @override
  State<EndingScreen> createState() => _EndingScreenState();
}

class _EndingScreenState extends State<EndingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController reveal = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: widget.c.store.settings.reducedMotion ? 500 : 9000,
    ),
  )..forward();
  @override
  void dispose() {
    reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: reveal,
    builder: (context, _) => LayoutBuilder(
      builder: (context, box) => Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/ui/ending.png', fit: BoxFit.cover),
          CustomPaint(painter: _VaultReveal(reveal.value)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xf5081117),
                  Color(0xda081117),
                  Color(0x00081117),
                ],
                stops: [0, .37, .72],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: box.maxWidth * .54,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: box.maxWidth * .05,
                  vertical: 22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'MƯỜI HAI CÁNH CỬA ĐÃ MỞ',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: gold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'MECHANICA',
                      style: TextStyle(
                        fontFamily: 'NotoSerif',
                        fontSize: box.maxHeight < 450 ? 32 : 44,
                        color: cream,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Một thế giới mới\nđang thức dậy.',
                      style: TextStyle(
                        fontFamily: 'NotoSerif',
                        fontSize: 24,
                        color: gold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Trong khu vườn dưới lòng núi,\nhạt giống đầu tiên nảy mầm.\n\nCỗ máy đã tìm được người gác tiếp theo.',
                      style: TextStyle(fontSize: 13, color: cream, height: 1.7),
                    ),
                    const SizedBox(height: 20),
                    MetalButton(
                      'Trở về · Tiếp tục khám phá',
                      primary: true,
                      onPressed: () => widget.c.navigate(AppPage.home),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hình ảnh nguyên bản tạo bằng AI · Nhạc tổng hợp riêng\nPhông Noto — giấy phép SIL OFL · Flutter & Flame\nCảm ơn bạn đã lắng nghe cỗ máy.',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xffb5b9ad),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _VaultReveal extends CustomPainter {
  const _VaultReveal(this.progress);
  final double progress;
  @override
  void paint(Canvas c, Size size) {
    final opening = Curves.easeInOutCubic.transform(
      (progress * 1.7).clamp(0, 1),
    );
    final middle = size.width * .70;
    final half = size.width * .32;
    final paint = Paint()..color = const Color(0xff111c22);
    c.save();
    c.clipRect(
      Rect.fromLTWH(size.width * .38, 0, size.width * .62, size.height),
    );
    for (final sign in [-1, 1]) {
      final left = sign < 0
          ? middle - half - half * opening
          : middle + half * opening;
      final panel = Rect.fromLTWH(left, 0, half, size.height);
      c.drawRect(panel, paint);
      c.drawRect(
        panel.deflate(8),
        Paint()
          ..color = gold.withValues(alpha: .4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (var i = 0; i < 8; i++) {
        final y = i * size.height / 7;
        c.drawLine(
          Offset(panel.left + 16, y),
          Offset(panel.right - 16, y),
          Paint()
            ..color = const Color(0xff3a403c)
            ..strokeWidth = 3,
        );
      }
    }
    // Pollen follows bounded analytic trajectories after the shutters open.
    for (var i = 0; i < 20; i++) {
      final x =
          size.width * .42 +
          (i * 57 % ((size.width * .55).toInt())) +
          math.sin(i + progress * 6) * 14;
      final y = (i * 37 - progress * 160) % size.height;
      c.drawCircle(
        Offset(x, y),
        1.6,
        Paint()..color = gold.withValues(alpha: opening * .5),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_VaultReveal old) => old.progress != progress;
}
