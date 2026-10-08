import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../domain/models/calendar_date.dart';
import '../../domain/species_catalog.dart';
import '../../domain/species_name.dart';
import '../../domain/status.dart';
import '../../services/identification_service.dart';
import '../../services/service_providers.dart';
import '../common/clear_button.dart';
import '../record/form_block.dart';
import '../record/macron_buttons.dart';
import '../specimen/species_name_text.dart';

/// 同定の入力内容(種名・命名者・年・同定者・同定日・状態)。
/// 同定入力(S-06)と、一括編集・編集(S-04・S-05)で共通に使う。
class IdentificationInput extends ChangeNotifier {
  IdentificationInput({SpeciesName? initial, this.confirmed = false})
    : vernacular = TextEditingController(text: initial?.vernacular),
      genus = TextEditingController(text: initial?.genus),
      species = TextEditingController(text: initial?.species),
      subspecies = TextEditingController(text: initial?.subspecies),
      authorship = TextEditingController(text: initial?.authorship),
      identifier = TextEditingController() {
    for (final c in controllers) {
      c.addListener(notifyListeners);
    }
  }

  final TextEditingController vernacular;
  final TextEditingController genus;
  final TextEditingController species;
  final TextEditingController subspecies;
  final TextEditingController authorship;
  final TextEditingController identifier;

  List<TextEditingController> get controllers => [vernacular, genus, species, subspecies, authorship, identifier];

  /// 同定日。既定は今日。
  CalendarDate date = CalendarDate.fromDateTime(DateTime.now());

  /// 「同定済み」を選んでいる(選んでいなければ、種名があれば仮同定)。
  bool confirmed;

  VoidCallback? _onNameCleared;

  SpeciesName get name => SpeciesName(
    vernacular: vernacular.text,
    genus: genus.text,
    species: species.text,
    subspecies: subspecies.text,
    authorship: authorship.text,
  );

  /// 種名が空のときは未同定、入力があれば、仮同定(確定したら同定済み)。
  IdentificationStatus get status => IdentificationService.statusFor(name, confirmed: confirmed);

  void setDate(CalendarDate d) {
    date = d;
    notifyListeners();
  }

  void setConfirmed(bool v) {
    confirmed = v;
    notifyListeners();
  }

  /// 種名の入力をすべて消して、最初からやり直す。自動入力の記憶も消す。同定者と同定日は残す。
  void clearName() {
    _onNameCleared?.call();
    for (final c in [vernacular, genus, species, subspecies, authorship]) {
      c.clear();
    }
    confirmed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }
}

enum _Field { vernacular, genus, species, subspecies, authorship, identifier }

/// 種名の候補。辞書(自分が使った種)か、甲虫の目録から。
class _Candidate {
  const _Candidate(this.name, {required this.fromCatalog});

  final SpeciesName name;
  final bool fromCatalog;
}

/// 同定の入力欄(「種名」と「同定」の2つのブロック)。辞書と目録からの候補、目録からの自動入力、
/// 特殊文字のボタン、クリアを備える(要件定義 S-06)。
class IdentificationInputSection extends ConsumerStatefulWidget {
  const IdentificationInputSection({super.key, required this.input});

  final IdentificationInput input;

  @override
  ConsumerState<IdentificationInputSection> createState() => _IdentificationInputSectionState();
}

class _IdentificationInputSectionState extends ConsumerState<IdentificationInputSection> {
  IdentificationInput get _input => widget.input;

  late final Map<_Field, TextEditingController> _controllers = {
    _Field.vernacular: _input.vernacular,
    _Field.genus: _input.genus,
    _Field.species: _input.species,
    _Field.subspecies: _input.subspecies,
    _Field.authorship: _input.authorship,
    _Field.identifier: _input.identifier,
  };
  final _focus = {for (final k in _Field.values) k: FocusNode()};

  /// ō ū のボタンで文字を入れる欄。最後に触った欄。
  var _active = _Field.species;

  /// 種名の欄に打った文字から引いた、辞書と目録の候補。
  var _candidates = const <_Candidate>[];

  /// 合った候補の総数。多いときは、和名の50音順で先頭の [_maxCandidates] 件だけ出す。
  var _matched = 0;
  var _generation = 0;

  /// 候補や目録の自動入力で文字を入れている間は、入力の変化で候補や自動入力をやり直さない。
  var _picking = false;
  var _autofilling = false;

  /// 目録から自動入力した(または候補から選んだ)種。一度入れた種は、消された欄を入れ直さない。
  final _autoFilled = <CatalogEntry>{};
  String? _autoFillNote;

