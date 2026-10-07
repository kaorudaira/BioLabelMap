import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../domain/specimen_list.dart';
import '../../domain/status.dart';
import '../../services/service_providers.dart';
import 'specimen_filter_sheet.dart';
import 'status_mark.dart';

/// 標本一覧(要件定義 S-04)。種・採集日・場所・採集方法が同じ標本は1行にまとめる。
class SpecimenListScreen extends ConsumerStatefulWidget {
  const SpecimenListScreen({super.key});

  @override
  ConsumerState<SpecimenListScreen> createState() => _SpecimenListScreenState();
}

class _SpecimenListScreenState extends ConsumerState<SpecimenListScreen> {
  var _filter = const SpecimenFilter();
  var _sort = SpecimenSort.dateDesc;
  var _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(specimenItemsProvider);
    final all = items.value ?? const <SpecimenListItem>[];
    final groups = arrangeSpecimens(all, filter: _filter, sort: _sort);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(hintText: '種名・地名・標本番号', border: InputBorder.none),
                onChanged: (v) => setState(() => _filter = _filter.copyWith(query: v)),
              )
            : const Text('標本一覧'),
        actions: [
          IconButton(
            tooltip: _searching ? '検索を閉じる' : '検索',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _searchController.clear();
                _filter = _filter.copyWith(query: '');
              }
            }),
          ),
          IconButton(
            tooltip: '絞り込み',
            icon: Badge(isLabelVisible: _filter.hasConditions, child: const Icon(Icons.filter_list)),
            onPressed: _openFilter,
          ),
          PopupMenuButton<SpecimenSort>(
            tooltip: '並び替え',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (context) => [
              for (final s in SpecimenSort.values) CheckedPopupMenuItem(value: s, checked: s == _sort, child: Text(s.label)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filter.hasConditions) _ConditionBar(filter: _filter, onClear: () => setState(() => _filter = _filter.copyWith(
            place: '',
            from: null,
            to: null,
            methods: const {},
            statuses: const {},
            unprintedOnly: false,
          ))),
          Expanded(child: _body(items.isLoading, all.length, groups)),
        ],
      ),
    );
  }

  Widget _body(bool loading, int total, List<SpecimenGroup> groups) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (total == 0) return const Center(child: Text('標本はまだありません'));
    if (groups.isEmpty) return const Center(child: Text('条件に合う標本はありません'));
    final count = groups.fold<int>(0, (sum, g) => sum + g.count);
    return ListView.builder(
      itemCount: groups.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('標本 $count件(${groups.length}行)', style: Theme.of(context).textTheme.bodySmall),
          );
        }
        final group = groups[i - 1];
        // 行と行の間に区切りの線を入れる
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GroupTile(group: group, onTap: () => _open(group)),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  Future<void> _openFilter() async {
    final result = await showSpecimenFilterSheet(context, _filter);
    if (result != null) setState(() => _filter = result);
  }

  /// 1件ならそのまま詳細へ。複数なら、どの標本を開くか選ぶ。
  Future<void> _open(SpecimenGroup group) async {
    if (group.count == 1) {
      context.push('/specimens/${group.first.id}');
      return;
    }
    final id = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('${group.first.species.label} ×${group.count}', style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final item in group.items)
              ListTile(
                leading: Icon(item.printed ? Icons.print : Icons.print_disabled, color: item.printed ? null : warningColor),
                title: Text(item.catalogText),
                subtitle: Text(item.printed ? '印刷済み' : '未印刷'),
                onTap: () => Navigator.pop(context, item.id),
              ),
          ],
        ),
      ),
    );
    if (id != null && mounted) context.push('/specimens/$id');
  }
}

/// 絞り込み中の条件を、画面上部に示す(要件定義 S-04)。
class _ConditionBar extends StatelessWidget {
  const _ConditionBar({required this.filter, required this.onClear});

  final SpecimenFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final labels = [
      if (filter.place.trim().isNotEmpty) '地名: ${filter.place.trim()}',
      if (filter.from != null || filter.to != null) '採集日: ${filter.from ?? ''}〜${filter.to ?? ''}',
      if (filter.methods.isNotEmpty) '採集方法: ${filter.methods.map((m) => m.nameJa).join('・')}',
      if (filter.statuses.isNotEmpty) '同定: ${filter.statuses.map((s) => s.label).join('・')}',
      if (filter.unprintedOnly) '未印刷のみ',
    ];
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Row(
          children: [
            Expanded(child: Text(labels.join(' / '), style: Theme.of(context).textTheme.bodySmall)),
            TextButton(onPressed: onClear, child: const Text('解除')),
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onTap});

  final SpecimenGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final first = group.first;
    final theme = Theme.of(context);
    final unidentified = first.species.isEmpty;
    final place = first.placeJa.isEmpty ? first.placeEn : first.placeJa;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: BlockColors.specimen, width: 6)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusMark(first.status),
                      Flexible(
                        child: Text(
                          first.species.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: unidentified ? theme.disabledColor : BlockColors.identification,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [formatPeriodText(first.period), if (place.isNotEmpty) place].join('  '),
                    style: theme.textTheme.bodyMedium?.copyWith(color: BlockColors.location),
                  ),
                  Text(first.methodLabel, style: theme.textTheme.bodySmall?.copyWith(color: BlockColors.collecting)),
                  const SizedBox(height: 2),
                  Text(
                    '×${group.count}  ${group.catalogRuns}',
                    style: theme.textTheme.bodySmall?.copyWith(color: BlockColors.specimen),
                  ),
                ],
              ),
            ),
            if (group.hasUnprinted)
              const Tooltip(
                message: '未印刷',
                child: Icon(Icons.print_disabled, size: 20, color: warningColor),
              ),
          ],
        ),
      ),
    );
  }
}
