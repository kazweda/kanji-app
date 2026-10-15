# kanji-app

漢字の書き順を 1 画ずつ確認しながら練習できる Flutter Web アプリです。

- 小学 1〜6 年生のセットをメニューから選択（1 年生 80 字・2 年生 160 字・3 年生 200 字・4 年生 202 字・5 年生 193 字・6 年生 191 字、合計 1,026 字）
- 1 回 10 問、選んだ学年の漢字からランダムに出題
- 「次の画」で 1 画ずつ、筆の動きをアニメーションで表示（いまの画は赤）
- 自動再生、前の画に戻る、最初から、お手本のうすい表示の切り替え
- キーボード操作: → / Space で次の画、← で前の画

公開ページ: https://kazweda.github.io/kanji-app/

<img src="docs/qr.svg" alt="公開ページの QR コード" width="160">

## 動かし方

```sh
flutter pub get
flutter run -d chrome
```

## 開発の流れ

`main` ブランチは保護されていて、直接 push できません。

1. ブランチを作って変更を push し、プルリクエストを作る
2. CI（フォーマット、`flutter analyze`、`flutter test`）が通ったらマージする
3. `main` にマージされると、GitHub Pages に自動で公開される

## 漢字データの作り直し

学年ごとの漢字と読み（`lib/src/kanji_data.dart`）は、常用漢字表の音訓から生成しています。
足りない KanjiVG の SVG も `assets/kanjivg/` にダウンロードされます。

```sh
curl -L -o joyo.wiki "https://ja.wikipedia.org/w/index.php?title=常用漢字一覧&action=raw"
python3 tool/generate_kanji_data.py joyo.wiki
```

学年を増やすときは、`tool/generate_kanji_data.py` の `GRADES` に追加して実行します。

## ライセンス

- プログラム（`assets/kanjivg/` 以外）: [MIT License](LICENSE) © kazweda
- 書き順データ（`assets/kanjivg/`）: [KanjiVG](https://kanjivg.tagaini.net) © Ulrich Apel, [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/)

学年別の漢字は学年別漢字配当表（2020 年度施行）、読みは常用漢字表（文化庁）によります。
