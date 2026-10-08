import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/db/database_provider.dart';
import '../../domain/label/data_label_builder.dart';
import '../../domain/label/date_range_format.dart';
import '../../domain/models/calendar_date.dart';
import '../../domain/macron_notice.dart';
import '../../domain/sampling_method.dart';
import '../../domain/status.dart';
import '../../services/record_service.dart';
import '../../services/service_providers.dart';
import '../../domain/dictionary.dart';
import 'form_block.dart';
import 'macron_buttons.dart';
import 'position_picker_screen.dart';
import 'romaji_candidate.dart';
import 'text_suggestions.dart';
import 'record_form.dart';

/// 記録画面を開くときの引数。go_router の `extra` で渡す。
class RecordArgs {
  const RecordArgs(this.form, {this.draftId});

  final RecordForm form;

  /// 下書きから開いたときの下書き ID。
  final int? draftId;
}

/// 精度の警告しきい値(要件定義 F-06。設定で変えられるのは段階4)。
const _accuracyWarningMeters = 30.0;

/// 記録画面(要件定義 S-02)。
class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key, required this.args});

  final RecordArgs args;

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

enum _CloseChoice { saveDraft, discard, keepEditing }

class _RecordScreenState extends ConsumerState<RecordScreen> {
  late final RecordForm _form = widget.args.form;
  late final _habitat = TextEditingController(text: _form.habitat);
  late final _hostPlant = TextEditingController(text: _form.hostPlant);
  late final _otherMethod = TextEditingController(text: _form.samplingMethodOther);
  late final _lightSource = TextEditingController(text: _form.lightSource);
  late final _bait = TextEditingController(text: _form.bait);
  late final _remarks = TextEditingController(text: _form.remarks);
  late final _localityEn = TextEditingController(text: _form.place?.localityEn ?? '');
  // ↑ `late final ... = 式` は、最初に使われたときに初期化される(Java の遅延初期化ホルダーに近い)

  /// 何か入力したか。何も入力していなければ、閉じるときに確認しない。
  late bool _dirty = widget.args.draftId != null;
  var _closing = false;
  var _saving = false;

  /// 標高・地名の取得中か。
  var _lookingUp = false;
  var _offline = false;

  /// 「この地点に追加」のときの既存の地点。
  Locality? _existing;

  @override
  void initState() {
    super.initState();
    if (_form.existingLocalityId case final id?) {
      _loadExisting(id);
    } else if (_form.elevationMeters == null && _form.place == null) {
      _lookup();
    }
  }

