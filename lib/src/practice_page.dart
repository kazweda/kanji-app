import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kanji_data.dart';
import 'kanjivg.dart';
import 'stroke_painter.dart';

/// 書き順を 1 画ずつ進めながら練習する画面。
class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage>
    with SingleTickerProviderStateMixin {
  late final Future<List<KanjiStrokes>> _strokes = Future.wait([
    for (final e in kanjiList) KanjiStrokes.load(e.kanji),
  ]);

  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..addStatusListener(_onDrawStatus);

  final _focusNode = FocusNode();

  int _index = 0;
  int _step = 0;
  bool _autoPlay = false;
  bool _showUpcoming = true;

  // 現在の問題の画数。データ読み込み後に build で更新する。
  int _strokeCount = 0;

  bool get _finished => _index >= kanjiList.length;

  @override
  void dispose() {
    _draw.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onDrawStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _autoPlay) {
      if (_step < _strokeCount) {
        _nextStroke();
      } else {
        setState(() => _autoPlay = false);
      }
    }
  }

  void _nextStroke() {
    if (_step >= _strokeCount) return;
    setState(() => _step++);
    _draw.forward(from: 0);
  }

  void _prevStroke() {
    if (_step == 0) return;
    setState(() {
      _step--;
      _autoPlay = false;
    });
    _draw.value = 1;
  }

  void _restart() {
    setState(() {
      _step = 0;
      _autoPlay = false;
    });
    _draw.value = 0;
  }

  void _toggleAutoPlay() {
    if (_autoPlay) {
      setState(() => _autoPlay = false);
      return;
    }
    setState(() {
      _autoPlay = true;
      if (_step >= _strokeCount) _step = 0;
    });
    _nextStroke();
  }

  void _goTo(int index) {
    setState(() {
      _index = index;
      _step = 0;
      _autoPlay = false;
    });
    _draw.value = 0;
  }

  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder(
        future: _strokes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('データを読み込めませんでした: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_finished) return _buildFinished(context);

          final data = snapshot.data![_index];
          _strokeCount = data.length;
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowRight): _nextStroke,
              const SingleActivator(LogicalKeyboardKey.space): _nextStroke,
              const SingleActivator(LogicalKeyboardKey.arrowLeft): _prevStroke,
            },
            child: Focus(
              focusNode: _focusNode,
              autofocus: true,
              child: _buildPractice(context, data),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPractice(BuildContext context, KanjiStrokes data) {
    final theme = Theme.of(context);
    final entry = kanjiList[_index];
    final isLast = _index == kanjiList.length - 1;
    final complete = _step >= data.length;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '第 ${_index + 1} 問 / ${kanjiList.length}',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (_index + 1) / kanjiList.length),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(entry.kanji, style: theme.textTheme.displaySmall),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.reading, style: theme.textTheme.titleMedium),
                      Text(
                        '${data.length} 画',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1,
                child: GestureDetector(
                  onTap: complete ? null : _nextStroke,
                  child: AnimatedBuilder(
                    animation: _draw,
                    builder: (context, _) => CustomPaint(
                      painter: StrokePainter(
                        data: data,
                        step: _step,
                        progress: _draw.value,
                        showUpcoming: _showUpcoming,
                        colorScheme: theme.colorScheme,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _step == 0
                    ? '「次の画」かマスをタップして 1 画目から'
                    : complete
                    ? 'できあがり！（全 ${data.length} 画）'
                    : '$_step / ${data.length} 画目',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _step > 0 ? _prevStroke : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('前の画'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: complete
                        ? FilledButton.icon(
                            onPressed: () => _goTo(_index + 1),
                            icon: Icon(
                              isLast ? Icons.flag : Icons.arrow_forward,
                            ),
                            label: Text(isLast ? 'おわる' : '次の問題へ'),
                          )
                        : FilledButton.icon(
                            onPressed: _nextStroke,
                            icon: const Icon(Icons.chevron_right),
                            label: const Text('次の画'),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _toggleAutoPlay,
                    icon: Icon(_autoPlay ? Icons.pause : Icons.play_arrow),
                    label: Text(_autoPlay ? '停止' : '自動再生'),
                  ),
                  TextButton.icon(
                    onPressed: _step > 0 ? _restart : null,
                    icon: const Icon(Icons.replay),
                    label: const Text('最初から'),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: _showUpcoming,
                        onChanged: (v) => setState(() => _showUpcoming = v),
                      ),
                      const Text('お手本をうすく表示'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinished(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              '${kanjiList.length} 問 おわり！',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              kanjiList.map((e) => e.kanji).join(' '),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _goTo(0),
              icon: const Icon(Icons.replay),
              label: const Text('もう一度'),
            ),
          ],
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
          'KanjiVG © Ulrich Apel, CC BY-SA 3.0',
        ),
      ],
    );
  }
}
