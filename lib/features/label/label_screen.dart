import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../app/theme.dart';
import '../../core/label/label_pdf.dart';
import '../../domain/elevation_rounding.dart';
import '../../domain/label/data_label_builder.dart';
import '../../domain/label/data_label_layout.dart';
import '../../domain/label/date_range_format.dart';
import '../../domain/label/label_sheet.dart';
import '../../services/label_service.dart';
import '../../services/service_providers.dart';

/// ラベル出力(要件定義 S-07)。段階1はデータラベルとコレクションラベルのみ。
class LabelScreen extends ConsumerStatefulWidget {
  const LabelScreen({super.key});

  @override
  ConsumerState<LabelScreen> createState() => _LabelScreenState();
}

class _LabelScreenState extends ConsumerState<LabelScreen> {
  var _unprintedOnly = true;
  var _arrangement = LabelArrangement.bySpecimen;
  var _cutLines = true;
  var _working = false;

  /// 一覧から外した標本。表示中の標本のうち、これ以外を印刷する。
  final _excluded = <int>{};

  @override
  Widget build(BuildContext context) {
    final candidates = ref.watch(labelCandidatesProvider);
    final visible = [
      for (final c in candidates.value ?? const <LabelCandidate>[])
        if (!_unprintedOnly || !c.printed) c,
    ];
    final targets = [for (final c in visible) if (!_excluded.contains(c.specimen.id)) c];
    // データラベルとコレクションラベルで、1標本2枚
    final pages = LabelSheetSpec.postcard.pagesFor(targets.length * 2);

    return Scaffold(
      appBar: AppBar(title: const Text('ラベル出力')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _options(),
          const SizedBox(height: 12),
          Text('対象の標本 ${targets.length}件', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (candidates.isLoading) const Center(child: CircularProgressIndicator()),
          if (visible.isEmpty && !candidates.isLoading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_unprintedOnly ? '未印刷の標本はありません' : '標本はありません', textAlign: TextAlign.center),
            ),
          for (final group in _groupByEvent(visible)) _groupTile(group),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: targets.isEmpty || _working ? null : () => _create(targets),
            icon: _working
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf),
            label: Text('PDFを作成(${targets.length * 2}枚・$pagesページ)'),
          ),
        ),
      ),
    );
  }

  Widget _options() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('印刷単位: データ+コレクション(同定ラベルは段階3で対応)'),
            const SizedBox(height: 8),
            SegmentedButton<LabelArrangement>(
              segments: const [
                ButtonSegment(value: LabelArrangement.bySpecimen, label: Text('標本ごと')),
                ButtonSegment(value: LabelArrangement.byKind, label: Text('種類ごと')),
              ],
              selected: {_arrangement},
              onSelectionChanged: (s) => setState(() => _arrangement = s.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('未印刷のみ'),
              value: _unprintedOnly,
              onChanged: (v) => setState(() => _unprintedOnly = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('切り取り線'),
              value: _cutLines,
              onChanged: (v) => setState(() => _cutLines = v),
            ),
          ],
        ),
      ),
    );
  }

  /// 同じ採集(同地点・同日)の標本を1行にまとめる。
  List<List<LabelCandidate>> _groupByEvent(List<LabelCandidate> list) {
    final groups = <int, List<LabelCandidate>>{};
    for (final c in list) {
      groups.putIfAbsent(c.event.id, () => []).add(c);
    }
    return groups.values.toList();
  }

  Widget _groupTile(List<LabelCandidate> group) {
    final first = group.first;
    final last = group.last;
    final ids = group.map((c) => c.specimen.id).toSet();
    final selectedCount = ids.where((id) => !_excluded.contains(id)).length;
    final numbers = group.length == 1
        ? first.specimen.catalogText
        : '${first.specimen.catalogText}〜${last.specimen.catalogNumber}';
    final place = [first.locality.municipalityJa, first.locality.localityJa].nonNulls.join();
    final period = formatLabelPeriod(first.toSource(ElevationRounding.tenMeters).period);

    return CheckboxListTile(
      value: selectedCount == 0 ? false : (selectedCount == ids.length ? true : null),
      tristate: true,
      onChanged: (_) => setState(() {
        if (selectedCount == ids.length) {
          _excluded.addAll(ids);
        } else {
          _excluded.removeAll(ids);
        }
      }),
      title: Text('$numbers(${group.length}件)'),
      subtitle: Text(
        [period, first.event.samplingMethod.nameJa, if (place.isNotEmpty) place].join('  '),
      ),
      secondary: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (group.any((c) => c.pendingEnrichment))
            const Text('取得待ち', style: TextStyle(color: warningColor, fontSize: 12)),
          if (group.any((c) => c.printed))
            const Text('印刷済み', style: TextStyle(color: Colors.black54, fontSize: 12))
          else
            const Text('未印刷', style: TextStyle(color: BlockColors.specimen, fontSize: 12)),
        ],
      ),
    );
  }

  // ---- PDF の作成 ----

  Future<void> _create(List<LabelCandidate> targets) async {
    setState(() => _working = true);
    try {
      await _createInner(targets);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _createInner(List<LabelCandidate> targets) async {
    // 1. 補完待ちのまま印刷するか(要件定義 第13章)
    final pending = targets.where((c) => c.pendingEnrichment).length;
    if (pending > 0) {
      final choice = await _ask(
        '標高・地名が未取得の標本が$pending件あります',
        '未取得の標高と地名は、ラベルから省いて印字します。補完したあと、再印刷を促します。',
        ['補完してから印刷', 'そのまま印刷'],
      );
      if (choice == null) return;
      if (choice == 0) {
        final summary = await ref.read(enrichmentSchedulerProvider).trigger();
        _snack(summary.failed > 0 ? '通信できませんでした。あとで自動で再試行します' : '補完しました。内容を確かめてから作成してください');
        return;
      }
    }

    final fonts = await ref.read(labelFontsProvider.future);
    final rounding = ref.read(settingsProvider).value?.elevationRounding ?? ElevationRounding.tenMeters;
    DataLabelLayout layoutOf(LabelCandidate c, {bool allowOmit = true}) => layoutDataLabel(
      buildDataLabel(c.toSource(rounding)),
      measurer: fonts.measurer,
      allowOmitJapanese: allowOmit,
    );
    final layouts = {for (final c in targets) c.specimen.id: layoutOf(c)};

    // 2. 日本語の地名を省くラベルがあれば、省いてよいか確認する(要件定義 第5章)
    final omitted = [for (final c in targets) if (layouts[c.specimen.id]!.japaneseOmitted) c];
    if (omitted.isNotEmpty) {
      final choice = await _ask(
        '日本語の地名を省くラベルが${omitted.length}件あります',
        '文字を小さくしても収まらないため、日本語の地名を省きます。\n'
            '${omitted.take(10).map((c) => c.specimen.catalogText).join('、')}'
            '${omitted.length > 10 ? ' ほか' : ''}',
        ['省いて印刷', '省かない(はみ出す)'],
      );
      if (choice == null) return;
      if (choice == 1) {
        for (final c in omitted) {
          layouts[c.specimen.id] = layoutOf(c, allowOmit: false);
        }
      }
    }

    // 3. PDF を作り、プレビューを開く
    final labels = arrangeLabels(
      [
        for (final c in targets)
          SpecimenLabels(
            specimenId: c.specimen.id,
            catalogText: c.specimen.catalogText,
            dataLabel: layouts[c.specimen.id]!,
          ),
      ],
      _arrangement,
    );
    final bytes = await buildLabelPdf(labels: labels, fonts: fonts, cutLines: _cutLines);
    final overflowing = [for (final c in targets) if (layouts[c.specimen.id]!.overflows) c.specimen.catalogText];
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _PreviewScreen(bytes: bytes, overflowing: overflowing)),
    );

    // 4. 印刷済みにするか(「はい」のときだけ記録する)
    if (!mounted) return;
    final mark = await _ask(
      '印刷済みにしますか',
      '${targets.length}件の標本を印刷済みとして記録します。',
      ['はい', 'いいえ'],
      showCancel: false,
    );
    if (mark == 0) {
      await ref.read(labelServiceProvider).markPrinted(layouts);
      _snack('${targets.length}件を印刷済みにしました');
    }
  }

  /// 選択肢を出す。選ばれた番号を返し、閉じられたら null。
  Future<int?> _ask(
    String title,
    String message,
    List<String> options, {
    bool showCancel = true,
  }) => showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        if (showCancel)
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('やめる')),
        // 最初の選択肢(おすすめ)を右端に、塗りつぶしのボタンで置く
        for (var i = options.length - 1; i >= 1; i--)
          TextButton(onPressed: () => Navigator.pop(context, i), child: Text(options[i])),
        FilledButton(onPressed: () => Navigator.pop(context, 0), child: Text(options[0])),
      ],
    ),
  );

  void _snack(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// PDF のプレビュー。拡大して確認でき、共有・保存・印刷に渡せる。
class _PreviewScreen extends StatelessWidget {
  const _PreviewScreen({required this.bytes, required this.overflowing});

  final List<int> bytes;
  final List<String> overflowing;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: const Text('プレビュー')),
      body: Column(
        children: [
          if (overflowing.isNotEmpty)
            MaterialBanner(
              backgroundColor: warningColor.withValues(alpha: 0.12),
              content: Text('枠からはみ出すラベルがあります: ${overflowing.join('、')}'),
              actions: const [SizedBox.shrink()],
            ),
          Expanded(
            child: PdfPreview(
              build: (_) async => Uint8List.fromList(bytes),
              pdfFileName: 'labels-$date.pdf',
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
            ),
          ),
        ],
      ),
    );
  }
}
