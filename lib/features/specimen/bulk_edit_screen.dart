import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';
import '../../domain/models/calendar_date.dart';
import '../../domain/models/collection_period.dart';
import '../../domain/sampling_method.dart';
import '../../domain/specimen_list.dart';
import '../../domain/status.dart';
import '../../services/service_providers.dart';
import '../../services/specimen_edit_service.dart';
import '../../services/specimen_service.dart';
import '../record/form_block.dart';
import '../record/macron_buttons.dart';
import '../record/position_picker_screen.dart';

/// 一括編集・編集を開くときの引数。go_router の `extra` で渡す。
class BulkEditArgs {
  const BulkEditArgs(this.specimenIds, {this.initial});

  /// 修正する標本。
  final List<int> specimenIds;

  /// 1件を編集するときの、いまの内容。あれば全項目を編集でき、入力欄にいまの値が入る。
  /// 無ければ一括編集(地名と採集方法だけ。空欄は変更しない)。
  final SpecimenDetail? initial;
}

/// 一括編集(要件定義 S-04)と、標本1件の編集(要件定義 S-05)。
/// 同じ採集を共有する標本のうち一部だけを直したときは、その標本のために採集を複製して付け替える。
class BulkEditScreen extends ConsumerStatefulWidget {
  const BulkEditScreen({super.key, required this.args});

  final BulkEditArgs args;

  @override
  ConsumerState<BulkEditScreen> createState() => _BulkEditScreenState();
}

class _BulkEditScreenState extends ConsumerState<BulkEditScreen> {
  SpecimenDetail? get _initial => widget.args.initial;
  bool get _single => _initial != null;
  int get _count => widget.args.specimenIds.length;

  late SamplingMethod? _method = _initial?.event.samplingMethod;
  late final _methodOther = TextEditingController(text: _initial?.event.samplingMethodOther);
  late final _lightSource = TextEditingController(text: _initial?.event.lightSource);
  late final _bait = TextEditingController(text: _initial?.event.bait);
  late final _habitat = TextEditingController(text: _initial?.event.habitat);
  late final _hostPlant = TextEditingController(text: _initial?.event.hostPlant);
  late final _remarks = TextEditingController(text: _initial?.specimen.remarks);
  late Sex? _sex = _initial?.specimen.sex;
  late CalendarDate _start = _initial?.event.startDate ?? CalendarDate.fromDateTime(DateTime.now());
  late CalendarDate _end = _initial?.event.endDate ?? _start;
  late bool _isPeriod = _initial != null && _initial!.event.startDate != _initial!.event.endDate;

  late final Map<PlaceField, TextEditingController> _place = {
    for (final f in PlaceField.values) f: TextEditingController(text: _initialPlace(f)),
  };

  // 番号が未確定(仮)の標本は、番号を使っていないので、個体数を増減できる
  bool get _canChangeCount => _single && _initial!.specimen.catalogNumber == null && _initial!.specimen.deletedAt == null;
  late final int _count0 = _initial?.provisionalIdsInEvent.length ?? 0;
  late int _provCount = _count0;

  var _saving = false;

  /// 地図で選び直した座標。1件の編集だけ。
  LatLng? _newPosition;

  String? _initialPlace(PlaceField f) {
    final l = _initial?.locality;
    if (l == null) return null;
    return switch (f) {
      PlaceField.prefectureJa => l.prefectureJa,
      PlaceField.countyJa => l.countyJa,
      PlaceField.municipalityJa => l.municipalityJa,
      PlaceField.localityJa => l.localityJa,
      PlaceField.prefectureEn => l.prefectureEn,
      PlaceField.countyEn => l.countyEn,
      PlaceField.municipalityEn => l.municipalityEn,
      PlaceField.localityEn => l.localityEn,
    };
  }

  @override
  void dispose() {
    for (final c in [_methodOther, _lightSource, _bait, _habitat, _hostPlant, _remarks, ..._place.values]) {
      c.dispose();
    }
    super.dispose();
  }

  static String? _blankToNull(String s) => s.trim().isEmpty ? null : s.trim();