  /// 候補の一覧に同時に見せる件数と、1件の高さ。
  static const _visibleCandidates = 5;
  static const _maxCandidates = 20;
  static const _candidateRowHeight = 64.0;

  static const _nameFields = [_Field.vernacular, _Field.genus, _Field.species, _Field.subspecies];

  final _listeners = <TextEditingController, VoidCallback>{};

  @override
  void initState() {
    super.initState();
    _input._onNameCleared = _onNameCleared;
    _input.addListener(_rebuild);
    _loadDefaultIdentifier();
    // 目録は大きいので、画面を開いたときから読み込んでおく
    ref.read(speciesCatalogProvider.future).ignore();
    for (final MapEntry(:key, :value) in _controllers.entries) {
      void listener() {
        if (!_picking && !_autofilling && _nameFields.contains(key)) {
          // 候補は、入力した欄の文字を、その欄だけで探す(属名の欄なら属名、種小名の欄なら種小名)。
          // 入力済みのほかの欄も、それぞれの欄の条件にする
          if (_focus[key]!.hasFocus) _refreshCandidates();
          _autoFill();
        }
      }

      _listeners[value] = listener;
      value.addListener(listener);
      _focus[key]!.addListener(() {
        // 同定者の欄には、専用の特殊文字ボタンを置く(種名の下のボタンは、種名と命名者・年の欄に入れる)
        if (_focus[key]!.hasFocus && key != _Field.identifier) setState(() => _active = key);
      });
    }
  }

