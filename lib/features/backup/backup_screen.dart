import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/backup_service.dart';
import '../../services/service_providers.dart';

/// 標本の件数と採集日の範囲。画面を開くたびに数え直す。
final _summaryProvider = FutureProvider.autoDispose<BackupSummary>(
  (ref) => ref.watch(backupServiceProvider).summarize(),
);

/// 簡易バックアップ(要件定義 F-17・S-09)。全データを1つのファイルにして共有画面に渡す。
///
/// 段階1は書き出しのみ。写真の有無の選択と復元の画面は段階4で作る。
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  var _working = false;

  Future<void> _export() async {
    setState(() => _working = true);
    try {
      final now = DateTime.now();
      final file = await ref.read(backupServiceProvider).export(now: now);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(file.bytes, mimeType: 'application/json', name: file.fileName)],
          fileNameOverrides: [file.fileName],
          subject: file.fileName,
        ),
      );
      // 閉じただけのときは記録しない。結果が分からない環境(unavailable)では、渡せたものとみなす
      if (result.status != ShareResultStatus.dismissed) {
        await ref.read(settingsServiceProvider).markBackedUp(now);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('書き出せませんでした: $e')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(_summaryProvider);
    final lastBackupAt = ref.watch(settingsProvider).value?.lastBackupAt;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('バックアップ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('標本・地点・下書き・設定・辞書など、全データを1つのファイルに書き出します。'
              '共有画面から保存先(Google Drive、iCloud Drive、メールなど)を選んでください。'),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: switch (summary) {
                AsyncData(:final value) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('標本 ${value.specimenCount}件', style: textTheme.titleLarge),
                    if (value.firstDate != null)
                      Text('採集日 ${_date(value.firstDate!)}〜${_date(value.lastDate!)}'),
                  ],
                ),
                AsyncError(:final error) => Text('件数を数えられませんでした: $error'),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: Text(lastBackupAt == null ? 'まだバックアップしていません' : '最後のバックアップ: ${_dateTime(lastBackupAt)}'),
          ),
          const SizedBox(height: 8),
          Text('写真の添付と、バックアップからの復元は今後の版で対応します。', style: textTheme.bodySmall),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _working ? null : _export,
            icon: _working
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share),
            label: const Text('バックアップを書き出す'),
          ),
        ),
      ),
    );
  }

  /// `2026-06-19` → `2026/6/19`
  static String _date(String iso) {
    final p = iso.split('-');
    return '${p[0]}/${int.parse(p[1])}/${int.parse(p[2])}';
  }

  static String _dateTime(DateTime d) {
    final l = d.toLocal();
    return '${l.year}/${l.month}/${l.day} ${l.hour}:${l.minute.toString().padLeft(2, '0')}';
  }
}
