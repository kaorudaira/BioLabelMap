import 'package:flutter/material.dart';

import '../common/clear_button.dart';import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/catalog_number.dart';
import '../../domain/label/collector_name_format.dart';
import '../../services/service_providers.dart';

/// 初回設定(要件定義 第14章)。
///
/// これまでの最新の標本番号を入力するまで、記録は始められない。
/// 採集者名もここで入れる(ラベルに `K. YOSHIHARA` の形で印字する)。
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  // ConsumerStatefulWidget は、状態を持ち、Provider も読める画面。
  // Widget(設定値)と State(変わる状態)を別クラスに分けるのが Flutter の作法。
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNumber = TextEditingController(text: '0');
  final _collector = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    // TextEditingController は自分で破棄する(Java の close() に相当)
    _lastNumber.dispose();
    _collector.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final settings = ref.read(settingsServiceProvider);
    try {
      await settings.setCollectorName(_collector.text);
      await settings.initializeCatalog(int.parse(_lastNumber.text));
      // 設定が変わると settingsProvider が流れ直し、アプリが地図画面に切り替わる
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存できませんでした: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    final format = CatalogNumberFormat(
      prefix: settings?.catalogPrefix ?? 'KYC',
      digits: settings?.catalogDigits ?? 5,
    );
    final last = int.tryParse(_lastNumber.text);
    final name = _collector.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('はじめに')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('標本番号の開始値を設定します。あとから変更できません。'),
            const SizedBox(height: 20),
            TextFormField(
              controller: _lastNumber,
              decoration: withClear(
                const InputDecoration(
                  labelText: 'これまでの最新の標本番号(数字のみ)',
                  helperText: '標本が無ければ 0',
                  border: OutlineInputBorder(),
                ),
                _lastNumber,
                onCleared: () => setState(() {}),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => int.tryParse(v ?? '') == null ? '数字を入力してください' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (last != null)
              Text('最初の標本は ${format.format(last + 1)} になります',
                  style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 28),
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
            if (name.isNotEmpty)
              Text('ラベルには「${formatCollectorName(name)}」と印字します',
                  style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('はじめる'),
            ),
          ],
        ),
      ),
    );
  }
}
