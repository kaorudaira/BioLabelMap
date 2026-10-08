import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/species_name.dart';
import '../../services/service_providers.dart';
import 'identification_input.dart';

/// 同定入力を開くときの引数。go_router の `extra` で渡す。
class IdentifyArgs {
  const IdentifyArgs(this.specimenIds, {this.initial});

  /// 同定を追加する標本。複数なら、同じ同定をまとめて追加する。
  final List<int> specimenIds;

  /// 入力欄の初期値(再同定のとき、直前の同定を手直しできるようにする)。
  final SpeciesName? initial;
}

/// 同定入力(要件定義 S-06)。保存すると、上書きせず同定履歴に追加する。
/// 入力欄は、一括編集・編集と共通(`IdentificationInputSection`)。
class IdentifyScreen extends ConsumerStatefulWidget {
  const IdentifyScreen({super.key, required this.args});

  final IdentifyArgs args;

  @override
  ConsumerState<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends ConsumerState<IdentifyScreen> {
  late final _input = IdentificationInput(initial: widget.args.initial);
  var _saving = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(identificationServiceProvider).add(
        widget.args.specimenIds,
        name: _input.name,
        identifiedBy: _input.identifier.text,
        dateIdentified: _input.date,
        status: _input.status,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存できませんでした: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.args.specimenIds.length;
    return Scaffold(
      appBar: AppBar(title: Text(count > 1 ? '同定入力($count件)' : '同定入力')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [IdentificationInputSection(input: _input)],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(count > 1 ? '$count件に同定を追加' : '同定を追加'),
          ),
        ),
      ),
    );
  }
}
