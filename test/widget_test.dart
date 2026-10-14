import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_app/main.dart';
import 'package:kanji_app/src/kanji_data.dart';
import 'package:kanji_app/src/kanjivg.dart';

/// 小学校で習う画数。KanjiVG の解析結果と一致するか確かめる。
const expectedStrokes = {
  '一': 1,
  '山': 3,
  '川': 3,
  '日': 4,
  '月': 4,
  '木': 4,
  '水': 4,
  '火': 4,
  '右': 5,
  '学': 8,
};

void main() {
  test('すべての漢字の KanjiVG データを解析できる', () {
    expect(kanjiList, hasLength(10));
    for (final entry in kanjiList) {
      final svg = File(KanjiStrokes.assetPathFor(entry.kanji))
          .readAsStringSync();
      final data = KanjiStrokes.parse(svg);
      expect(data.length, expectedStrokes[entry.kanji], reason: entry.kanji);
      expect(data.numberPositions, hasLength(data.length), reason: entry.kanji);
    }
  });

  test('アセットのファイル名はコードポイントの 5 桁 16 進数', () {
    expect(KanjiStrokes.assetPathFor('右'), 'assets/kanjivg/053f3.svg');
  });

  testWidgets('1 画ずつ進めて次の問題へ移れる', (tester) async {
    // スマートフォン程度の縦長画面で確かめる。
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KanjiApp());
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    expect(find.text('第 1 問 / 10'), findsOneWidget);
    // 「一」は 1 画なので、1 回進めると完成する。
    await tester.tap(find.text('次の画'));
    await tester.pumpAndSettle();
    expect(find.textContaining('できあがり'), findsOneWidget);

    await tester.tap(find.text('次の問題へ'));
    await tester.pumpAndSettle();
    expect(find.text('第 2 問 / 10'), findsOneWidget);
    expect(find.text('3 画'), findsOneWidget);
  });
}
