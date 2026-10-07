import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/specimen_list.dart';
import '../../domain/status.dart';
import '../../services/service_providers.dart';
import '../identification/identify_screen.dart';
import 'bulk_edit_screen.dart';
import 'specimen_filter_sheet.dart';
import 'specimen_group_tile.dart';

/// 標本一覧(要件定義 S-04)。種・採集日・場所・採集方法が同じ標本は1行にまとめる。
/// 行を長押しすると選択モードに入り、画面下にラベル出力・一括編集・同定を追加・削除を出す。
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

  /// 選んだ標本(標本の ID)。空でなければ選択モード。行は標本のまとまりなので、行ごとにまとめて選ぶ。
  final _selected = <int>{};

  bool get _selecting => _selected.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Set<int> _idsOf(SpecimenGroup g) => {for (final i in g.items) i.id};

  void _toggle(SpecimenGroup g) => setState(() {
    final ids = _idsOf(g);
    if (_selected.containsAll(ids)) {
      _selected.removeAll(ids);
    } else {
      _selected.addAll(ids);
    }
  });

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(specimenItemsProvider);
    final all = items.value ?? const <SpecimenListItem>[];
    final groups = arrangeSpecimens(all, filter: _filter, sort: _sort);
    // ごみ箱に移したなどで、一覧から消えた標本は選択から外す
    final existing = {for (final i in all) i.id};
    _selected.removeWhere((id) => !existing.contains(id));

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        appBar: _selecting ? _selectionAppBar(groups) : _appBar(),
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
                  ),
                ),
              ),
            Expanded(child: _body(items.isLoading, all.length, groups)),
          ],
        ),
        bottomNavigationBar: _selecting ? _selectionBar() : null,
      ),
    );
  }

  AppBar _appBar() => AppBar(
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

  AppBar _selectionAppBar(List<SpecimenGroup> groups) {
    final visible = {for (final g in groups) ..._idsOf(g)};
    return AppBar(
      leading: IconButton(
        tooltip: '選択を解除',
        icon: const Icon(Icons.close),
        onPressed: () => setState(_selected.clear),
      ),
      title: Text('${_selected.length}件を選択'),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _selected.containsAll(visible) ? _selected.clear() : _selected.addAll(visible);
          }),
          child: Text(_selected.containsAll(visible) ? '全て解除' : '全て選択'),
        ),
      ],
    );
  }

  /// 選択モードの操作(要件定義 S-04)。
  Widget _selectionBar() {
    final ids = _selected.toList()..sort();
    Widget action(IconData icon, String label, VoidCallback onTap) => Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 12))]),
        ),
      ),
    );
    return Material(
      elevation: 8,
      child: SafeArea(
        child: Row(
          children: [
            action(Icons.print, 'ラベル出力', () => context.push('/labels', extra: ids)),
            action(Icons.edit_note, '一括編集', () async {
              final done = await context.push<bool>('/bulk-edit', extra: BulkEditArgs(ids));
              if (done == true && mounted) setState(_selected.clear);
            }),
            action(Icons.fact_check, '同定を追加', () async {
              final done = await context.push<bool>('/identify', extra: IdentifyArgs(ids));
              if (done == true && mounted) setState(_selected.clear);
            }),
            action(Icons.delete_outline, '削除', () => _delete(ids)),
          ],
        ),
      ),
    );
  }

  /// ごみ箱に移す。期間内なら、ごみ箱から元に戻せる。
  Future<void> _delete(List<int> ids) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${ids.length}件をごみ箱に移しますか'),
        content: const Text('30日以内なら、ごみ箱から元の標本番号のまま戻せます。30日を過ぎると完全に削除します。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('やめる')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ごみ箱に移す')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(specimenEditServiceProvider).moveToTrash(ids);
    if (!mounted) return;
    setState(_selected.clear);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ids.length}件をごみ箱に移しました')));
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
            SpecimenGroupTile(
              group: group,
              selecting: _selecting,
              selected: _selected.containsAll(_idsOf(group)),
              onTap: _selecting ? () => _toggle(group) : () => openSpecimenGroup(context, group),
              // 長押しで選択モードに入る(行ごとにまとめて選ぶ)
              onLongPress: () => _toggle(group),
            ),
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

