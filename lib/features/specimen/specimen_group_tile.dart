import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../domain/specimen_list.dart';
import '../../services/service_providers.dart';
import 'bulk_edit_screen.dart';
import 'species_name_text.dart';
import 'status_mark.dart';

/// 標本一覧(S-04)と地点詳細(S-03)の1行。種・同定の状態・採集日・場所・採集方法が同じ標本を1行にまとめたもの。
class SpecimenGroupTile extends StatelessWidget {
  const SpecimenGroupTile({
    super.key,
    required this.group,
    required this.onTap,
    this.onLongPress,
    this.showPlace = true,
    this.withYear = true,
    this.selecting = false,
    this.selected = false,
    this.partial = false,
    this.expandable = false,
    this.expanded = false,
    this.onToggleExpand,
  });

  final SpecimenGroup group;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// 採集日の右に地名を出す。地点詳細は同じ場所なので出さない。
  final bool showPlace;

  /// 採集日に年を付ける(地点詳細は `6/19〜20` と年を省く)。
  final bool withYear;

  /// 選択モード中か。選択中は、行の左にチェックの丸を出す。
  final bool selecting;
  final bool selected;

  /// 行の標本の一部だけを選んでいる(チェックを「半分」の表示にする)。
  final bool partial;

  /// 展開して、標本を1件ずつ選べる行か。展開しているときは [expanded]。
  final bool expandable;
  final bool expanded;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final first = group.first;
    final theme = Theme.of(context);
    final unidentified = first.species.isEmpty;
    final place = first.placeJa.isEmpty ? first.placeEn : first.placeJa;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: selected || partial ? theme.colorScheme.primaryContainer.withValues(alpha: selected ? 0.5 : 0.25) : null,
          border: const Border(left: BorderSide(color: BlockColors.specimen, width: 6)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selecting)
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 2),
                child: Icon(
                  selected ? Icons.check_circle : (partial ? Icons.remove_circle : Icons.circle_outlined),
                  color: selected || partial ? theme.colorScheme.primary : null,
                  semanticLabel: selected ? '選択中' : (partial ? '一部を選択中' : '未選択'),
                ),
              ),
            // 同定の印は左の枠に置き、和名・採集日・採集方法・件数は、同じ位置から始める
            Padding(padding: const EdgeInsets.only(top: 2), child: StatusMark(first.status)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpeciesNameText(
                    first.species,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: unidentified ? theme.disabledColor : BlockColors.identification,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      formatPeriodText(first.period, withYear: withYear),
                      if (showPlace && place.isNotEmpty) place,
                    ].join('  '),
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
            if (expandable)
              IconButton(
                tooltip: expanded ? '標本を閉じる' : '標本を1件ずつ選ぶ',
                visualDensity: VisualDensity.compact,
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                onPressed: onToggleExpand,
              ),
            if (group.hasLabelMismatch)
              const Tooltip(
                message: 'ラベルと不一致',
                child: Icon(Icons.sync_problem, size: 20, color: warningColor),
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

/// 行をタップしたとき。1件ならそのまま標本詳細へ、複数なら、開く標本を選ぶシートを出す。
/// シートでは、標本ごとの「編集」、見出しの「全てまとめて編集」「選んで編集」もできる。
Future<void> openSpecimenGroup(BuildContext context, SpecimenGroup group) async {
  if (group.count == 1) {
    context.push('/specimens/${group.first.id}');
    return;
  }
  final action = await showModalBottomSheet<_SheetAction>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _GroupSheet(group: group),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _OpenSpecimen(:final id):
      context.push('/specimens/$id');
    case _EditSpecimen(:final id):
      // 1件の編集は、いまの内容を渡して、編集画面を開く
      final detail = await ProviderScope.containerOf(context).read(specimenServiceProvider).detail(id);
      if (detail != null && context.mounted) {
        context.push('/bulk-edit', extra: BulkEditArgs([id], initial: detail));
      }
    case _EditSpecimens(:final ids):
      context.push('/bulk-edit', extra: BulkEditArgs(ids));
  }
}

/// シートで選んだ操作。
sealed class _SheetAction {
  const _SheetAction();
}

final class _OpenSpecimen extends _SheetAction {
  const _OpenSpecimen(this.id);
  final int id;
}

final class _EditSpecimen extends _SheetAction {
  const _EditSpecimen(this.id);
  final int id;
}

final class _EditSpecimens extends _SheetAction {
  const _EditSpecimens(this.ids);
  final List<int> ids;
}

/// 行の標本を1件ずつ見せるシート。
class _GroupSheet extends StatefulWidget {
  const _GroupSheet({required this.group});

  final SpecimenGroup group;

  @override
  State<_GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends State<_GroupSheet> {
  /// 「選んで編集」のために、標本を選んでいる最中か。
  var _choosing = false;
  final _chosen = <int>{};

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SpeciesNameText(
                      group.first.species,
                      suffix: ' ×${group.count}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (_choosing)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => setState(() {
                            _choosing = false;
                            _chosen.clear();
                          }),
                          child: const Text('やめる'),
                        ),
                        FilledButton(
                          onPressed: _chosen.isEmpty
                              ? null
                              : () => Navigator.pop(context, _EditSpecimens(_chosen.toList()..sort())),
                          child: Text('編集(${_chosen.length}件)'),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, _EditSpecimens([for (final i in group.items) i.id])),
                          child: const Text('全てまとめて編集'),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: () => setState(() => _choosing = true),
                          child: const Text('選んで編集'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (_choosing)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text('編集する標本を選んでください', style: theme.textTheme.bodySmall),
              ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in group.items)
                    ListTile(
                      leading: _choosing
                          ? Checkbox(
                              value: _chosen.contains(item.id),
                              onChanged: (_) => setState(() => _toggle(item.id)),
                            )
                          : Icon(
                              item.printed ? Icons.print : Icons.print_disabled,
                              color: item.printed ? null : warningColor,
                            ),
                      title: Text(item.catalogDisplay),
                      subtitle: Text(item.printed ? '印刷済み' : '未印刷'),
                      // 各行の右端に、この標本だけを編集するボタン
                      trailing: _choosing
                          ? null
                          : IconButton(
                              tooltip: '${item.catalogDisplay}を編集',
                              icon: const Icon(Icons.edit),
                              onPressed: () => Navigator.pop(context, _EditSpecimen(item.id)),
                            ),
                      onTap: _choosing ? () => setState(() => _toggle(item.id)) : () => Navigator.pop(context, _OpenSpecimen(item.id)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(int id) => _chosen.contains(id) ? _chosen.remove(id) : _chosen.add(id);
}
