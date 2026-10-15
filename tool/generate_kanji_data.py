#!/usr/bin/env python3
"""学年別の漢字データ（lib/src/kanji_data.dart）と KanjiVG の SVG を用意する。

使い方:
    curl -L -o joyo.wiki "https://ja.wikipedia.org/w/index.php?title=常用漢字一覧&action=raw"
    python3 tool/generate_kanji_data.py joyo.wiki

- 学年ごとの漢字は学年別漢字配当表（2020 年度施行）。常用漢字一覧の学年欄と一致するか確かめる。
- 読みは常用漢字表の音訓から、括弧付きの特別な読みを除いて音読み・訓読みを数個ずつ取る。
- assets/kanjivg/ にない SVG は KanjiVG からダウンロードする。
"""

import re
import subprocess
import sys
from pathlib import Path

GRADES = {
    1: "一右雨円王音下火花貝学気九休玉金空月犬見五口校左三山子四糸字耳七車手十出女小上森"
       "人水正生青夕石赤千川先早草足村大男竹中虫町天田土二日入年白八百文木本名目立力林六",
    2: "引羽雲園遠何科夏家歌画回会海絵外角楽活間丸岩顔汽記帰弓牛魚京強教近兄形計元言原戸古"
       "午後語工公広交光考行高黄合谷国黒今才細作算止市矢姉思紙寺自時室社弱首秋週春書少場色"
       "食心新親図数西声星晴切雪船線前組走多太体台地池知茶昼長鳥朝直通弟店点電刀冬当東答頭"
       "同道読内南肉馬売買麦半番父風分聞米歩母方北毎妹万明鳴毛門夜野友用曜来里理話",
    3: "悪安暗医委意育員院飲運泳駅央横屋温化荷界開階寒感漢館岸起期客究急級宮球去橋業曲局銀"
       "区苦具君係軽血決研県庫湖向幸港号根祭皿仕死使始指歯詩次事持式実写者主守取酒受州拾終"
       "習集住重宿所暑助昭消商章勝乗植申身神真深進世整昔全相送想息速族他打対待代第題炭短談"
       "着注柱丁帳調追定庭笛鉄転都度投豆島湯登等動童農波配倍箱畑発反坂板皮悲美鼻筆氷表秒病"
       "品負部服福物平返勉放味命面問役薬由油有遊予羊洋葉陽様落流旅両緑礼列練路和",
    4: "愛案以衣位茨印英栄媛塩岡億加果貨課芽賀改械害街各覚潟完官管関観願岐希季旗器機議求泣給挙漁"
       "共協鏡競極熊訓軍郡群径景芸欠結建健験固功好香候康佐差菜最埼材崎昨札刷察参産散残氏司試児治"
       "滋辞鹿失借種周祝順初松笑唱焼照城縄臣信井成省清静席積折節説浅戦選然争倉巣束側続卒孫帯隊達"
       "単置仲沖兆低底的典伝徒努灯働特徳栃奈梨熱念敗梅博阪飯飛必票標不夫付府阜富副兵別辺変便包法"
       "望牧末満未民無約勇要養浴利陸良料量輪類令冷例連老労録",
    5: "圧囲移因永営衛易益液演応往桜可仮価河過快解格確額刊幹慣眼紀基寄規喜技義逆久旧救居許境均禁"
       "句型経潔件険検限現減故個護効厚耕航鉱構興講告混査再災妻採際在財罪殺雑酸賛士支史志枝師資飼"
       "示似識質舎謝授修述術準序招証象賞条状常情織職制性政勢精製税責績接設絶祖素総造像増則測属率"
       "損貸態団断築貯張停提程適統堂銅導得毒独任燃能破犯判版比肥非費備評貧布婦武復複仏粉編弁保墓"
       "報豊防貿暴脈務夢迷綿輸余容略留領歴",
    6: "胃異遺域宇映延沿恩我灰拡革閣割株干巻看簡危机揮貴疑吸供胸郷勤筋系敬警劇激穴券絹権憲源厳己"
       "呼誤后孝皇紅降鋼刻穀骨困砂座済裁策冊蚕至私姿視詞誌磁射捨尺若樹収宗就衆従縦縮熟純処署諸除"
       "承将傷障蒸針仁垂推寸盛聖誠舌宣専泉洗染銭善奏窓創装層操蔵臓存尊退宅担探誕段暖値宙忠著庁頂"
       "腸潮賃痛敵展討党糖届難乳認納脳派拝背肺俳班晩否批秘俵腹奮並陛閉片補暮宝訪亡忘棒枚幕密盟模"
       "訳郵優預幼欲翌乱卵覧裏律臨朗論",
}

