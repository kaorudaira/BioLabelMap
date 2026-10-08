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
import 'bulk_edit_screen.dart';
import '../record/form_block.dart';
import '../record/record_form.dart';
import '../record/record_screen.dart';
import 'species_name_text.dart';
import 'status_mark.dart';

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
          // 画面下の操作(要件定義 S-05):編集、同地点で追加、ラベル出力、削除
          bottomNavigationBar: Material(
            elevation: 8,
            child: SafeArea(
              child: Row(
                children: [
                  _BarAction(
                    icon: Icons.edit,
                    label: '編集',
                    onTap: () => context.push(
                      '/bulk-edit',
                      extra: BulkEditArgs([d.specimen.id], initial: d),
                    ),
                  ),
                  _BarAction(
                    icon: Icons.add_location_alt,
                    label: '同地点で追加',
                    onTap: () => context.push(
                      '/record',
                      extra: RecordArgs(RecordForm.fromEvent(d.event, d.locality)),
                    ),
                  ),
                  _BarAction(
                    icon: Icons.print,
                    label: 'ラベル出力',
                    onTap: () => context.push('/labels', extra: [d.specimen.id]),
                  ),
                  _BarAction(icon: Icons.delete_outline, label: '削除', onTap: () => _delete(context, ref, d)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ごみ箱に移して、一覧に戻る。
  Future<void> _delete(BuildContext context, WidgetRef ref, SpecimenDetail d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${d.specimen.catalogText}をごみ箱に移しますか'),
        content: const Text('30日以内なら、ごみ箱から元の標本番号のまま戻せます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('やめる')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ごみ箱に移す')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(specimenEditServiceProvider).moveToTrash([d.specimen.id]);
    if (!context.mounted) return;
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ごみ箱に移しました')));
  }

  Widget _identification(BuildContext context, SpecimenDetail d) {
    final latest = d.latest;
    final name = speciesNameOf(latest);
    final status = latest?.status ?? IdentificationStatus.unidentified;
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
          _Field('和名', name.vernacular, mark: status),
          _Field('学名', name.scientific, italic: true, mark: name.vernacular == null ? status : null),
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
    final method = formatSamplingMethod(e.samplingMethod, e.samplingMethodOther);
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
    final placeEn = formatPlaceEn(
      prefecture: l.prefectureEn,
      county: l.countyEn,
      municipality: l.municipalityEn,
      locality: l.localityEn,
    );
    return FormBlock(
      color: BlockColors.location,
      title: '地点',
      children: [
        _Field('地名', placeJa.isEmpty ? _placeFallback(l) : placeJa),
        _Field('地名(英)', placeEn.isEmpty ? null : placeEn),
        _Field('緯度経度', formatLatLon(l.latitude, l.longitude)),
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
            // 種名の左に印を置き、日付と同定者は、種名と同じ位置から始める
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusMark(i.status),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SpeciesNameText(speciesNameOf(i)),
                      Text(
                        [
                          i.dateIdentified?.toIso() ?? _dateOnly(i.createdAt),
                          i.identifiedBy,
                        ].whereType<String>().where((e) => e.isNotEmpty).join('  '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
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
  const _Field(this.label, this.value, {this.italic = false, this.mark}); 

  final String label;
  final String? value;
  final bool italic;

  /// 同定の状態の印を、値の左に付ける。
  final IdentificationStatus? mark;

  @override
  Widget build(BuildContext context) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 同定の印は、項目名の枠の右端に置く。値は、印のある行もない行も、同じ位置から始まる
          SizedBox(
            width: 112,
            child: Row(
              children: [
                Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
                if (mark != null) StatusMark(mark!),
              ],
            ),
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

/// 画面下の操作の1つ(アイコンと名前)。
class _BarAction extends StatelessWidget {
  const _BarAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 12))],
        ),
      ),
    ),
  );
}
