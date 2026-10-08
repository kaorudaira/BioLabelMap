import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../domain/models/collection_period.dart';
import '../../domain/specimen_list.dart';
import '../../domain/status.dart';
import '../../services/service_providers.dart';
import '../record/record_form.dart';
import '../record/record_screen.dart';
import 'specimen_group_tile.dart';

/// 地点詳細(要件定義 S-03)。ピンをタップして開く。「どの虫を、いつ採ったか」が上から読める順に並べる。
class LocalityDetailScreen extends ConsumerStatefulWidget {
  const LocalityDetailScreen({super.key, required this.localityId});

  final int localityId;

  @override
  ConsumerState<LocalityDetailScreen> createState() => _LocalityDetailScreenState();
}

class _LocalityDetailScreenState extends ConsumerState<LocalityDetailScreen> {
  /// 並び替え。日付順(既定、新しい日から)と、種ごと。
  var _sort = SpecimenSort.dateDesc;

  @override
  Widget build(BuildContext context) {
    final locality = ref.watch(localityProvider(widget.localityId));
    final items = ref.watch(specimenItemsProvider);
    final l = locality.value;
    if (locality.isLoading || items.isLoading) {
      return Scaffold(appBar: AppBar(title: const Text('地点')), body: const Center(child: CircularProgressIndicator()));
    }
    if (l == null) {
      return Scaffold(appBar: AppBar(title: const Text('地点')), body: const Center(child: Text('地点が見つかりません')));
    }

    // 同じ場所(緯度経度の判定キーが同じ)の標本をすべて出す。地名の修正で地点を複製しても、1つにまとまる
    final here = [
      for (final i in items.value ?? const <SpecimenListItem>[])
        if (i.latE4 == l.latE4 && i.lonE4 == l.lonE4) i,
    ];
    final groups = arrangeSpecimens(here, sort: _sort);
    final span = periodSpanOf(here);
    final placeJa = formatPlaceJa(
      prefecture: l.prefectureJa,
      county: l.countyJa,
      municipality: l.municipalityJa,
      locality: l.localityJa,
    );

    return Scaffold(
      appBar: AppBar(title: Text(placeJa.isEmpty ? '地点' : placeJa)),
      body: ListView(
        children: [
          _Header(locality: l, placeJa: placeJa, count: here.length, span: span),
          if (here.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: SegmentedButton<SpecimenSort>(
                segments: const [
                  ButtonSegment(value: SpecimenSort.dateDesc, label: Text('日付順')),
                  ButtonSegment(value: SpecimenSort.species, label: Text('種ごと')),
                ],
                selected: {_sort},
                onSelectionChanged: (s) => setState(() => _sort = s.first),
              ),
            ),
          if (here.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('この地点の標本はありません'))),
          for (final g in groups) ...[
            SpecimenGroupTile(
              group: g,
              showPlace: false,
              onTap: () => openSpecimenGroup(context, g),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => _addHere(l, here),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('この地点で追加'),
          ),
        ),
      ),
    );
  }

  /// 地点・日時・採集方法をコピーして、記録画面を開く。標本が無い地点は、地点だけを使う。
  Future<void> _addHere(Locality l, List<SpecimenListItem> here) async {
    RecordForm form;
    if (here.isEmpty) {
      form = RecordForm.at(latitude: l.latitude, longitude: l.longitude, existingLocalityId: l.id);
    } else {
      // いちばん新しい採集(採集日が新しく、同じなら標本番号が大きいもの)をコピーする
      final latest = arrangeSpecimens(here).first.items.last;
      final detail = await ref.read(specimenServiceProvider).detail(latest.id);
      if (detail == null || !mounted) return;
      form = RecordForm.fromEvent(detail.event, detail.locality);
    }
    if (mounted) context.push('/record', extra: RecordArgs(form));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.locality, required this.placeJa, required this.count, required this.span});

  final Locality locality;
  final String placeJa;
  final int count;
  final CollectionPeriod? span;

  @override
  Widget build(BuildContext context) {
    final l = locality;
    final theme = Theme.of(context);
    final placeEn = formatPlaceEn(
      prefecture: l.prefectureEn,
      county: l.countyEn,
      municipality: l.municipalityEn,
      locality: l.localityEn,
    );
    final elevation = l.elevationMeters != null
        ? '標高 ${l.elevationMeters!.round()} m'
        : switch (l.elevationStatus) {
            FetchStatus.pending => '標高 取得待ち',
            FetchStatus.unavailable => '標高 取得できません',
            _ => null,
          };
    return Container(
      decoration: BoxDecoration(
        color: BlockColors.location.withValues(alpha: 0.06),
        border: const Border(left: BorderSide(color: BlockColors.location, width: 6)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            placeJa.isEmpty ? (l.placeStatus == FetchStatus.pending ? '地名 取得待ち' : '地名なし') : placeJa,
            style: theme.textTheme.titleLarge?.copyWith(color: BlockColors.location, fontWeight: FontWeight.bold),
          ),
          if (placeEn.isNotEmpty) Text(placeEn),
          const SizedBox(height: 4),
          Text(
            [formatLatLon(l.latitude, l.longitude), ?elevation].join('  '),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            ['$count件', if (span != null) formatPeriodText(span!)].join('、'),
            style: theme.textTheme.titleMedium?.copyWith(color: BlockColors.specimen),
          ),
        ],
      ),
    );
  }
}
