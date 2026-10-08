import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/gsi/oaza_romaji_table.dart';
import '../../core/label/label_pdf.dart';
import '../../domain/elevation_rounding.dart';
import '../../domain/label/data_label_builder.dart';
import '../../domain/label/data_label_layout.dart';
import '../../domain/label/identification_label.dart';
import '../../domain/label/date_range_format.dart';
import '../../domain/label/label_sheet.dart';
import '../../services/label_service.dart';
import '../../services/printed_label_values.dart';
import '../../services/service_providers.dart';
import '../record/macron_buttons.dart';
import '../record/romaji_candidate.dart';

/// ラベル出力(要件定義 S-07)。段階1はデータラベルとコレクションラベルのみ。
class LabelScreen extends ConsumerStatefulWidget {
  const LabelScreen({super.key, this.specimenIds});

  /// 対象の標本。標本一覧や標本詳細から開いたときに、選んだ標本だけを出す。null なら、すべての標本。
  final Set<int>? specimenIds;

  @override
  ConsumerState<LabelScreen> createState() => _LabelScreenState();
}

class _LabelScreenState extends ConsumerState<LabelScreen> {
  // 標本を選んで開いたときは、印刷済みでも対象にする
  late var _unprintedOnly = widget.specimenIds == null;
  var _unit = LabelUnit.dataAndCollection;
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
        if (widget.specimenIds == null || widget.specimenIds!.contains(c.specimen.id))
        // 未印刷のみは、データ・コレクションの印刷状態。同定ラベルだけを出すときは使わない
        // 印刷したラベルと食い違っている標本(補完や修正で標高・地名が変わった)も、再印刷の対象にする
        if (!_unprintedOnly || _unit == LabelUnit.identificationOnly || !c.printed || c.labelMismatch(_rounding)) c,
    ];
    final targets = [for (final c in visible) if (!_excluded.contains(c.specimen.id)) c];
    final identified = targets.where((c) => c.identificationSource != null).length;
    final labelCount = _labelCount(targets.length, identified);
    final pages = LabelSheetSpec.postcard.pagesFor(labelCount);

    return Scaffold(
      appBar: AppBar(title: const Text('ラベル出力')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _options(),
          if (_unit.hasIdentification) _unidentifiedNotice(targets.length - identified),
          if (_unit.hasData) _missingRomajiCard(visible),
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
            onPressed: labelCount == 0 || _working ? null : () => _create(targets),
            icon: _working
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf),
            label: Text('PDFを作成($labelCount枚・$pagesページ)'),
          ),
        ),
      ),
    );
  }

  /// 出力するラベルの枚数。データとコレクションは標本ごとに1枚ずつ、同定ラベルは同定した標本だけ。
  int _labelCount(int targets, int identified) =>
      (_unit.hasData ? targets : 0) + (_unit.hasCollection ? targets : 0) + (_unit.hasIdentification ? identified : 0);

  /// 未同定の標本には、同定ラベルを出さない。除く件数を知らせる(要件定義 S-07)。
  Widget _unidentifiedNotice(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Card(
      color: warningColor.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text('未同定の標本 $count件には、同定ラベルを出しません', style: const TextStyle(color: warningColor)),
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
            const Text('印刷単位'),
            const SizedBox(height: 4),
            SegmentedButton<LabelUnit>(
              segments: [for (final u in LabelUnit.values) ButtonSegment(value: u, label: Text(u.label))],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() => _unit = s.first),
            ),
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
              subtitle: _unit == LabelUnit.identificationOnly ? const Text('同定ラベルだけのときは、印刷状態で絞りません') : null,
              value: _unprintedOnly,
              onChanged: _unit == LabelUnit.identificationOnly ? null : (v) => setState(() => _unprintedOnly = v),
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

  /// 大字のローマ字が未入力の地点(地点ごとに1件)。
  static List<Locality> _localitiesMissingRomaji(List<LabelCandidate> list) => {
    for (final c in list)
      if (c.missingLocalityRomaji) c.locality.id: c.locality,
  }.values.toList();

  /// 大字のローマ字が未入力の地点を知らせ、その場で入力できるようにする。
  /// 圏外で記録した初めての場所は、記録画面でローマ字を入れられないため。
  Widget _missingRomajiCard(List<LabelCandidate> visible) {
    final localities = _localitiesMissingRomaji(visible);
    if (localities.isEmpty) return const SizedBox.shrink();
    return Card(
      color: warningColor.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('大字のローマ字が未入力の地点 ${localities.length}件',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: warningColor)),
            const Text('このままではラベルに大字の英語表記が入りません。'),
            for (final l in localities)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text([l.countyJa, l.municipalityJa, l.localityJa].nonNulls.join()),
                subtitle: Text([l.municipalityEn, l.prefectureEn].nonNulls.join(', ')),
                trailing: OutlinedButton(onPressed: () => _editRomaji(l), child: const Text('入力')),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editRomaji(Locality locality) async {
    final en = await showDialog<String>(
      context: context,
      builder: (context) => _RomajiDialog(
        locality: locality,
        candidate: ref.read(oazaRomajiTableProvider).lookup(locality.municipalityCode, locality.localityJa),
      ),
    );
    if (en == null) return;
    try {
      await ref.read(labelServiceProvider).setLocalityRomaji(locality.id, en);
    } catch (e) {
      _snack('保存できませんでした: $e');
    }
  }

  /// 同じ採集(同地点・同日)の標本を1行にまとめる。
  List<List<LabelCandidate>> _groupByEvent(List<LabelCandidate> list) {
    final groups = <int, List<LabelCandidate>>{};
    for (final c in list) {
      groups.putIfAbsent(c.event.id, () => []).add(c);
    }
    return groups.values.toList();
  }

  ElevationRounding get _rounding => ref.read(settingsProvider).value?.elevationRounding ?? ElevationRounding.tenMeters;

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
          if (group.any((c) => c.labelMismatch(_rounding)))
            const Text('ラベルと不一致', style: TextStyle(color: warningColor, fontSize: 12))
          else if (group.any((c) => c.printed))
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
    // 1. 補完待ちのまま印刷するか(要件定義 第13章)。標高・地名はデータラベルのことなので、同定ラベルだけなら聞かない
    final pending = _unit.hasData ? targets.where((c) => c.pendingEnrichment).length : 0;
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

    // 2. 大字のローマ字が未入力の地点があれば、先に入力するか確認する
    final missing = _unit.hasData ? _localitiesMissingRomaji(targets) : <Locality>[];
    if (missing.isNotEmpty) {
      final choice = await _ask(
        '大字のローマ字が未入力の地点が${missing.length}件あります',
        'このまま印刷すると、ラベルに大字の英語表記が入りません。\n'
            '${missing.take(5).map((l) => [l.municipalityJa, l.localityJa].nonNulls.join()).join('、')}'
            '${missing.length > 5 ? ' ほか' : ''}',
        ['先に入力する', 'そのまま印刷'],
      );
      if (choice == null) return;
      if (choice == 0) {
        _snack('上の「大字のローマ字が未入力の地点」から入力してください');
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

    // 3. 日本語の地名を省くラベルがあれば、省いてよいか確認する(要件定義 第5章)
    final omitted = _unit.hasData ? [for (final c in targets) if (layouts[c.specimen.id]!.japaneseOmitted) c] : <LabelCandidate>[];
    if (omitted.isNotEmpty) {
      final choice = await _ask(
        '日本語の地名を省くラベルが${omitted.length}件あります',
        '${omitted.any((c) => layouts[c.specimen.id]!.japaneseOmittedForDate) ? '日付と採集者が1行に収まらない、または' : ''}'
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

    // 4. PDF を作り、プレビューを開く。同定ラベルは、同定した標本の分だけ作る
    final identificationLayouts = {
      if (_unit.hasIdentification)
        for (final c in targets)
          if (c.identificationSource case final source?)
            c.specimen.id: layoutIdentificationLabel(source, measurer: fonts.measurer),
    };
    final labels = arrangeLabels(
      [
        for (final c in targets)
          SpecimenLabels(
            specimenId: c.specimen.id,
            catalogText: c.specimen.catalogText,
            dataLabel: layouts[c.specimen.id]!,
            identificationLabel: identificationLayouts[c.specimen.id],
          ),
      ],
      _arrangement,
      unit: _unit,
    );
    final bytes = await buildLabelPdf(labels: labels, fonts: fonts, cutLines: _cutLines);
    final overflowing = [
      if (_unit.hasData)
        for (final c in targets)
          if (layouts[c.specimen.id]!.overflows) c.specimen.catalogText,
      for (final c in targets)
        if (identificationLayouts[c.specimen.id]?.overflows ?? false) '${c.specimen.catalogText}(同定)',
    ];
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _PreviewScreen(bytes: bytes, overflowing: overflowing)),
    );

    // 5. 印刷済みにするか(「はい」のときだけ記録する)。印刷済みは、データ・コレクションの印刷状態なので、同定ラベルだけのときは聞かない
    if (!mounted || !_unit.hasData) return;
    final mark = await _ask(
      '印刷済みにしますか',
      '${targets.length}件の標本を印刷済みとして記録します。',
      ['はい', 'いいえ'],
      showCancel: false,
    );
    if (mark == 0) {
      await ref.read(labelServiceProvider).markPrinted({
        for (final c in targets) c.specimen.id: currentLabelValues(c.locality, rounding),
      });
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

/// 大字のローマ字の入力。入力した綴りを返し、やめたら null。
class _RomajiDialog extends StatefulWidget {
  const _RomajiDialog({required this.locality, this.candidate});

  final Locality locality;

  /// 公的データから作った候補。
  final OazaRomaji? candidate;

  @override
  State<_RomajiDialog> createState() => _RomajiDialogState();
}

class _RomajiDialogState extends State<_RomajiDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final en = _controller.text.trim();
    if (en.isNotEmpty) Navigator.pop(context, en);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.locality;
    return AlertDialog(
      title: Text('${l.localityJa} のローマ字'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text([l.countyJa, l.municipalityJa, l.localityJa].nonNulls.join()),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '大字のローマ字',
              hintText: '例: Shimooritate',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 6),
          MacronButtons(controller: _controller, onInserted: () => setState(() {})),
          if (_controller.text.trim().isEmpty)
            if (widget.candidate case final candidate?)
              RomajiCandidate(
                candidate: candidate,
                onUse: () => setState(() => _controller.text = candidate.value),
              ),
          const SizedBox(height: 6),
          Text('同じ大字のほかの地点にも入り、次に記録するときは自動で入ります。',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('やめる')),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty ? null : _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
