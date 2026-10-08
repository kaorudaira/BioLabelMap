import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../domain/specimen_list.dart';
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
          color: selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
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
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? theme.colorScheme.primary : null,
                  semanticLabel: selected ? '選択中' : '未選択',
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

/// 行をタップしたとき。1件ならそのまま標本詳細へ、複数なら、どの標本を開くか選ぶ。
Future<void> openSpecimenGroup(BuildContext context, SpecimenGroup group) async {
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
            child: SpeciesNameText(
              group.first.species,
              suffix: ' ×${group.count}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final item in group.items)
            ListTile(
              leading: Icon(item.printed ? Icons.print : Icons.print_disabled, color: item.printed ? null : warningColor),
              title: Text(item.catalogDisplay),
              subtitle: Text(item.printed ? '印刷済み' : '未印刷'),
              onTap: () => Navigator.pop(context, item.id),
            ),
        ],
      ),
    ),
  );
  if (id != null && context.mounted) context.push('/specimens/$id');
}
