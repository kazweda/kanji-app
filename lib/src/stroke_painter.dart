import 'package:flutter/material.dart';

import 'kanjivg.dart';

/// 書き順をステップ表示するペインター。
///
/// - 書き終わった画: 黒
/// - いま書いている画: 赤（[progress] に合わせて筆の動きを再現）
/// - これから書く画: 薄いグレー（[showUpcoming] が true のとき）
class StrokePainter extends CustomPainter {
  StrokePainter({
    required this.data,
    required this.step,
    required this.progress,
    required this.showUpcoming,
    required this.colorScheme,
  });

  final KanjiStrokes data;

  /// 表示している画数（0 = まだ何も書いていない）。
  final int step;

  /// いま書いている画（step 画目）の描画の進み具合（0.0〜1.0）。
  final double progress;

  final bool showUpcoming;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    _paintGrid(canvas, side);

    canvas.save();
    canvas.scale(side / kanjiVgSize);

    Paint strokePaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final done = strokePaint(colorScheme.onSurface);
    final current = strokePaint(Colors.red.shade600);
    final upcoming = strokePaint(colorScheme.onSurface.withValues(alpha: 0.12));

    for (var i = 0; i < data.length; i++) {
      final path = data.strokes[i];
      if (i < step - 1) {
        canvas.drawPath(path, done);
      } else if (i == step - 1) {
        if (showUpcoming) canvas.drawPath(path, upcoming);
        canvas.drawPath(_partial(path, progress), current);
      } else if (showUpcoming) {
        canvas.drawPath(path, upcoming);
      }
    }

    // 書いた画の番号を表示する。
    for (var i = 0; i < step && i < data.numberPositions.length; i++) {
      _paintNumber(
        canvas,
        '${i + 1}',
        data.numberPositions[i],
        i == step - 1 ? Colors.red.shade600 : colorScheme.outline,
      );
    }
    canvas.restore();
  }

  /// 練習用の田の字のマス目。
  void _paintGrid(Canvas canvas, double side) {
    final border = Paint()
      ..color = colorScheme.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final guide = Paint()
      ..color = colorScheme.outlineVariant
      ..strokeWidth = 1;

    canvas.drawRect(Rect.fromLTWH(0, 0, side, side), border);
    const dash = 6.0;
    for (double t = 0; t < side; t += dash * 2) {
      final end = (t + dash).clamp(0.0, side);
      canvas.drawLine(Offset(side / 2, t), Offset(side / 2, end), guide);
      canvas.drawLine(Offset(t, side / 2), Offset(end, side / 2), guide);
    }
  }

  /// パスの先頭から [fraction] の長さだけを切り出す。
  Path _partial(Path path, double fraction) {
    if (fraction >= 1) return path;
    final result = Path();
    for (final metric in path.computeMetrics()) {
      result.addPath(
        metric.extractPath(0, metric.length * fraction),
        Offset.zero,
      );
    }
    return result;
  }

  void _paintNumber(Canvas canvas, String text, Offset baseline, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // KanjiVG の座標は文字のベースライン位置。
    painter.paint(
      canvas,
      baseline -
          Offset(
            0,
            painter.computeDistanceToActualBaseline(TextBaseline.alphabetic),
          ),
    );
  }

  @override
  bool shouldRepaint(StrokePainter old) =>
      old.data != data ||
      old.step != step ||
      old.progress != progress ||
      old.showUpcoming != showUpcoming ||
      old.colorScheme != colorScheme;
}
