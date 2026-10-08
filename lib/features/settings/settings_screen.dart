import 'package:flutter/material.dart';

import '../common/clear_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/catalog_number.dart';
import '../../domain/label/collector_name_format.dart';
import '../../services/service_providers.dart';
import '../../services/settings_service.dart';

/// 設定(要件定義 S-11)。段階1は採集者名と、標本番号の接頭辞・桁数のみ。
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _collector;
  late final TextEditingController _prefix;
  late final TextEditingController _digits;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    // この画面は初回設定の後にしか開けないので、設定は読み込み済み
    final settings = ref.read(settingsProvider).requireValue;
    _collector = TextEditingController(text: settings.collectorName ?? '');
    _prefix = TextEditingController(text: settings.catalogPrefix);
    _digits = TextEditingController(text: '${settings.catalogDigits}');
  }

  @override
  void dispose() {
    _collector.dispose();
    _prefix.dispose();
    _digits.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final service = ref.read(settingsServiceProvider);
    final prefix = _prefix.text.trim();
    final digits = int.parse(_digits.text);
    try {
      final conflict = await service.findFormatConflict(prefix: prefix, digits: digits);
      if (conflict != null) {
        if (!mounted) return;
        setState(() => _saving = false);
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('この書式は使えません'),
            content: Text('これから発行する番号が、既存の標本番号 $conflict と重なります。接頭辞か桁数を変えてください。'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
        return;
      }
      await service.setCollectorName(_collector.text);
      await service.setCatalogFormat(prefix: prefix, digits: digits);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('設定を保存しました')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存できませんでした: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).requireValue;
    final next = settings.nextCatalogNumber!;
    final name = _collector.text.trim();
    final prefix = _prefix.text.trim();
    final digits = int.tryParse(_digits.text);
    final formatValid = prefix.isNotEmpty && digits != null && digits >= 1 && digits <= maxCatalogDigits;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('採集者', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _collector,
              decoration: withClear(
                const InputDecoration(
                  labelText: '採集者名(英語表記)',
                  hintText: 'Kaoru Yoshihara',
                  border: OutlineInputBorder(),
                ),
                _collector,
                onCleared: () => setState(() {}),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v ?? '').trim().isEmpty ? '採集者名を入力してください' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (name.isNotEmpty) Text('ラベルには「${formatCollectorName(name)}」と印字します'),
            const SizedBox(height: 4),
            Text('これから記録する標本に使います。記録済みの標本は変わりません。', style: textTheme.bodySmall),
            const Divider(height: 40),
            Text('標本番号', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _prefix,
                    decoration: withClear(
                      const InputDecoration(labelText: '接頭辞', border: OutlineInputBorder()),
                      _prefix,
                      onCleared: () => setState(() {}),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    // 空白は番号の文字列に混ぜない
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                    validator: (v) => (v ?? '').trim().isEmpty ? '入力してください' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _digits,
                    decoration: withClear(
                      const InputDecoration(labelText: '桁数', border: OutlineInputBorder()),
                      _digits,
                      onCleared: () => setState(() {}),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return n == null || n < 1 || n > maxCatalogDigits ? '1〜$maxCatalogDigits' : null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (formatValid)
              Text(
                '次の標本は ${CatalogNumberFormat(prefix: prefix, digits: digits).format(next)} になります',
                style: textTheme.bodyLarge,
              ),
            const SizedBox(height: 4),
            Text('すでに付けた標本番号は変わりません。', style: textTheme.bodySmall),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline),
              title: Text('次の番号: $next'),
              subtitle: const Text('開始番号は初回にだけ設定でき、変更できません。番号は記録のたびに自動で進みます。'),
            ),
            const Divider(height: 40),
            Text('辞書', style: textTheme.titleMedium),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book),
              title: const Text('辞書管理'),
              subtitle: const Text('地名のローマ字、種、環境・寄主植物の候補を編集します'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/dictionary'),
            ),
            const Divider(height: 40),
            Text('データの出典', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            // アドレス・ベース・レジストリは CC BY 4.0。加工したことと出典を示す
            Text(
              '県・市町村の英語表記: 総務省「全国地方公共団体コード」、日本郵便「郵便番号データ」を加工して作成\n\n'
              '大字のローマ字: デジタル庁「アドレス・ベース・レジストリ」'
              '(https://www.digital.go.jp/policies/base_registry_address、CC BY 4.0)、'
              '日本郵便「郵便番号データ」を加工して作成。長音のマクロンはカナから補っています'
              '\n\n'
              '甲虫の和名・学名: 「日本産甲虫目録」(https://japanesebeetles.jimdofree.com/)のデータを、同定の自動入力に使用',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
        ),
      ),
    );
  }
}
