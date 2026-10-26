import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const chapterColors = [
  Color(0xffe1ac60),
  Color(0xff64cfba),
  Color(0xffb6a1f1),
  Color(0xffff956e),
];
const chapterNames = [
  'Xưởng Đồng Hồ',
  'Thư Viện Chìm',
  'Đài Thiên Văn',
  'Lõi Vĩnh Cửu',
];

// Bounded text layout cache: values change on actions, most labels do not.
final Map<String, TextPainter> _textCache = {};

void textAt(
  Canvas canvas,
  String text,
  Offset center, {
  double size = 16,
  Color color = const Color(0xffefe8d8),
  double width = 240,
  bool serif = false,
  TextAlign align = TextAlign.center,
  FontWeight weight = FontWeight.w500,
}) {
  final key = '$text|$size|${color.toARGB32()}|$width|$serif|$align|$weight';
  var p = _textCache[key];
  if (p == null) {
    if (_textCache.length >= 384) {
      _textCache.remove(_textCache.keys.first)?.dispose();
    }
    p = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: serif ? 'NotoSerif' : 'NotoSans',
          fontSize: size,
          color: color,
          fontWeight: weight,
          height: 1.2,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: width);
    _textCache[key] = p;
  }
  p.paint(
    canvas,
    Offset(
      center.dx - (align == TextAlign.center ? p.width / 2 : 0),
      center.dy - p.height / 2,
    ),
  );
}

void metalPanel(
  Canvas c,
  Rect r,
  Color accent, {
  double radius = 12,
  bool rivets = true,
}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
  c.drawRRect(
    rr.shift(const Offset(0, 6)),
    Paint()
      ..color = const Color(0xaa000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
  c.drawRRect(
    rr,
    Paint()
      ..shader = ui.Gradient.linear(
        r.topLeft,
        r.bottomRight,
        [
          const Color(0xff353a3b),
          const Color(0xff11171b),
          const Color(0xff202427),
        ],
        [0, .5, 1],
      ),
  );
  c.drawRRect(
    rr,
    Paint()
      ..color = accent.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  c.drawRRect(
    RRect.fromRectAndRadius(r.deflate(5), Radius.circular(radius - 3)),
    Paint()
      ..color = const Color(0xff62605a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7,
  );
  // Etched scratches are deterministic and stay attached to the material.
  for (var i = 0; i < 13; i++) {
    final x = r.left + 12 + (i * 73 % ((r.width - 24).toInt().clamp(1, 10000)));
    final y = r.top + 12 + (i * 41 % ((r.height - 24).toInt().clamp(1, 10000)));
    c.drawLine(
      Offset(x, y),
      Offset(x + 8, y - 1),
      Paint()..color = const Color(0x226f7775),
    );
  }
  if (rivets) {
    for (final p in [
      r.topLeft + const Offset(12, 12),
      r.topRight + const Offset(-12, 12),
      r.bottomLeft + const Offset(12, -12),
      r.bottomRight + const Offset(-12, -12),
    ]) {
      c.drawCircle(p, 3.5, Paint()..color = const Color(0xffa29b84));
      c.drawLine(
        p - const Offset(2, 1),
        p + const Offset(2, 1),
        Paint()
          ..color = const Color(0xff252626)
          ..strokeWidth = 1.5,
      );
    }
  }
}

void glow(
  Canvas c,
  Offset p,
  double radius,
  Color color, {
  double strength = .5,
}) {
  c.drawCircle(
    p,
    radius,
    Paint()
      ..shader = ui.Gradient.radial(p, radius, [
        color.withValues(alpha: strength),
        color.withValues(alpha: 0),
      ]),
  );
}

void pipe(
  Canvas c,
  List<Offset> points,
  Color accent, {
  bool active = false,
  double time = 0,
  double width = 14,
}) {
  if (points.length < 2) return;
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final p in points.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  c.drawPath(
    path,
    Paint()
      ..color = const Color(0xc9000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 9
      ..strokeJoin = StrokeJoin.round,
  );
  c.drawPath(
    path,
    Paint()
      ..color = const Color(0xff635c4e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round,
  );
  c.drawPath(
    path,
    Paint()
      ..color = const Color(0xffa9a28b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round,
  );
  if (active) {
    c.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * .4,
    );
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      for (var j = 0; j < 6; j++) {
        final t = metric.getTangentForOffset(
          ((time * 65 + j * 37) % metric.length),
        );
        if (t != null) c.drawCircle(t.position, 2.8, Paint()..color = accent);
      }
    }
  }
}

void dial(
  Canvas c,
  Offset center,
  double radius,
  double value,
  double max,
  Color accent, {
  String label = '',
  double? target,
}) {
  glow(c, center, radius + 10, Colors.black, strength: .8);
  c.drawCircle(
    center,
    radius,
    Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          const Color(0xffddcfa7),
          const Color(0xff857b60),
          const Color(0xff252727),
        ],
        [0, .7, 1],
      ),
  );
  c.drawCircle(center, radius - 6, Paint()..color = const Color(0xffe0d4b6));
  for (var i = 0; i <= 10; i++) {
    final angle = -math.pi * .8 + i * math.pi * 1.6 / 10;
    final direction = Offset(math.sin(angle), -math.cos(angle));
    c.drawLine(
      center + direction * (radius - 10),
      center + direction * (radius - 17),
      Paint()
        ..color = const Color(0xff393d3a)
        ..strokeWidth = 2,
    );
  }
  if (target != null) {
    final a = -math.pi * .8 + (target / max) * math.pi * 1.6;
    c.drawCircle(
      center + Offset(math.sin(a), -math.cos(a)) * (radius - 12),
      4,
      Paint()..color = const Color(0xff3b7f61),
    );
  }
  final angle = -math.pi * .8 + (value / max).clamp(0, 1) * math.pi * 1.6;
  c.drawLine(
    center,
    center + Offset(math.sin(angle), -math.cos(angle)) * (radius - 19),
    Paint()
      ..color = const Color(0xff9b3a21)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round,
  );
  c.drawCircle(center, 5, Paint()..color = const Color(0xff292c2a));
  textAt(
    c,
    '${value.round()}',
    center + Offset(0, radius * .40),
    size: 17,
    color: const Color(0xff252a28),
  );
  if (label.isNotEmpty) {
    textAt(
      c,
      label,
      center + Offset(0, radius + 20),
      size: 15,
      width: 180,
      color: accent,
    );
  }
}
