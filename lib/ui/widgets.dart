import 'package:flutter/material.dart';

const cream = Color(0xffede4d3),
    gold = Color(0xffdeb06e),
    ink = Color(0xff0b131a);

class UiSoundScope extends InheritedWidget {
  const UiSoundScope({super.key, required this.onSound, required super.child});
  final void Function(String) onSound;
  @override
  bool updateShouldNotify(UiSoundScope oldWidget) => false;
}

class MetalButton extends StatefulWidget {
  const MetalButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.accent = gold,
    this.primary = false,
    this.compact = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color accent;
  final bool primary, compact;
  @override
  State<MetalButton> createState() => _MetalButtonState();
}

class _MetalButtonState extends State<MetalButton> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: widget.onPressed != null,
    label: widget.label,
    child: Tooltip(
      message: widget.label,
      child: GestureDetector(
        onTapDown: widget.onPressed == null
            ? null
            : (_) => setState(() => pressed = true),
        onTapUp: widget.onPressed == null
            ? null
            : (_) => setState(() => pressed = false),
        onTapCancel: () => setState(() => pressed = false),
        onTap: widget.onPressed == null
            ? null
            : () {
                context
                    .dependOnInheritedWidgetOfExactType<UiSoundScope>()
                    ?.onSound('click');
                widget.onPressed!();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 22,
            vertical: widget.compact ? 8 : 12,
          ),
          transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: widget.onPressed == null
                  ? const Color(0xff454b50)
                  : widget.accent.withValues(alpha: widget.primary ? 1 : .55),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.primary
                  ? [
                      widget.accent.withValues(alpha: .35),
                      const Color(0xff392c20),
                    ]
                  : [const Color(0xf52e373c), const Color(0xf5111c24)],
            ),
            boxShadow: pressed
                ? []
                : const [
                    BoxShadow(
                      color: Color(0x99000000),
                      offset: Offset(0, 3),
                      blurRadius: 5,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.onPressed == null ? Colors.grey : widget.accent,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: widget.onPressed == null ? Colors.grey : cream,
                    fontSize: widget.compact ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ArtBackdrop extends StatelessWidget {
  const ArtBackdrop({
    super.key,
    this.chapter = 0,
    required this.child,
    this.dim = .35,
  });
  final int chapter;
  final Widget child;
  final double dim;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/images/chapters/${['brass', 'water', 'prism', 'core'][chapter]}/room.png',
        fit: BoxFit.cover,
        errorBuilder: (_, error, stack) => const ColoredBox(color: ink),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(3, 8, 12, .82),
              Color.fromRGBO(3, 8, 12, dim),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
      child,
    ],
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader(
    this.title, {
    super.key,
    required this.onBack,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      MetalButton(
        'Quay lại',
        onPressed: onBack,
        icon: Icons.arrow_back,
        compact: true,
      ),
      const SizedBox(width: 22),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'NotoSerif',
                fontSize: 23,
                color: cream,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 12, color: gold),
              ),
          ],
        ),
      ),
    ],
  );
}

class GamePanel extends StatelessWidget {
  const GamePanel({super.key, required this.child, this.width = 560});
  final Widget child;
  final double width;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xf7101a22),
      border: Border.all(color: gold.withValues(alpha: .6)),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 35)],
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

Widget stars(int value, {double size = 20, Color color = gold}) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    for (var i = 0; i < 3; i++)
      Icon(
        i < value ? Icons.star_rounded : Icons.star_outline_rounded,
        size: size,
        color: color,
      ),
  ],
);
Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GamePanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'NotoSerif',
                  fontSize: 22,
                  color: gold,
                ),
              ),
              const SizedBox(height: 14),
              Text(message, style: const TextStyle(color: cream)),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MetalButton(
                    'Hủy',
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                  const SizedBox(width: 12),
                  MetalButton(
                    'Xác nhận',
                    primary: true,
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ??
    false;
Future<void> showReading(
  BuildContext context,
  String title,
  String body, {
  String close = 'Đã hiểu',
  VoidCallback? after,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
      child: GamePanel(
        width: 650,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'NotoSerif',
                fontSize: 23,
                color: gold,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  body,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: cream,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: MetalButton(
                close,
                primary: true,
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  after?.call();
}
