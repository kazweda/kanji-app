import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

/// KanjiVG の座標系（viewBox="0 0 109 109"）の一辺の長さ。
const double kanjiVgSize = 109;

/// KanjiVG の SVG から取り出した、1 文字分の書き順データ。
class KanjiStrokes {
  const KanjiStrokes({required this.strokes, required this.numberPositions});

  /// 書き順どおりに並んだ各画のパス（KanjiVG 座標系）。
  final List<Path> strokes;

  /// 各画の画数番号を表示する位置（KanjiVG 座標系）。
  final List<Offset> numberPositions;

  int get length => strokes.length;

  /// KanjiVG の SVG 文字列を解析する。
  factory KanjiStrokes.parse(String svg) {
    final doc = XmlDocument.parse(svg);

    // 画のパスは id が "kvg:XXXXX-sN" の path 要素。N の順に並べる。
    final strokeRe = RegExp(r'-s(\d+)$');
    final paths = <(int, Path)>[];
    for (final el in doc.findAllElements('path')) {
      final m = strokeRe.firstMatch(el.getAttribute('id') ?? '');
      final d = el.getAttribute('d');
      if (m == null || d == null) continue;
      paths.add((int.parse(m.group(1)!), parseSvgPathData(d)));
    }
    paths.sort((a, b) => a.$1.compareTo(b.$1));

    // 画数番号は transform="matrix(1 0 0 1 x y)" の text 要素。
    final numbers = <(int, Offset)>[];
    for (final el in doc.findAllElements('text')) {
      final n = int.tryParse(el.innerText.trim());
      final values = RegExp(r'-?[\d.]+')
          .allMatches(el.getAttribute('transform') ?? '')
          .map((m) => double.parse(m.group(0)!))
          .toList();
      if (n == null || values.length < 6) continue;
      numbers.add((n, Offset(values[4], values[5])));
    }
    numbers.sort((a, b) => a.$1.compareTo(b.$1));

    return KanjiStrokes(
      strokes: [for (final p in paths) p.$2],
      numberPositions: [for (final n in numbers) n.$2],
    );
  }

  /// アセットに同梱した KanjiVG の SVG を読み込む。
  static Future<KanjiStrokes> load(String kanji) async {
    final svg = await rootBundle.loadString(assetPathFor(kanji));
    return KanjiStrokes.parse(svg);
  }

  /// KanjiVG のファイル名は Unicode コードポイントの 5 桁 16 進数。
  static String assetPathFor(String kanji) {
    final hex = kanji.runes.first.toRadixString(16).padLeft(5, '0');
    return 'assets/kanjivg/$hex.svg';
  }
}
