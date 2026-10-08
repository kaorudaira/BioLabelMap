import 'package:flutter/material.dart';

import '../common/clear_button.dart';
import '../../domain/models/calendar_date.dart';
import '../../domain/sampling_method.dart';
import '../../domain/specimen_list.dart';
import '../../domain/status.dart';

/// 標本一覧の絞り込み条件を選ぶシート(要件定義 S-04)。「適用」で新しい条件を返す。
Future<SpecimenFilter?> showSpecimenFilterSheet(BuildContext context, SpecimenFilter current) =>
    showModalBottomSheet<SpecimenFilter>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(initial: current),
    );

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final SpecimenFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late var _filter = widget.initial;
  late final _place = TextEditingController(text: widget.initial.place);

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('絞り込み', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _place,
                decoration: withClear(
                  const InputDecoration(labelText: '地名', border: OutlineInputBorder()),
                  _place,
                  onCleared: () => _filter = _filter.copyWith(place: ''),
                ),
                onChanged: (v) => _filter = _filter.copyWith(place: v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dateButton('開始日', _filter.from, (d) => _filter = _filter.copyWith(from: d))),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('〜')),
                  Expanded(child: _dateButton('終了日', _filter.to, (d) => _filter = _filter.copyWith(to: d))),
                ],
              ),
              const SizedBox(height: 12),
              Text('採集方法', style: Theme.of(context).textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in SamplingMethod.values)
                    FilterChip(
                      label: Text(m.nameJa),
                      selected: _filter.methods.contains(m),
                      onSelected: (on) => setState(
                        () => _filter = _filter.copyWith(methods: _toggled(_filter.methods, m, on)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text('同定の状態', style: Theme.of(context).textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in IdentificationStatus.values)
                    FilterChip(
                      label: Text(s.label),
                      selected: _filter.statuses.contains(s),
                      onSelected: (on) => setState(
                        () => _filter = _filter.copyWith(statuses: _toggled(_filter.statuses, s, on)),
                      ),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('未印刷のみ'),
                value: _filter.unprintedOnly,
                onChanged: (v) => setState(() => _filter = _filter.copyWith(unprintedOnly: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('ラベルと不一致のみ'),
                subtitle: const Text('印刷したあとに、標高や地名が変わった標本'),
                value: _filter.mismatchOnly,
                onChanged: (v) => setState(() => _filter = _filter.copyWith(mismatchOnly: v)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _filter.copyWith(
                          place: '',
                          from: null,
                          to: null,
                          methods: const {},
                          statuses: const {},
                          unprintedOnly: false,
                          mismatchOnly: false,
                        ),
                      ),
                      child: const Text('条件を解除'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(onPressed: () => Navigator.pop(context, _filter), child: const Text('適用'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Set<T> _toggled<T>(Set<T> set, T value, bool on) => on ? {...set, value} : ({...set}..remove(value));

  Widget _dateButton(String label, CalendarDate? value, void Function(CalendarDate?) assign) {
    return OutlinedButton(
      onPressed: () async {
        final initial = value == null ? DateTime.now() : DateTime(value.year, value.month, value.day);
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1900),
          lastDate: DateTime(DateTime.now().year + 1, 12, 31),
        );
        if (picked != null) setState(() => assign(CalendarDate.fromDateTime(picked)));
      },
      child: Text(value == null ? label : value.toIso()),
    );
  }
}
