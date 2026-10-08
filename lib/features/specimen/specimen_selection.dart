import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/specimen_list.dart';
import '../../services/service_providers.dart';
import '../identification/identify_screen.dart';
import 'bulk_edit_screen.dart';
import 'specimen_group_tile.dart';

/// 標本の選択モードの状態(標本一覧 S-04 と地点詳細 S-03 で共通)。
///
/// 行は標本のまとまりなので、行をタップすると、行の標本をまとめて選ぶ。
/// 行を展開すると、標本を1件ずつ選べる(5件の行から2件だけ、など)。
class SpecimenSelection {
  /// 選択モードか。上部の「選択」ボタンか、行の長押しで入る。何も選んでいなくても、選択モードのままにする。
  var mode = false;

  /// 選んだ標本(標本の ID)。
  final selected = <int>{};

  /// 展開して、標本を1件ずつ見せている行(行の先頭の標本の ID で数える)。
  final expanded = <int>{};

  void exit() {
    mode = false;
    selected.clear();
    expanded.clear();
  }

  /// ごみ箱に移すなどで、一覧から消えた標本を、選択から外す。
  void prune(Set<int> existing) {
    selected.removeWhere((id) => !existing.contains(id));
  }

  static Set<int> idsOf(SpecimenGroup g) => {for (final i in g.items) i.id};

  /// 行の標本を、すべて選んでいる。
  bool isFull(SpecimenGroup g) => selected.containsAll(idsOf(g));

  /// 行の標本の一部だけを選んでいる。
  bool isPartial(SpecimenGroup g) {
    final n = idsOf(g).where(selected.contains).length;
    return n > 0 && n < g.count;
  }

  /// 行の標本をまとめて選ぶ。すべて選んでいれば外す(一部だけのときは、すべてを選ぶ)。
  void toggleGroup(SpecimenGroup g) {
    final ids = idsOf(g);
    isFull(g) ? selected.removeAll(ids) : selected.addAll(ids);
  }

  void toggleItem(int id) => selected.contains(id) ? selected.remove(id) : selected.add(id);

  bool isExpanded(SpecimenGroup g) => expanded.contains(g.first.id);

  void toggleExpanded(SpecimenGroup g) => isExpanded(g) ? expanded.remove(g.first.id) : expanded.add(g.first.id);

  /// 表示している標本をすべて選ぶ。すべて選んでいれば、すべて外す。
  void toggleAll(Set<int> visible) => selected.containsAll(visible) ? selected.clear() : selected.addAll(visible);
}

/// 一覧の1行。選択モードでは、行ごとに選べ、展開して標本を1件ずつ選べる。
class SpecimenGroupRow extends StatelessWidget {
  const SpecimenGroupRow({
    super.key,
    required this.group,
    required this.selection,
    required this.onChanged,
    this.showPlace = true,
    this.withYear = true,
  });

  final SpecimenGroup group;
  final SpecimenSelection selection;

  /// 選択の状態が変わったとき(画面を作り直す)。
  final VoidCallback onChanged;
  final bool showPlace;
  final bool withYear;

  @override
  Widget build(BuildContext context) {
    final selecting = selection.mode;
    final expanded = selecting && selection.isExpanded(group);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpecimenGroupTile(
          group: group,
          showPlace: showPlace,
          withYear: withYear,
          selecting: selecting,
          selected: selection.isFull(group),
          partial: selection.isPartial(group),
          // 標本が2件以上の行は、展開して1件ずつ選べる
          expandable: selecting && group.count > 1,
          expanded: expanded,
          onToggleExpand: () {
            selection.toggleExpanded(group);
            onChanged();
          },
          onTap: selecting
              ? () {
                  selection.toggleGroup(group);
                  onChanged();
                }
              : () => openSpecimenGroup(context, group),
          // 長押しで選択モードに入る(行ごとにまとめて選ぶ)
          onLongPress: () {
            selection.mode = true;
            selection.toggleGroup(group);
            onChanged();
          },
        ),
        if (expanded)
          for (final item in group.items)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 56, right: 8),
              leading: Checkbox(
                value: selection.selected.contains(item.id),
                onChanged: (_) {
                  selection.toggleItem(item.id);
                  onChanged();
                },
              ),
              title: Text(item.catalogDisplay),
              subtitle: Text(item.printed ? '印刷済み' : '未印刷'),
              trailing: IconButton(
                tooltip: '${item.catalogDisplay}の詳細を開く',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => context.push('/specimens/${item.id}'),
              ),
              onTap: () {
                selection.toggleItem(item.id);
                onChanged();
              },
            ),
        const Divider(height: 1),
      ],
    );
  }
}