  @override
  void dispose() {
    _input._onNameCleared = null;
    _input.removeListener(_rebuild);
    for (final MapEntry(:key, :value) in _listeners.entries) {
      key.removeListener(value);
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onNameCleared() {
    _picking = true;
    _generation++;
    _autoFilled.clear();
    _autoFillNote = null;
    _candidates = const [];
    _matched = 0;
    // 消す処理が終わったあとに、自動入力などが走らないよう、次の描画で戻す
    WidgetsBinding.instance.addPostFrameCallback((_) => _picking = false);
  }

  /// 同定者の既定は、最後に入力した名前。
  Future<void> _loadDefaultIdentifier() async {
    final settings = await ref.read(settingsServiceProvider).read();
    if (mounted && _input.identifier.text.isEmpty) _input.identifier.text = settings.lastIdentifier ?? '';
  }

  Future<void> _refreshCandidates() async {
    final generation = ++_generation;
    final query = SpeciesNameQuery(
      vernacular: _input.vernacular.text,
      genus: _input.genus.text,
      species: _input.species.text,
      subspecies: _input.subspecies.text,
    );
    final fromDictionary = await ref.read(dictionaryServiceProvider).suggestSpeciesByFields(query, limit: null);
    if (!mounted || generation != _generation) return;
    // 自分で使った種(辞書)を先に、目録の種をその後ろに並べる。同じ種名は1つにまとめる
    final catalog = ref.read(speciesCatalogProvider).value ?? SpeciesCatalog.empty;
    final found = <String, _Candidate>{
      for (final n in fromDictionary) n.key: _Candidate(n, fromCatalog: false),
    };
    for (final e in catalog.searchFields(query, limit: null)) {
      final n = e.toSpeciesName();
      found.putIfAbsent(n.key, () => _Candidate(n, fromCatalog: true));
    }
    final sorted = found.values.toList()..sort((a, b) => compareByVernacular(a.name, b.name));
    setState(() {
      _matched = sorted.length;
      _candidates = sorted.take(_maxCandidates).toList();
    });
  }

  /// 入力した和名・学名が目録の1つの種に一致したら、空の欄を目録から埋める。
  /// 入力済みの欄は書き換えない。
  void _autoFill() {
    final catalog = ref.read(speciesCatalogProvider).value;
    if (catalog == null) return;
    final match = catalog.uniqueMatch(_input.name);
    if (match == null) {
      if (_autoFillNote != null) setState(() => _autoFillNote = null);
      return;
    }
    // 一度入れた種は、消されても入れ直さない(部分的に消している途中や、全部消したあとも)
    if (!_autoFilled.add(match)) return;

    final filled = <String>[];
    void fill(TextEditingController c, String? value, String label) {
      if (value != null && c.text.trim().isEmpty) {
        c.text = value;
        filled.add(label);
      }
    }

    _autofilling = true;
    fill(_input.vernacular, match.vernacular, '和名');
    fill(_input.genus, match.genus, '属');
    fill(_input.species, match.species, '種');
    fill(_input.subspecies, match.subspecies, '亜種');
    fill(_input.authorship, match.authorship, '命名者・年');
    _autofilling = false;
    setState(() => _autoFillNote = filled.isEmpty ? null : '目録から入力しました: ${filled.join('・')}');
  }

  /// 候補を選ぶと、和名・学名・命名者・年がまとめて入る。
  void _pick(SpeciesName c) {
    _picking = true;
    _generation++;
    _input.vernacular.text = c.vernacular ?? '';
    _input.genus.text = c.genus ?? '';
    _input.species.text = c.species ?? '';
    _input.subspecies.text = c.subspecies ?? '';
    _input.authorship.text = c.authorship ?? '';
    _picking = false;
    // 選んだ種が目録の種と一致するなら、消した欄を勝手に入れ直さない
    final match = ref.read(speciesCatalogProvider).value?.uniqueMatch(_input.name);
    if (match != null) _autoFilled.add(match);
    setState(() {
      _autoFillNote = null;
      _candidates = const [];
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickDate() async {
    final d = _input.date;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(d.year, d.month, d.day),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) _input.setDate(CalendarDate.fromDateTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    final name = _input.name;
    final status = _input.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormBlock(
          color: BlockColors.identification,
          title: '種名',
          trailing: TextButton.icon(
            onPressed: name.isEmpty ? null : _input.clearName,
            icon: const Icon(Icons.clear_all),
            label: const Text('クリア'),
          ),
          children: [
            _field(_Field.vernacular, '和名(任意)', hint: '例: オサムシ'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _field(_Field.genus, '属名', hint: 'Carabus', italic: true)),
                const SizedBox(width: 8),
                Expanded(child: _field(_Field.species, '種小名', hint: 'insulicola', italic: true)),
              ],
            ),
            const SizedBox(height: 8),
            _field(_Field.subspecies, '亜種名', italic: true),
            if (_candidates.isNotEmpty) _candidateList(),
            const SizedBox(height: 8),
            _field(_Field.authorship, '命名者・年', hint: '例: (Linnaeus, 1758)'),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('括弧の有無は、入力したとおりラベルに載ります', style: TextStyle(fontSize: 12)),
            ),
            if (_autoFillNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _autoFillNote!,
                  style: const TextStyle(fontSize: 12, color: BlockColors.identification, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 8),
            MacronButtons(controller: _controllers[_active]!, onInserted: () {}, personNames: true),
          ],
        ),
        FormBlock(
          color: BlockColors.identification,
          title: '同定',
          children: [
            _field(_Field.identifier, '同定者'),
            const SizedBox(height: 6),
            MacronButtons(controller: _input.identifier, onInserted: () {}, personNames: true),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text('同定日 ${_input.date.toIso()}'),
            ),
            const SizedBox(height: 12),
            if (name.isEmpty)
              Text('状態: ${status.label}(種名が空のときは未同定になります)')
            else
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(IdentificationStatus.provisional.label)),
                  ButtonSegment(value: true, label: Text(IdentificationStatus.verified.label)),
                ],
                selected: {_input.confirmed},
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: BlockColors.identification,
                  selectedForegroundColor: Colors.white,
                ),
                onSelectionChanged: (s) => _input.setConfirmed(s.first),
              ),
          ],
        ),
      ],
    );
  }

  Widget _field(_Field f, String label, {String? hint, bool italic = false}) => TextField(
    controller: _controllers[f],
    focusNode: _focus[f],
    style: italic ? const TextStyle(fontStyle: FontStyle.italic) : null,
    decoration: withClear(
      InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder(), isDense: true),
      _controllers[f]!,
    ),
  );

  /// 候補の一覧。和名の50音順に最大20件を出し、5件ぶんの高さでスクロールする。
  Widget _candidateList() {
    final shown = _candidates.length < _visibleCandidates ? _candidates.length : _visibleCandidates;
    return Card(
      margin: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              _matched > _candidates.length
                  ? '候補 $_matched件のうち、和名の50音順で ${_candidates.length}件(さらに入力すると絞り込めます)'
                  : '候補 ${_candidates.length}件(選ぶとまとめて入ります)',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // 5件ぶんの高さまで。名前が長いときは折り返して全体を見せるので、行の高さは変わる
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: shown * _candidateRowHeight),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _candidates.length,
              itemBuilder: (context, i) {
                final c = _candidates[i];
                return ListTile(
                  dense: true,
                  title: SpeciesNameText(c.name),
                  subtitle: c.name.authorship == null ? null : Text(c.name.authorship!),
                  trailing: c.fromCatalog ? const Text('目録', style: TextStyle(fontSize: 12)) : null,
                  onTap: () => _pick(c.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
