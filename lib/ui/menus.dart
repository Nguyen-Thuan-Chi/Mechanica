import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../app/controller.dart';
import '../game/rendering/drawing.dart';
import 'settings.dart';
import 'widgets.dart';
import 'account.dart';
import 'developer_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen(this.c, {super.key});
  final GameController c;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 80),
  )..repeat();
  @override
  void dispose() {
    spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return ArtBackdrop(
      dim: .12,
      child: LayoutBuilder(
        builder: (context, b) {
          final small = b.maxHeight < 600 || b.maxWidth < 1100;
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: b.maxWidth * .055,
              vertical: small ? 18 : 35,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MƯỜI HAI CÁNH CỬA · MỘT BÍ MẬT',
                        style: TextStyle(
                          color: gold,
                          fontSize: 11,
                          letterSpacing: 2.3,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'MECHANICA',
                        style: TextStyle(
                          fontFamily: 'NotoSerif',
                          fontSize: small ? 44 : 64,
                          fontWeight: FontWeight.w500,
                          color: cream,
                          letterSpacing: small ? 4 : 7,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 15),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BÍ ẨN CỖ MÁY CUỐI CÙNG',
                        style: TextStyle(
                          fontSize: small ? 12 : 15,
                          color: gold,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: small ? 15 : 24),
                      const Text(
                        'Có những cỗ máy chỉ cần một tia lửa.\nCó những bí mật cần cả một hành trình.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xffb8b6ac),
                          height: 1.7,
                        ),
                      ),
                      SizedBox(height: small ? 20 : 32),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          MetalButton(
                            c.store.resume != null
                                ? 'Chơi tiếp'
                                : 'Bắt đầu hành trình',
                            primary: true,
                            onPressed: c.continueGame,
                            icon: Icons.play_arrow_rounded,
                          ),
                          MetalButton(
                            'Chọn chương',
                            onPressed: () => c.navigate(AppPage.chapters),
                            icon: Icons.explore_outlined,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 18,
                        runSpacing: 4,
                        children: [
                          _link('Cài đặt', () => showSettings(context, c)),
                          _link('Cách chơi', () => showGuide(context)),
                          _link('Thoát', SystemNavigator.pop),
                          if (kDebugMode)
                            _link(
                              c.isDeveloper
                                  ? 'Phòng thử đang bật'
                                  : 'Phòng thử máy',
                              () => showDeveloperMenu(context, c),
                            ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'KHÁM PHÁ · SUY LUẬN · ĐÁNH THỨC',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 2,
                          color: Color(0xff898d8c),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: IgnorePointer(
                    ignoring: false,
                    child: AnimatedBuilder(
                      animation: spin,
                      builder: (context, _) => Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: b.maxHeight * .7,
                            height: b.maxHeight * .7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: gold.withValues(alpha: .12),
                                  blurRadius: 75,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                          ),
                          Transform.rotate(
                            angle: c.store.settings.reducedMotion
                                ? 0
                                : spin.value * math.pi * 2,
                            child: Image.asset(
                              'assets/images/chapters/brass/prop0.png',
                              width: b.maxHeight * .82,
                            ),
                          ),
                          Container(
                            width: small ? 80 : 120,
                            height: small ? 80 : 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ink,
                              border: Border.all(color: gold, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                'M',
                                style: TextStyle(
                                  fontFamily: 'NotoSerif',
                                  fontSize: small ? 40 : 60,
                                  color: gold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            child: Text(
                              '${c.store.bestStars.length.toString().padLeft(2, '0')} / 12 CỖ MÁY ĐÃ THỨC',
                              style: const TextStyle(
                                fontSize: 10,
                                color: gold,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: MetalButton(
                              'Tài khoản',
                              compact: true,
                              icon: Icons.person_outline,
                              onPressed: () => showAccount(context, c),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _link(String text, VoidCallback callback) => GestureDetector(
    onTap: callback,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text, style: const TextStyle(color: cream, fontSize: 12)),
    ),
  );
}

class ChapterScreen extends StatelessWidget {
  const ChapterScreen(this.c, {super.key});
  final GameController c;
  @override
  Widget build(BuildContext context) => ArtBackdrop(
    chapter: c.selectedChapter,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          PageHeader(
            'Bốn khu vực bị lãng quên',
            onBack: () => c.navigate(AppPage.home),
            subtitle: 'Mỗi cánh cửa mở ra một phần ký ức.',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 3 ? 0 : 14),
                      child: _chapter(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hoàn thành một màn để mở màn kế tiếp. Có thể chơi lại để tìm cách vận hành tốt hơn.',
            style: TextStyle(fontSize: 11, color: Color(0xffb4b5ae)),
          ),
        ],
      ),
    ),
  );
  Widget _chapter(int i) {
    final open = c.isUnlocked(i * 3 + 1);
    final earned = c.levels
        .skip(i * 3)
        .take(3)
        .fold(0, (sum, l) => sum + (c.store.bestStars[l.id] ?? 0));
    return GestureDetector(
      onTap: open
          ? () {
              c.selectedChapter = i;
              c.navigate(AppPage.levels);
            }
          : null,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: ink,
          border: Border.all(
            color: chapterColors[i].withValues(alpha: open ? 0.65 : .22),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/chapters/${c.levels[i * 3].biome}/card.png',
                    fit: BoxFit.cover,
                    color: open ? null : const Color(0xff777777),
                    colorBlendMode: open ? null : BlendMode.saturation,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, ink.withValues(alpha: .9)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 12,
                    child: Text(
                      '0${i + 1}',
                      style: TextStyle(
                        fontFamily: 'NotoSerif',
                        fontSize: 28,
                        color: chapterColors[i],
                      ),
                    ),
                  ),
                  if (!open)
                    const Center(
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: cream,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapterNames[i],
                    maxLines: 2,
                    style: TextStyle(
                      fontFamily: 'NotoSerif',
                      fontSize: 17,
                      color: open ? cream : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    open
                        ? '${c.levels.where((l) => l.chapter == i && c.store.bestStars.containsKey(l.id)).length}/3 máy đã sửa · $earned / 9 sao'
                        : 'Mở sau màn ${i * 3}',
                    style: TextStyle(fontSize: 11, color: chapterColors[i]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LevelScreen extends StatelessWidget {
  const LevelScreen(this.c, {super.key});
  final GameController c;
  @override
  Widget build(BuildContext context) => ArtBackdrop(
    chapter: c.selectedChapter,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          PageHeader(
            chapterNames[c.selectedChapter],
            onBack: () => c.navigate(AppPage.chapters),
            subtitle: [
              'Đồng thau, hơi nước và những bánh răng im lặng.',
              'Nơi ký ức chờ sau những lớp kính ướt.',
              'Lần theo ánh sáng của một bầu trời đã mất.',
              'Mọi hệ thống đều dẫn về đây.',
            ][c.selectedChapter],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Row(
              children: [
                for (final l in c.levels.skip(c.selectedChapter * 3).take(3))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: c.isUnlocked(l.number)
                            ? () => c.start(l.number - 1)
                            : null,
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: ink,
                            border: Border.all(
                              color: chapterColors[l.chapter].withValues(
                                alpha: .55,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      'assets/images/ui/lv${l.number.toString().padLeft(2, '0')}.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, error, stack) =>
                                          Image.asset(
                                            l.background,
                                            fit: BoxFit.cover,
                                          ),
                                    ),
                                    Positioned(
                                      left: 14,
                                      top: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        color: ink,
                                        child: Text(
                                          'MÀN ${l.number.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            color: gold,
                                            fontSize: 11,
                                            letterSpacing: 1.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!c.isUnlocked(l.number))
                                      const Center(
                                        child: Icon(
                                          Icons.lock_outline,
                                          size: 32,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.title,
                                      style: const TextStyle(
                                        fontFamily: 'NotoSerif',
                                        fontSize: 18,
                                        color: cream,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    stars(c.store.bestStars[l.id] ?? 0),
                                    const SizedBox(height: 5),
                                    Text(
                                      l.goal,
                                      maxLines: 2,
                                      style: const TextStyle(
                                        color: Color(0xffa5b1b5),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
