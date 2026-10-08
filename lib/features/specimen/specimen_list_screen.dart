import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/specimen_list.dart';
import '../../domain/status.dart';
import '../../services/service_providers.dart';
import '../common/clear_button.dart';
import 'specimen_filter_sheet.dart';
import 'specimen_selection.dart';

/// 標本一覧(要件定義 S-04)。種・同定の状態・採集日・場所・採集方法が同じ標本は1行にまとめる。
/// 行を長押しするか、上部の「選択」ボタンで選択モードに入り、画面下にラベル出力・一括編集・同定を追加・
/// 番号確定・削除を出す。行を展開すると、標本を1件ずつ選べる。
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
  final _selection = SpecimenSelection();

  void _changed() => setState(() {});

  void _exitSelectMode() => setState(_selection.exit);

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
    // ごみ箱に移したなどで、一覧から消えた標本は選択から外す
    _selection.prune({for (final i in all) i.id});

    return PopScope(
      canPop: !_selection.mode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelectMode();
      },
      child: Scaffold(
        appBar: _selection.mode
            ? buildSelectionAppBar(
                selection: _selection,
                visible: {for (final g in groups) ...SpecimenSelection.idsOf(g)},
                onExit: _exitSelectMode,
                onChanged: _changed,
              )
            : _appBar(),
        body: Column(
          children: [
            if (_filter.hasConditions)
              _ConditionBar(
                filter: _filter,
                onClear: () => setState(
                  () => _filter = _filter.copyWith(
                    place: '',
                    from: null,
                    to: null,
                    methods: const {},
                    statuses: const {},
                    unprintedOnly: false,
                    mismatchOnly: false,
                  ),
                ),
              ),
            Expanded(child: _body(items.isLoading, all.length, groups)),
          ],
        ),
        bottomNavigationBar: _selection.mode
            ? SpecimenSelectionBar(selectedIds: _selection.selected, onDone: _exitSelectMode)
            : null,
      ),
    );
  }

  AppBar _appBar() => AppBar(
    title: _searching
        ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: withClear(
              const InputDecoration(hintText: '種名・地名・標本番号', border: InputBorder.none),
              _searchController,
              onCleared: () => setState(() => _filter = _filter.copyWith(query: '')),
            ),
            onChanged: (v) => setState(() => _filter = _filter.copyWith(query: v)),
          )
        : const Text('標本一覧'),
    actions: [
      IconButton(
        tooltip: '選択',
        icon: const Icon(Icons.checklist),
        onPressed: () => setState(() => _selection.mode = true),
      ),
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
      // 右上のメニュー。ごみ箱の入口(要件定義 S-04)
      PopupMenuButton<String>(
        tooltip: 'メニュー',
        onSelected: (route) => context.push(route),
        itemBuilder: (context) => const [
          PopupMenuItem(value: '/trash', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('ごみ箱'))),
        ],
      ),
    ],
  );

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
        return SpecimenGroupRow(group: groups[i - 1], selection: _selection, onChanged: _changed);
      },
    );
  }

  Future<void> _openFilter() async {
    final result = await showSpecimenFilterSheet(context, _filter);
    if (result != null) setState(() => _filter = result);
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
      if (filter.mismatchOnly) 'ラベルと不一致のみ',
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

