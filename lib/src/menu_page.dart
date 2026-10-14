import 'package:flutter/material.dart';

import 'kanji_data.dart';
import 'practice_page.dart';

/// 学年ごとの練習セットを選ぶ画面。
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('漢字 書き順練習'),
        actions: [
          IconButton(
            tooltip: 'このアプリについて',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'セットをえらんでね',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '1 回 $questionsPerRound 問、ランダムに出題されます',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                for (final set in kanjiSets)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        child: Text(
                          set.entries.first.kanji,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      title: Text('${set.title}セット'),
                      subtitle: Text(
                        '${set.entries.length} 字　'
                        '${set.entries.take(5).map((e) => e.kanji).join(' ')} …',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PracticePage(kanjiSet: set),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '漢字 書き順練習',
      children: const [
        Text(
          '書き順データは KanjiVG（https://kanjivg.tagaini.net）を使用しています。\n'
          'KanjiVG © Ulrich Apel, CC BY-SA 3.0\n\n'
          '学年別の漢字は学年別漢字配当表、読みは常用漢字表（文化庁）によります。',
        ),
      ],
    );
  }
}
