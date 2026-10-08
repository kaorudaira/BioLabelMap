import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../domain/specimen_list.dart';
import '../../domain/trash.dart';
import '../../services/service_providers.dart';
import 'species_name_text.dart';
import 'status_mark.dart';

/// ごみ箱(要件定義 S-04「ごみ箱」)。削除した標本が、削除日の新しい順に並ぶ。
/// 期間内なら元に戻せ、期間が過ぎると完全に削除する。
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key, this.now});

  /// 残り日数の計算に使う現在時刻(テスト用)。
  final DateTime? now;

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  /// 選んだ標本の ID。空でなければ選択モード。
  final _selected = <int>{};

  void _toggle(int id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));

  @override
  Widget build(BuildContext context) {
    final trashed = ref.watch(trashedItemsProvider);
    final items = [...(trashed.value ?? const <SpecimenListItem>[])]
      ..sort((a, b) {
        final c = b.deletedAt!.compareTo(a.deletedAt!);
        return c != 0 ? c : b.id.compareTo(a.id);
      });
    final now = widget.now ?? DateTime.now();
    _selected.removeWhere((id) => !items.any((i) => i.id == id));
    final selecting = _selected.isNotEmpty;

    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: selecting
              ? IconButton(
                  tooltip: '選択を解除',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_selected.clear),
                )
              : null,
          title: Text(selecting ? '${_selected.length}件を選択' : 'ごみ箱'),
        ),
        body: trashed.isLoading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
            ? const Center(child: Text('ごみ箱は空です'))
            : ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      '削除から$trashRetentionDays日を過ぎると、完全に削除します。長押しで選ぶと、元に戻せます。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  for (final i in items) ...[_tile(i, now, selecting), const Divider(height: 1)],
                ],
              ),
        bottomNavigationBar: selecting
            ? Material(
                elevation: 8,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _restore,
                            icon: const Icon(Icons.restore_from_trash),
                            label: const Text('元に戻す'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _deleteNow,
                            style: OutlinedButton.styleFrom(foregroundColor: warningColor),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('今すぐ完全に削除'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _tile(SpecimenListItem i, DateTime now, bool selecting) {
    final selected = _selected.contains(i.id);
    final theme = Theme.of(context);
    return InkWell(
      onTap: selecting ? () => _toggle(i.id) : null,
      onLongPress: () => _toggle(i.id),
      child: Container(
        color: selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selecting)
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 2),
                child: Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
            Padding(padding: const EdgeInsets.only(top: 2), child: StatusMark(i.status)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpeciesNameText(
                    i.species,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: i.species.isEmpty ? theme.disabledColor : BlockColors.identification,
                    ),
                  ),
                  Text(
                    '${i.catalogDisplay}  ${formatPeriodText(i.period)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: BlockColors.specimen),
                  ),
                  Text(
                    purgeCountdownText(i.deletedAt!, now),
                    style: theme.textTheme.bodySmall?.copyWith(color: warningColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 元の標本番号のまま、標本一覧に戻す。
  Future<void> _restore() async {
    final ids = _selected.toList();
    await ref.read(specimenEditServiceProvider).restore(ids);
    if (!mounted) return;
    setState(_selected.clear);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ids.length}件を元に戻しました')));
  }

  Future<void> _deleteNow() async {
    final ids = _selected.toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${ids.length}件を完全に削除しますか'),
        content: const Text('完全に削除すると、元に戻せません。標本番号は欠番になり、再利用しません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('やめる')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: warningColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('完全に削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(specimenEditServiceProvider).deletePermanently(ids);
    if (!mounted) return;
    setState(_selected.clear);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ids.length}件を完全に削除しました')));
  }
}
