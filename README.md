# kanji-app

漢字の書き順を 1 画ずつ確認しながら練習できる Flutter Web アプリです。

- 小学 1 年生の漢字 10 字（一 山 川 日 月 木 水 火 右 学）を順番に練習
- 「次の画」で 1 画ずつ、筆の動きをアニメーションで表示（いまの画は赤）
- 自動再生、前の画に戻る、最初から、お手本のうすい表示の切り替え
- キーボード操作: → / Space で次の画、← で前の画

公開ページ: https://kazweda.github.io/kanji-app/

## 動かし方

```sh
flutter pub get
flutter run -d chrome
```

## 漢字を追加するには

1. [KanjiVG](https://github.com/KanjiVG/kanjivg/tree/master/kanji) から、その漢字のコードポイント（5 桁の 16 進数）の SVG（例: 右 → `053f3.svg`）を `assets/kanjivg/` に入れる
2. `lib/src/kanji_data.dart` の `kanjiList` に追加する

## ライセンス

書き順データ（`assets/kanjivg/`）は [KanjiVG](https://kanjivg.tagaini.net) のものです。
KanjiVG © Ulrich Apel, [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/)