MAX_ON = 2
MAX_KUN = 3

ROOT = Path(__file__).resolve().parent.parent
SVG_DIR = ROOT / "assets" / "kanjivg"
OUT = ROOT / "lib" / "src" / "kanji_data.dart"
KANJIVG_URL = "https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/{}.svg"


def svg_name(kanji):
    return f"{ord(kanji):05x}"


def parse_joyo(wiki_path):
    """常用漢字一覧の wikitext から {漢字: (学年, [読み])} を作る。

    表の行は "| 番号 || [[wikt:姉|姉]] || 旧字体 || 部首 || 画数 || 学年 || ... || シ、あね"。
    """
    table = {}
    for line in Path(wiki_path).read_text(encoding="utf-8").splitlines():
        m = re.search(r"\[\[wikt:(.)\|\1\]\]", line)
        if not m or not line.startswith("|") or m.group(1) in table:
            continue
        cols = [c.strip() for c in line.split("||")]
        # 注記 <ref>…</ref> の本文にも「、」があるので、区切る前に取り除く。
        readings = re.sub(r"<ref[^>]*/>|<ref[^>]*>.*?</ref>", "", cols[-1])
        table[m.group(1)] = (cols[5], [r.strip() for r in readings.split("、")])
    return table


def format_readings(readings):
    """表示用の読みを作る（例: イチ・イツ・ひと・ひと(つ)）。"""
    # 岡・埼・栃・阜は、都道府県名などに使う括弧付きの読みしかない。
    # そのときに限り、括弧と注記を外して使う。
    if all(not r or r.startswith("（") for r in readings):
        readings = [r.strip("（）") for r in readings]
    ons, kuns = [], []
    for r in readings:
        if not r or r.startswith("（"):
            continue  # 括弧付きは特別な読み（例: 上の「うわ」）
        if re.fullmatch(r"[ァ-ヶー]+", r):
            ons.append(r)
        else:
            # 送り仮名の区切り "ひと-つ" を "ひと(つ)" にする。
            stem, _, okuri = r.partition("-")
            kuns.append(f"{stem}({okuri})" if okuri else stem)
    # 訓読みは「い(きる)・い(かす)・い(ける)」のように同じ読みが並ばないよう、
    # 語幹の違うものを優先して選ぶ。
    stems = set()
    distinct = []
    for k in kuns:
        stem = k.split("(")[0]
        if stem not in stems:
            stems.add(stem)
            distinct.append(k)
    picked = (distinct + [k for k in kuns if k not in distinct])[:MAX_KUN]
    picked.sort(key=kuns.index)
    return "・".join(ons[:MAX_ON] + picked)


def main(wiki_path):
    joyo = parse_joyo(wiki_path)

    for grade, kanji in GRADES.items():
        listed = {k for k, (g, _) in joyo.items() if g == str(grade)}
        if set(kanji) != listed or len(kanji) != len(set(kanji)):
            sys.exit(f"{grade} 年生の漢字が常用漢字一覧と一致しません")

    SVG_DIR.mkdir(parents=True, exist_ok=True)
    for kanji in "".join(GRADES.values()):
        path = SVG_DIR / f"{svg_name(kanji)}.svg"
        if not path.exists():
            print(f"download {kanji} {path.name}")
            url = KANJIVG_URL.format(svg_name(kanji))
            subprocess.run(["curl", "-sfL", "-o", str(path), url], check=True)

    lines = [
        "// tool/generate_kanji_data.py で生成。手で編集しないこと。",
        "// 読みは常用漢字表（文化庁）の音訓による。",
        "",
        "/// 練習問題の 1 文字分の情報。",
        "class KanjiEntry {",
        "  const KanjiEntry(this.kanji, this.reading);",
        "",
        "  final String kanji;",
        "  final String reading;",
        "}",
        "",
        "/// 学年ごとの練習セット。",
        "class KanjiSet {",
        "  const KanjiSet(this.grade, this.entries);",
        "",
        "  final int grade;",
        "  final List<KanjiEntry> entries;",
        "",
        "  String get title => '小学 $grade 年生';",
        "}",
        "",
        "/// 学年別漢字配当表（2020 年度施行）の 1〜6 年生の漢字。",
        "/// 各文字の SVG は assets/kanjivg/ に同梱している。",
        "const kanjiSets = [",
    ]
    for grade, kanji in GRADES.items():
        lines.append(f"  KanjiSet({grade}, [")
        for k in kanji:
            lines.append(f"    KanjiEntry('{k}', '{format_readings(joyo[k][1])}'),")
        lines.append("  ]),")
    lines.append("];")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main(sys.argv[1])
