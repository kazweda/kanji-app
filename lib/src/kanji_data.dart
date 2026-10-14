/// 練習問題の 1 文字分の情報。
class KanjiEntry {
  const KanjiEntry(this.kanji, this.reading);

  final String kanji;
  final String reading;
}

/// 練習する漢字（小学 1 年生で習う漢字から 10 字）。
/// 各文字の SVG は assets/kanjivg/ に同梱している。
const kanjiList = [
  KanjiEntry('一', 'イチ・ひと(つ)'),
  KanjiEntry('山', 'サン・やま'),
  KanjiEntry('川', 'セン・かわ'),
  KanjiEntry('日', 'ニチ・ひ'),
  KanjiEntry('月', 'ゲツ・つき'),
  KanjiEntry('木', 'モク・き'),
  KanjiEntry('水', 'スイ・みず'),
  KanjiEntry('火', 'カ・ひ'),
  KanjiEntry('右', 'ウ・みぎ'),
  KanjiEntry('学', 'ガク・まな(ぶ)'),
];