/// 選択モードの上部(選んだ件数と、全て選択)。
AppBar buildSelectionAppBar({
  required SpecimenSelection selection,
  required Set<int> visible,
  required VoidCallback onExit,
  required VoidCallback onChanged,
}) {
  final all = selection.selected.containsAll(visible) && visible.isNotEmpty;
  return AppBar(
    leading: IconButton(tooltip: '選択を解除', icon: const Icon(Icons.close), onPressed: onExit),
    title: Text(selection.selected.isEmpty ? '標本を選んでください' : '${selection.selected.length}件を選択'),
    actions: [
      TextButton(
        onPressed: () {
          selection.toggleAll(visible);
          onChanged();
        },
        child: Text(all ? '全て解除' : '全て選択'),
      ),
    ],
  );
}

/// 選択モードの操作(要件定義 S-04・S-03)。画面下に、ラベル出力・一括編集・同定を追加・番号確定・削除を出す。
/// 何も選んでいないときは、押せない。
class SpecimenSelectionBar extends ConsumerWidget {
  const SpecimenSelectionBar({super.key, required this.selectedIds, required this.onDone});

  final Set<int> selectedIds;

  /// 操作が済んだとき(選択モードを抜ける)。
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = selectedIds.toList()..sort();
    final enabled = ids.isNotEmpty;
    Widget action(IconData icon, String label, VoidCallback onTap) => Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.38,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(icon), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 12))],
            ),
          ),
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
              if (done == true && context.mounted) onDone();
            }),
            action(Icons.fact_check, '同定を追加', () async {
              final done = await context.push<bool>('/identify', extra: IdentifyArgs(ids));
              if (done == true && context.mounted) onDone();
            }),
            action(Icons.pin, '番号確定', () => _confirmNumbers(context, ref, ids)),
            action(Icons.delete_outline, '削除', () => _delete(context, ref, ids)),
          ],
        ),
      ),
    );
  }

  /// 選んだ標本のうち、番号が未確定(仮)の標本に、番号を付ける(要件定義 第14章)。保存した順に、続きの番号を付ける。
  Future<void> _confirmNumbers(BuildContext context, WidgetRef ref, List<int> ids) async {
    final selected = ids.toSet();
    final pending = (ref.read(specimenItemsProvider).value ?? const <SpecimenListItem>[])
        .where((i) => selected.contains(i.id) && i.provisional)
        .length;
    if (pending == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('選んだ標本に、番号が未確定のものはありません')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$pending件の番号を確定しますか'),
        content: const Text('番号が未確定の標本に、保存した順に、続きの番号を付けます。確定した番号は戻せません。個体数などを直す場合は、先に直してください。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('やめる')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('番号を確定')),
        ],
      ),
    );
    if (ok != true) return;
    final result = await ref.read(catalogNumberServiceProvider).confirm(ids);
    if (!context.mounted) return;
    onDone();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result.count}件の番号を確定しました(${result.range})')));
  }

  /// ごみ箱に移す。期間内なら、ごみ箱から元に戻せる。
  Future<void> _delete(BuildContext context, WidgetRef ref, List<int> ids) async {
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
    if (!context.mounted) return;
    onDone();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ids.length}件をごみ箱に移しました')));
  }
}
