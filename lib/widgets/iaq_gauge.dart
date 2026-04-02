import 'dart:math';
import 'package:flutter/material.dart';

class GaugeSegment {
  final double from;
  final double to;
  final Color color;

  const GaugeSegment({
    required this.from,
    required this.to,
    required this.color,
  });
}

class IaqGauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final List<GaugeSegment> segments;
  final String label;
  final String valueText;

  const IaqGauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.segments,
    required this.label,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: min, end: clamped),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return SizedBox(
          width: 320,
          height: 240,
          child: CustomPaint(
            painter: _GaugePainter(
              value: animatedValue,
              min: min,
              max: max,
              segments: segments,
              label: label,
              valueText: valueText,
              textStyle:
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final List<GaugeSegment> segments;
  final String label;
  final String valueText;
  final TextStyle textStyle;

  _GaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.segments,
    required this.label,
    required this.valueText,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.90);
    final radius = _min(size.width * 0.42, size.height * 0.70);
    final rect = Rect.fromCircle(center: center, radius: radius);

    const startAngle = pi;
    const sweepAngle = pi;

    // 背景弧
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..color = Colors.black12;

    canvas.drawArc(rect, startAngle, sweepAngle, false, bgPaint);

    // 彩色分段弧
    final segPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;

    for (final s in segments) {
      final a0 = _mapToAngle(s.from);
      final a1 = _mapToAngle(s.to);
      segPaint.color = s.color;
      canvas.drawArc(rect, a0, a1 - a0, false, segPaint);
    }

    // 刻度文字
    _drawText(
      canvas,
      Offset(center.dx - radius - 6, center.dy - 18),
      "${min.toInt()}",
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );

    _drawText(
      canvas,
      Offset(center.dx - 18, center.dy - radius - 18),
      "${((min + max) / 2).toInt()}",
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );

    _drawText(
      canvas,
      Offset(center.dx + radius - 34, center.dy - 18),
      "${max.toInt()}",
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );

    // 指针阴影
    final clamped = value.clamp(min, max);
    final ang = _mapToAngle(clamped);
    final needleLen = radius * 0.82;

    final needleEnd = Offset(
      center.dx + needleLen * cos(ang),
      center.dy + needleLen * sin(ang),
    );

    final shadowPaint = Paint()
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = Colors.black12;

    canvas.drawLine(
      center.translate(2, 2),
      needleEnd.translate(2, 2),
      shadowPaint,
    );

    // 指针
    final needlePaint = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1F1F1F);

    canvas.drawLine(center, needleEnd, needlePaint);

    // 中心圆帽外圈
    final capOuter = Paint()..color = Colors.white;
    canvas.drawCircle(center, 14, capOuter);

    // 中心圆帽内圈
    final capInner = Paint()..color = const Color(0xFF1F1F1F);
    canvas.drawCircle(center, 9, capInner);

    // 标题
    _drawCenteredText(
      canvas,
      Offset(size.width / 2, size.height * 0.10),
      label,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );

    // 数值
    _drawCenteredText(
      canvas,
      Offset(size.width / 2, size.height * 0.21),
      valueText,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );
  }

  double _mapToAngle(double v) {
    final t = (v - min) / (max - min);
    return pi + (pi * t);
  }

  void _drawText(
    Canvas canvas,
    Offset pos,
    String text, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: const Color(0xFF2B2B2B),
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, pos);
  }

  void _drawCenteredText(
    Canvas canvas,
    Offset center,
    String text, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: const Color(0xFF222222),
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  double _min(double a, double b) => a < b ? a : b;

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.label != label ||
        oldDelegate.valueText != valueText ||
        oldDelegate.segments != segments;
  }
}