  /// 画面の入力から、修正内容を作る。1件の編集では、変えた項目だけを入れる
  /// (変えていないのに採集を複製しないため)。一括編集では、空欄は変えない。
  SpecimenEdit _buildEdit() {
    final initial = _initial;
    if (initial == null) {
      return SpecimenEdit(
        method: _method,
        methodOther: _method == null ? null : Change(_method == SamplingMethod.other ? _blankToNull(_methodOther.text) : null),
        place: {
          for (final MapEntry(:key, :value) in _place.entries)
            if (value.text.trim().isNotEmpty) key: value.text.trim(),
        },
      );
    }

    final e = initial.event;
    final method = _method!;
    final methodChanged = method != e.samplingMethod;
    Change<String?>? text(TextEditingController c, String? before, {bool force = false}) {
      final now = _blankToNull(c.text);
      return force || now != before ? Change(now) : null;
    }

    final period = _isPeriod ? CollectionPeriod(_start, _end) : CollectionPeriod.singleDay(_start);
    return SpecimenEdit(
      period: period == CollectionPeriod(e.startDate, e.endDate) ? null : period,
      method: methodChanged ? method : null,
      methodOther: method == SamplingMethod.other ? text(_methodOther, e.samplingMethodOther) : (methodChanged ? const Change(null) : null),
      lightSource: method.hasLightSource ? text(_lightSource, e.lightSource) : (methodChanged ? const Change(null) : null),
      bait: method.hasBait ? text(_bait, e.bait) : (methodChanged ? const Change(null) : null),
      habitat: text(_habitat, e.habitat),
      hostPlant: text(_hostPlant, e.hostPlant),
      sex: _sex != initial.specimen.sex ? Change(_sex) : null,
      remarks: text(_remarks, initial.specimen.remarks),
      place: {
        for (final MapEntry(:key, :value) in _place.entries)
          if (_blankToNull(value.text) != _blankToNull(_initialPlace(key) ?? '')) key: _blankToNull(value.text),
      },
      position: _newPosition == null ? null : (latitude: _newPosition!.latitude, longitude: _newPosition!.longitude),
    );
  }

