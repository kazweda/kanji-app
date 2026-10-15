import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_app/main.dart';
import 'package:kanji_app/src/kanji_data.dart';
import 'package:kanji_app/src/kanjivg.dart';
import 'package:kanji_app/src/practice_page.dart';

/// 画数がわかっている漢字。KanjiVG の解析結果と一致するか確かめる。
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
  '書': 10,
  '曜': 18,
  '鼻': 14,
  '整': 16,
  '館': 16,
};

/// 書き順データの読み込みが終わるまで待つ。
///
/// アセットの読み込みは実時間で進むので、読み込み中の表示が消えるまで
/// 少しずつ実時間を進める。遅い CI でも待ちきれるよう、上限は長めにとる。
Future<void> pumpUntilLoaded(WidgetTester tester) async {
  final loading = find.byType(CircularProgressIndicator);
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (loading.evaluate().isNotEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail('書き順データの読み込みが 10 秒で終わらなかった');
    }
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  // rootBundle は読み込み中の Future をキャッシュする。前のテストの
  // 偽の時間の中で作られた Future は次のテストでは終わらないので、毎回消す。
  setUp(rootBundle.clear);

  test('1〜3 年生の漢字が学年別漢字配当表の字数どおりにある', () {
    expect([for (final s in kanjiSets) s.grade], [1, 2, 3]);
    expect([for (final s in kanjiSets) s.entries.length], [80, 160, 200]);
    final all = [for (final s in kanjiSets) ...s.entries.map((e) => e.kanji)];
    expect(all.toSet(), hasLength(440));
  });

  test('すべての漢字の KanjiVG データを解析でき、読みがある', () {
    for (final entry in kanjiSets.expand((s) => s.entries)) {
      final svg = File(KanjiStrokes.assetPathFor(entry.kanji))
          .readAsStringSync();
      final data = KanjiStrokes.parse(svg);
      expect(data.length, greaterThan(0), reason: entry.kanji);
      expect(data.numberPositions, hasLength(data.length), reason: entry.kanji);
      expect(entry.reading, isNotEmpty, reason: entry.kanji);
      if (expectedStrokes.containsKey(entry.kanji)) {
        expect(data.length, expectedStrokes[entry.kanji], reason: entry.kanji);
      }
    }
  });

  test('アセットのファイル名はコードポイントの 5 桁 16 進数', () {
    expect(KanjiStrokes.assetPathFor('右'), 'assets/kanjivg/053f3.svg');
  });

  testWidgets('メニューから選んで 10 問解き、メニューへ戻れる', (tester) async {
    // スマートフォン程度の縦長画面で確かめる。
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KanjiApp());
    for (final title in ['小学 1 年生セット', '小学 2 年生セット', '小学 3 年生セット']) {
      expect(find.text(title), findsOneWidget);
    }

    await tester.tap(find.text('小学 2 年生セット'));
    await tester.pump();
    await pumpUntilLoaded(tester);

    final grade2 = kanjiSets[1].entries.map((e) => e.kanji).toSet();
    for (var q = 1; q <= 10; q++) {
      expect(find.text('第 $q 問 / 10'), findsOneWidget);
      // 出題された漢字が 2 年生のものか確かめる。
      final shown = grade2.where((k) => find.text(k).evaluate().isNotEmpty);
      expect(shown, isNotEmpty, reason: '第 $q 問');

      // 書き終わるまで 1 画ずつ進める。
      while (find.text('次の画').evaluate().isNotEmpty) {
        await tester.tap(find.text('次の画'));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('できあがり'), findsOneWidget);
      await tester.tap(find.text(q < 10 ? '次の問題へ' : 'おわる'));
      await tester.pumpAndSettle();
    }

    expect(find.text('10 問 おわり！'), findsOneWidget);
    await tester.tap(find.text('メニューへ'));
    await tester.pumpAndSettle();
    expect(find.text('セットをえらんでね'), findsOneWidget);
  });

  testWidgets('読みの長い漢字も狭い画面からはみ出さない', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final longest = kanjiSets.expand((s) => s.entries).toList()
      ..sort((a, b) => b.reading.length.compareTo(a.reading.length));
    final set = KanjiSet(0, longest.take(questionsPerRound).toList());

    await tester.pumpWidget(MaterialApp(home: PracticePage(kanjiSet: set)));
    await pumpUntilLoaded(tester);
    for (var q = 1; q <= questionsPerRound; q++) {
      // はみ出すとレイアウトのエラーでテストが失敗する。
      expect(tester.takeException(), isNull, reason: '第 $q 問');
      while (find.text('次の画').evaluate().isNotEmpty) {
        await tester.tap(find.text('次の画'));
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.tap(find.text(q < questionsPerRound ? '次の問題へ' : 'おわる'));
      await tester.pumpAndSettle();
    }
    expect(find.text('$questionsPerRound 問 おわり！'), findsOneWidget);
  });
}