  @override
  void dispose() {
    for (final c in [_habitat, _hostPlant, _otherMethod, _lightSource, _bait, _remarks, _localityEn]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting(int id) async {
    final db = ref.read(databaseProvider);
    final locality = await (db.select(db.localities)..where((l) => l.id.equals(id))).getSingle();
    if (mounted) setState(() => _existing = locality);
  }

  /// 標高と地名を、その場で取得する。圏外なら「取得待ち」のまま保存し、あとで補完する。
  Future<void> _lookup() async {
    setState(() => _lookingUp = true);
    final result = await ref.read(localityLookupServiceProvider).lookup(_form.latitude, _form.longitude);
    if (!mounted) return;
    setState(() {
      _lookingUp = false;
      _offline = result.offline;
      _form.elevationMeters = result.elevationMeters;
      _form.place = result.place;
      _localityEn.text = result.place?.localityEn ?? '';
    });
  }

  /// 座標をタップしたとき。小さな地図で位置を補正し、標高と地名を取り直す(圏外なら補完待ち)。
  Future<void> _correctPosition() async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => PositionPickerScreen(initial: LatLng(_form.latitude, _form.longitude)),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _form.correctPosition(picked.latitude, picked.longitude);
      _localityEn.text = '';
      _dirty = true;
    });
    await _lookup();
  }

  void _edited(VoidCallback change) => setState(() {
    change();
    _dirty = true;
  });

  // ---- 保存と終了 ----

  Future<void> _save({required bool addAnother}) async {
    _form
      ..habitat = _habitat.text
      ..hostPlant = _hostPlant.text
      ..samplingMethodOther = _otherMethod.text
      ..lightSource = _lightSource.text
      ..bait = _bait.text
      ..remarks = _remarks.text;
    if (_form.isPeriod && _form.endDate.isBefore(_form.startDate)) {
      _showMessage('終了日が開始日より前です');
      return;
    }

    setState(() => _saving = true);
    final RecordResult result;
    try {
      result = await ref.read(recordServiceProvider).save(_form.toInput(draftId: widget.args.draftId));
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _showMessage('保存できませんでした: $e');
      return;
    }
    // 取得待ちがあれば、すぐに補完を試す(待たない)
    unawaited(ref.read(enrichmentSchedulerProvider).trigger());
    if (!mounted) return;

    _showMessage('${result.specimenIds.length}件を、番号未確定で保存しました');
    if (addAnother) {
      setState(() => _closing = true);
      context.pushReplacement('/record', extra: RecordArgs(_form.nextAtSameLocality(result.localityId)));
    } else {
      _closeWithoutConfirm();
    }
  }

  void _closeWithoutConfirm() {
    setState(() => _closing = true);
    // canPop が反映されてから閉じる
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  /// 入力した状態で閉じようとしたときの確認(要件定義 第14章)。
  Future<void> _confirmClose() async {
    final choice = await showDialog<_CloseChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('記録を閉じますか'),
        content: const Text('入力した内容は保存されていません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, _CloseChoice.keepEditing), child: const Text('続ける')),
          TextButton(onPressed: () => Navigator.pop(context, _CloseChoice.discard), child: const Text('破棄')),
          FilledButton(onPressed: () => Navigator.pop(context, _CloseChoice.saveDraft), child: const Text('下書きに保存')),
        ],
      ),
    );
    switch (choice) {
      case _CloseChoice.saveDraft:
        _form
          ..habitat = _habitat.text
          ..hostPlant = _hostPlant.text
          ..samplingMethodOther = _otherMethod.text
          ..lightSource = _lightSource.text
          ..bait = _bait.text
          ..remarks = _remarks.text;
        await ref.read(draftServiceProvider).save(_form.toJson(), id: widget.args.draftId);
        _showMessage('下書きに保存しました');
        _closeWithoutConfirm();
      case _CloseChoice.discard:
        if (widget.args.draftId case final id?) {
          await ref.read(draftServiceProvider).delete(id);
        }
        _closeWithoutConfirm();
      case _CloseChoice.keepEditing || null:
        break;
    }
    // ↑ Dart の switch 文は break を書かなくても次の case に落ちない(Java と違う)
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- 画面 ----

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;

    // PopScope は戻る操作を横取りする(Android の戻るボタン・スワイプ・AppBar の戻る)
    return PopScope(
      canPop: _closing || !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.args.draftId == null ? '記録' : '記録(下書き)')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            _locationBlock(settings),
            _dateBlock(),
            _methodBlock(),
            _habitatBlock(),
            _specimenBlock(settings),
          ],
        ),
        // 保存ボタンは画面下に固定する
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _save(addAnother: true),
                    child: const Text('保存して同地点で追加', textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _save(addAnother: false),
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationBlock(AppSettingsRow? settings) {
    // 「この地点に追加」は既存の地点の値を、新しい地点は取得した値を表示する
    final existing = _existing;
    final accuracy = existing != null ? existing.accuracyMeters : _form.accuracyMeters;
    final manual = existing != null ? existing.isManualPosition : _form.isManualPosition;
    final lowAccuracy = accuracy != null && accuracy > _accuracyWarningMeters;
    final rounding = settings?.elevationRounding;
    final elevation = existing?.elevationMeters ?? _form.elevationMeters;
    final placeJa = existing != null
        ? [existing.countyJa, existing.municipalityJa, existing.localityJa].nonNulls.join()
        : [_form.place?.countyJa, _form.place?.municipalityJa, _form.place?.localityJa].nonNulls.join();
    final placeEn = existing != null
        ? [existing.prefectureEn, existing.countyEn, existing.municipalityEn].nonNulls.join(', ')
        : [_form.place?.prefectureEn, _form.place?.countyEn, _form.place?.municipalityEn].nonNulls.join(', ');
    final pending = _offline ? '取得待ち(通信が戻ったら補完)' : '取得待ち';

    return FormBlock(
      color: BlockColors.location,
      title: existing != null ? '地点(既存の地点に追加)' : '地点',
      children: [
        // 新しい地点のときだけ、座標をタップして位置を補正できる(既存の地点は動かさない)
        InkWell(
          onTap: existing == null ? _correctPosition : null,
          child: Row(
            children: [
              Expanded(child: _row('座標', formatCoordinates(_form.latitude, _form.longitude))),
              if (existing == null) const Icon(Icons.edit_location_alt, size: 20, color: Colors.black45),
            ],
          ),
        ),
        _row(
          '精度',
          manual ? '手動' : (accuracy == null ? '不明' : '±${accuracy.round()} m'),
          color: lowAccuracy ? warningColor : null,
        ),
        if (lowAccuracy)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('精度が ±30 m を超えています', style: TextStyle(color: warningColor)),
          ),
        _row(
          '標高',
          _lookingUp
              ? '取得中…'
              : elevation == null
              ? pending
              : '${rounding?.apply(elevation) ?? elevation.round()} m',
        ),
        _row('地名', _lookingUp ? '取得中…' : (placeJa.isEmpty ? pending : placeJa)),
        if (placeEn.isNotEmpty) _row('', placeEn),
        if (ambiguousMacronName(
              countyEn: existing?.countyEn ?? _form.place?.countyEn,
              municipalityEn: existing?.municipalityEn ?? _form.place?.municipalityEn,
            )
            case final name?)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '$name の長音(ō)は、語の境目かもしれません。必要なら確かめてください',
              style: const TextStyle(color: warningColor),
            ),
          ),
        // 大字のローマ字は手入力。辞書か公的データ(マクロンを含まないもの)にあれば自動で入る。
        // 公的データのマクロンを含む候補は、確かめてから「使う」で入れる
        if (existing == null && _form.place?.localityJa != null) ...[
          const SizedBox(height: 6),
          TextField(
            controller: _localityEn,
            decoration: InputDecoration(
              labelText: '大字のローマ字(${_form.place!.localityJa})',
              hintText: '例: Shimooritate',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => _edited(() => _form.place = _form.place!.withLocalityEn(v.trim().isEmpty ? null : v.trim())),
          ),
          MacronButtons(controller: _localityEn, onInserted: () {
            _edited(() => _form.place = _form.place!.withLocalityEn(_localityEn.text.trim()));
          }),
          if (_localityEn.text.trim().isEmpty)
            if (ref.watch(oazaRomajiTableProvider).lookup(_form.place!.municipalityCode, _form.place!.localityJa)
                case final candidate?)
              RomajiCandidate(
                candidate: candidate,
                onUse: () {
                  _localityEn.text = candidate.value;
                  _edited(() => _form.place = _form.place!.withLocalityEn(candidate.value));
                },
              ),
        ],
        if (existing == null && !_lookingUp && _offline)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: _lookup, icon: const Icon(Icons.refresh), label: const Text('もう一度取得')),
          ),
      ],
    );
  }

  Widget _dateBlock() {
    return FormBlock(
      color: BlockColors.location,
      title: '日時',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('期間'),
          Switch(
            value: _form.isPeriod,
            onChanged: (v) => _edited(() {
              _form.isPeriod = v;
              if (v && _form.endDate.isBefore(_form.startDate)) _form.endDate = _form.startDate;
            }),
          ),
        ],
      ),
      children: [
        Row(
          children: [
            Expanded(child: _dateButton(_form.isPeriod ? '開始日' : '採集日', _form.startDate, (d) => _form.startDate = d)),
            if (_form.isPeriod) ...[
              const SizedBox(width: 8),
              Expanded(child: _dateButton('終了日', _form.endDate, (d) => _form.endDate = d)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text('ラベル: ${formatLabelPeriod(_form.period)}', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _dateButton(String label, CalendarDate value, void Function(CalendarDate) onPicked) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(value.year, value.month, value.day),
          firstDate: DateTime(1900),
          lastDate: DateTime.now().add(const Duration(days: 366)),
        );
        if (picked != null) _edited(() => onPicked(CalendarDate.fromDateTime(picked)));
      },
      child: Text('$label  ${value.year}/${value.month}/${value.day}'),
    );
  }

  Widget _methodBlock() {
    final method = _form.samplingMethod;
    return FormBlock(
      color: BlockColors.collecting,
      title: '採集方法',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final m in SamplingMethod.values)
              ChoiceChip(
                label: Text(m.nameJa),
                selected: m == method,
                selectedColor: BlockColors.collecting.withValues(alpha: 0.35),
                onSelected: (_) => _edited(() {
                  _form.samplingMethod = m;
                  // トラップ系は設置〜回収の期間を入力する
                  if (m.usesPeriod) _form.isPeriod = true;
                }),
              ),
          ],
        ),
        if (method == SamplingMethod.other) ...[
          const SizedBox(height: 8),
          _textField(_otherMethod, '採集方法(自由入力)'),
        ],
        if (method.hasLightSource) ...[
          const SizedBox(height: 8),
          _textField(_lightSource, '光源', hint: '例: UV LED 15W'),
        ],
        if (method.hasBait) ...[
          const SizedBox(height: 8),
          _textField(_bait, 'ベイト(無しなら空欄)', hint: '例: 腐肉、糖蜜'),
        ],
        if (method.usesPeriod && !_form.isPeriod)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('トラップは「期間」で設置日〜回収日を入力してください'),
          ),
      ],
    );
  }

  Widget _habitatBlock() {
    return FormBlock(
      color: BlockColors.collecting,
      title: '環境・寄主植物',
      children: [
        _textField(_habitat, '環境', hint: '例: ブナ林の林縁'),
        _suggestions(_habitat, DictTextKind.habitat),
        const SizedBox(height: 8),
        _textField(_hostPlant, '寄主植物', hint: '例: スゲ属'),
        _suggestions(_hostPlant, DictTextKind.hostPlant),
      ],
    );
  }

  Widget _specimenBlock(AppSettingsRow? settings) {
    // 番号は、保存した標本の個体数などを直してから、確定の操作で付ける(要件定義 第14章)
    const numberText = '番号は確定時に決まります';

    return FormBlock(
      color: BlockColors.specimen,
      title: '標本',
      children: [
        Row(
          children: [
            const Text('作成数'),
            const Spacer(),
            IconButton.outlined(
              onPressed: _form.count > 1 ? () => _edited(() => _form.count--) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 56,
              child: Text('${_form.count}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            ),
            IconButton.outlined(
              onPressed: () => _edited(() => _form.count++),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Text(numberText, style: const TextStyle(color: BlockColors.specimen, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SegmentedButton<Sex?>(
          segments: const [
            ButtonSegment(value: null, label: Text('－')),
            ButtonSegment(value: Sex.male, label: Text('♂')),
            ButtonSegment(value: Sex.female, label: Text('♀')),
            ButtonSegment(value: Sex.unknown, label: Text('不明')),
          ],
          selected: {_form.sex},
          onSelectionChanged: (s) => _edited(() => _form.sex = s.first),
        ),
        const SizedBox(height: 10),
        _textField(_remarks, 'メモ', maxLines: 3),
      ],
    );
  }

  Widget _row(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 48, child: Text(label, style: const TextStyle(color: Colors.black54))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 16, color: color))),
      ],
    ),
  );

  /// 入力中の文字に合う、辞書の候補(F-10)。
  Widget _suggestions(TextEditingController c, DictTextKind kind) => TextSuggestions(
    controller: c,
    fetch: (q) => ref.read(dictionaryServiceProvider).suggestText(kind, q),
    onPicked: () {
      if (!_dirty) setState(() => _dirty = true);
    },
  );

  Widget _textField(TextEditingController c, String label, {String? hint, int maxLines = 1}) => TextField(
    controller: c,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder(), isDense: true),
    onChanged: (_) {
      if (!_dirty) setState(() => _dirty = true);
    },
  );
}