  Future<void> _save() async {
    final edit = _buildEdit();
    final countChanged = _canChangeCount && _provCount != _count0;
    if (edit.isEmpty && !countChanged) {
      Navigator.pop(context, false);
      return;
    }
    if (!await _confirmOneLanguage(edit)) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(specimenEditServiceProvider);
      // 個体数を先に直す(採集を複製する修正の前に、元の採集で数える)
      if (countChanged) {
        await service.setProvisionalCount(_initial!.event.id, _provCount, keepSpecimenId: _initial!.specimen.id);
      }
      if (!edit.isEmpty) await service.apply(widget.args.specimenIds, edit);
      // 座標を直したら、新しい座標の標高と地名を取り直す(通信できなければ、あとで自動で補完する)
      if (edit.position != null) unawaited(ref.read(enrichmentSchedulerProvider).trigger());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_count件を修正しました')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存できませんでした: $e')));
    }
  }

  /// 地名の和文と英文の片方だけを変えるときは、そのままでよいか確かめる。
  Future<bool> _confirmOneLanguage(SpecimenEdit edit) async {
    final ja = edit.place.keys.any((f) => f.name.endsWith('Ja'));
    final en = edit.place.keys.any((f) => f.name.endsWith('En'));
    if (ja == en) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ja ? '和文の地名だけを変更します' : '英文の地名だけを変更します'),
        content: Text(
          ja
              ? '英文(ローマ字)の地名は変わりません。そのまま保存しますか。'
              : '和文の地名は変わりません。そのまま保存しますか。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('戻る')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('そのまま保存')),
        ],
      ),
    );
    return ok == true;
  }

  /// 座標を、地図の上で選び直す。いまの座標(直したあとなら、その座標)を開始地点にする。
  Future<void> _pickPosition() async {
    final l = _initial!.locality;
    final start = _newPosition ?? LatLng(l.latitude, l.longitude);
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => PositionPickerScreen(initial: start)),
    );
    if (picked != null && mounted) setState(() => _newPosition = picked);
  }

  Future<CalendarDate?> _pickDate(CalendarDate initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    return picked == null ? null : CalendarDate.fromDateTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_single ? '編集 ${_initial!.specimen.catalogText ?? provisionalLabel}' : '一括編集($_count件)')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!_single)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('選んだ標本の地名と採集方法を、まとめて直します。空欄の項目は変えません。'),
            ),
          if (_single) _dateBlock(),
          _methodBlock(),
          if (_single) _habitatBlock(),
          if (_canChangeCount) _countBlock(),
          if (_single) _specimenBlock(),
          if (_single) _positionBlock(),
          _placeBlock(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_single ? '保存' : '$_count件に反映'),
          ),
        ),
      ),
    );
  }

  Widget _dateBlock() => FormBlock(
    color: BlockColors.location,
    title: '採集日',
    children: [
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final d = await _pickDate(_start);
                if (d != null) {
                  setState(() {
                    _start = d;
                    if (!_isPeriod || _end.isBefore(_start)) _end = d;
                  });
                }
              },
              child: Text(_start.toIso()),
            ),
          ),
          if (_isPeriod) ...[
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('〜')),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final d = await _pickDate(_end);
                  if (d != null && !d.isBefore(_start)) setState(() => _end = d);
                },
                child: Text(_end.toIso()),
              ),
            ),
          ],
        ],
      ),
      Row(
        children: [
          const Text('期間'),
          const Spacer(),
          Switch(
            value: _isPeriod,
            onChanged: (v) => setState(() {
              _isPeriod = v;
              if (!v) _end = _start;
            }),
          ),
        ],
      ),
    ],
  );

  Widget _methodBlock() {
    final m = _method;
    return FormBlock(
      color: BlockColors.collecting,
      title: '採集方法',
      children: [
        DropdownButtonFormField<SamplingMethod?>(
          initialValue: m,
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          items: [
            if (!_single) const DropdownMenuItem(value: null, child: Text('変更しない')),
            for (final s in SamplingMethod.values) DropdownMenuItem(value: s, child: Text(s.nameJa)),
          ],
          onChanged: (v) => setState(() => _method = v),
        ),
        if (m == SamplingMethod.other) ...[
          const SizedBox(height: 8),
          _field(_methodOther, '採集方法(自由入力)'),
        ],
        if (_single && (m?.hasLightSource ?? false)) ...[const SizedBox(height: 8), _field(_lightSource, '光源')],
        if (_single && (m?.hasBait ?? false)) ...[const SizedBox(height: 8), _field(_bait, 'ベイト')],
      ],
    );
  }

  Widget _habitatBlock() => FormBlock(
    color: BlockColors.collecting,
    title: '環境・寄主植物',
    children: [_field(_habitat, '環境'), const SizedBox(height: 8), _field(_hostPlant, '寄主植物')],
  );

  Widget _countBlock() => FormBlock(
    color: BlockColors.specimen,
    title: '個体数(番号が未確定の標本)',
    children: [
      Row(
        children: [
          const Text('この採集の標本'),
          const Spacer(),
          IconButton.outlined(
            onPressed: _provCount > 1 ? () => setState(() => _provCount--) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 56,
            child: Text('$_provCount', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          ),
          IconButton.outlined(onPressed: () => setState(() => _provCount++), icon: const Icon(Icons.add)),
        ],
      ),
      Text(
        '番号を確定する前なら、個体数を直せます。減らすときは、保存した順の新しい標本から削除します(同定を入力した標本は減らせません)。',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  Widget _specimenBlock() => FormBlock(
    color: BlockColors.specimen,
    title: '標本',
    children: [
      SegmentedButton<Sex?>(
        segments: const [
          ButtonSegment(value: null, label: Text('－')),
          ButtonSegment(value: Sex.male, label: Text('♂')),
          ButtonSegment(value: Sex.female, label: Text('♀')),
          ButtonSegment(value: Sex.unknown, label: Text('不明')),
        ],
        selected: {_sex},
        onSelectionChanged: (s) => setState(() => _sex = s.first),
      ),
      const SizedBox(height: 8),
      _field(_remarks, 'メモ', maxLines: 3),
    ],
  );

  Widget _positionBlock() {
    final l = _initial!.locality;
    final shown = _newPosition ?? LatLng(l.latitude, l.longitude);
    return FormBlock(
      color: BlockColors.location,
      title: '座標',
      children: [
        Text(formatLatLon(shown.latitude, shown.longitude), style: Theme.of(context).textTheme.bodyLarge),
        if (_newPosition != null)
          Text(
            '保存すると、標高と地名は新しい座標で取り直します(通信できないときは、あとで自動で補完します)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickPosition,
          icon: const Icon(Icons.pin_drop),
          label: const Text('地図で座標を直す'),
        ),
      ],
    );
  }

  Widget _placeBlock() => FormBlock(
    color: BlockColors.location,
    title: '地名',
    children: [
      Text(
        _single
            ? '座標は変わりません。直した地名は、補完で上書きされません。'
            : '入力した項目だけ、選んだ標本の地名に反映します(空欄は変えません)。',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      for (final f in PlaceField.values) ...[
        _field(_place[f]!, f.label),
        if (f == PlaceField.localityEn) MacronButtons(controller: _place[f]!, onInserted: () {}),
        const SizedBox(height: 8),
      ],
    ],
  );

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) => TextField(
    controller: c,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
  );
}
