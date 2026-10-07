import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../domain/sampling_method.dart';
import '../../domain/specimen_list.dart';
import '../../domain/status.dart';
import '../../services/service_providers.dart';
import '../../services/specimen_service.dart';
import '../identification/identify_screen.dart';
import '../record/form_block.dart';
import '../record/record_form.dart';
import '../record/record_screen.dart';

/// 標本詳細(要件定義 S-05)。「この虫が何で、いつ、どこで採れたか」が上から読める順に並べる。
class SpecimenDetailScreen extends ConsumerWidget {
  const SpecimenDetailScreen({super.key, required this.specimenId});

  final int specimenId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(specimenDetailProvider(specimenId));
    return detail.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('読み込めませんでした: $e'))),
      data: (d) {
        if (d == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('標本が見つかりません')));
        }
        return Scaffold(
          appBar: AppBar(title: Text(d.specimen.catalogText)),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _identification(context, d),
              _specimen(context, d),
              _collecting(context, d),
              _locality(context, d),
              _history(context, d),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: () => context.push(
                  '/record',
                  extra: RecordArgs(RecordForm.fromEvent(d.event, d.locality)),
                ),
                icon: const Icon(Icons.add_location_alt),
                label: const Text('同地点で追加'),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _identification(BuildContext context, SpecimenDetail d) {
    final latest = d.latest;
    final name = speciesNameOf(latest);
    return FormBlock(
      color: BlockColors.identification,
      title: '同定(最新)',
      trailing: TextButton.icon(
        onPressed: () => context.push(
          '/identify',
          extra: IdentifyArgs([d.specimen.id], initial: name.isEmpty ? null : name),
        ),
        icon: const Icon(Icons.add),
        label: const Text('同定を追加'),
      ),
      children: [
        if (latest == null || name.isEmpty)
          const _Field('種名', '未同定')
        else ...[
          _Field('和名', name.vernacular),
          _Field('学名', name.scientific, italic: true),
          _Field('命名者・年', name.authorship),
          _Field('同定者', latest.identifiedBy),
          _Field('同定日', latest.dateIdentified?.toIso()),
        ],
        _Field('状態', (latest?.status ?? IdentificationStatus.unidentified).label),
      ],
    );
  }

  Widget _specimen(BuildContext context, SpecimenDetail d) {
    final s = d.specimen;
    return FormBlock(
      color: BlockColors.specimen,
      title: '標本',
      children: [
        _Field('標本番号', s.catalogText),
        _Field('性別', switch (s.sex) {
          Sex.male => '♂',
          Sex.female => '♀',
          Sex.unknown => '不明',
          null => null,
        }),
        _Field('メモ', s.remarks),
        _Field('印刷', s.printedAt == null ? '未印刷' : '印刷済み(${_dateTime(s.printedAt!)})'),
      ],
    );
  }

  Widget _collecting(BuildContext context, SpecimenDetail d) {
    final e = d.event;
    final other = e.samplingMethodOther?.trim();
    final method = e.samplingMethod == SamplingMethod.other && other != null && other.isNotEmpty
        ? other
        : e.samplingMethod.nameJa;
    return FormBlock(
      color: BlockColors.collecting,
      title: '採集',
      children: [
        _Field('採集日', formatPeriodText(d.period)),
        _Field('採集方法', method),
        _Field('光源', e.lightSource),
        _Field('ベイト', e.bait),
        _Field('環境', e.habitat),
        _Field('寄主植物', e.hostPlant),
        _Field('採集者', e.collector),
      ],
    );
  }

  Widget _locality(BuildContext context, SpecimenDetail d) {
    final l = d.locality;
    final placeJa = formatPlaceJa(
      prefecture: l.prefectureJa,
      county: l.countyJa,
      municipality: l.municipalityJa,
      locality: l.localityJa,
    );
    final placeEn = [l.localityEn, l.municipalityEn, l.countyEn, l.prefectureEn].whereType<String>().join(', ');
    return FormBlock(
      color: BlockColors.location,
      title: '地点',
      children: [
        _Field('地名', placeJa.isEmpty ? _placeFallback(l) : placeJa),
        _Field('地名(英)', placeEn.isEmpty ? null : placeEn),
        _Field('緯度経度', '${l.latitude.toStringAsFixed(5)}, ${l.longitude.toStringAsFixed(5)}'),
        _Field('精度', l.isManualPosition ? '手動' : (l.accuracyMeters == null ? null : '±${l.accuracyMeters!.round()} m')),
        _Field('標高', l.elevationMeters != null ? '${l.elevationMeters!.round()} m' : _fetchText(l.elevationStatus)),
      ],
    );
  }

  Widget _history(BuildContext context, SpecimenDetail d) {
    return FormBlock(
      color: BlockColors.identification,
      title: '同定履歴',
      children: [
        if (d.history.isEmpty) const Text('同定の記録はありません'),
        for (final i in d.history)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              [
                i.dateIdentified?.toIso() ?? _dateOnly(i.createdAt),
                i.identifiedBy,
                speciesNameOf(i).label,
              ].whereType<String>().where((e) => e.isNotEmpty).join('  '),
            ),
          ),
      ],
    );
  }

  /// 地名が未取得のときの表示。
  static String _placeFallback(Locality l) => _fetchText(l.placeStatus) ?? '';

  static String? _fetchText(FetchStatus s) => switch (s) {
    FetchStatus.pending => '取得待ち',
    FetchStatus.unavailable => '取得できません',
    _ => null,
  };

  static String _dateOnly(DateTime t) => '${t.year}-${_two(t.month)}-${_two(t.day)}';
  static String _dateTime(DateTime t) => '${_dateOnly(t)} ${_two(t.hour)}:${_two(t.minute)}';
  static String _two(int n) => n.toString().padLeft(2, '0');
}

/// 「項目名: 値」の1行。値が無い項目は出さない。
class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.italic = false});

  final String label;
  final String? value;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              v,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
