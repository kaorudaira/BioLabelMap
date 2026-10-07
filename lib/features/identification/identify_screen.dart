import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../domain/models/calendar_date.dart';
import '../../domain/species_catalog.dart';
import '../../domain/species_name.dart';
import '../../domain/status.dart';
import '../../services/identification_service.dart';
import '../../services/service_providers.dart';
import '../record/form_block.dart';
import '../record/macron_buttons.dart';

/// 同定入力を開くときの引数。go_router の `extra` で渡す。
class IdentifyArgs {
  const IdentifyArgs(this.specimenIds, {this.initial});

  /// 同定を追加する標本。複数なら、同じ同定をまとめて追加する。
  final List<int> specimenIds;

  /// 入力欄の初期値(再同定のとき、直前の同定を手直しできるようにする)。
  final SpeciesName? initial;
}

/// 同定入力(要件定義 S-06)。保存すると、上書きせず同定履歴に追加する。
class IdentifyScreen extends ConsumerStatefulWidget {
  const IdentifyScreen({super.key, required this.args});

  final IdentifyArgs args;

  @override
  ConsumerState<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends ConsumerState<IdentifyScreen> {
  late final _vernacular = TextEditingController(text: widget.args.initial?.vernacular);
  late final _genus = TextEditingController(text: widget.args.initial?.genus);
  late final _species = TextEditingController(text: widget.args.initial?.species);
  late final _subspecies = TextEditingController(text: widget.args.initial?.subspecies);
  late final _authorship = TextEditingController(text: widget.args.initial?.authorship);
  final _identifier = TextEditingController();
  final _focus = {for (final k in _Field.values) k: FocusNode()};

  late final Map<_Field, TextEditingController> _controllers = {
    _Field.vernacular: _vernacular,
    _Field.genus: _genus,
    _Field.species: _species,
    _Field.subspecies: _subspecies,
    _Field.authorship: _authorship,
    _Field.identifier: _identifier,
  };

  /// ō ū のボタンで文字を入れる欄。最後に触った欄。
  var _active = _Field.species;

  /// 種名の欄に打った文字から引いた、辞書の候補。
  var _candidates = const <_Candidate>[];
  var _generation = 0;

  var _date = CalendarDate.fromDateTime(DateTime.now());
  var _confirmed = false;
  var _saving = false;

  /// 候補や目録の自動入力で文字を入れている間は、入力の変化で候補や自動入力をやり直さない。
  var _picking = false;
  var _autofilling = false;

  /// 目録から自動入力した種。同じ種に一致し続けている間は、消した欄を入れ直さない。
  CatalogEntry? _autoFilled;
  String? _autoFillNote;

  static const _nameFields = [_Field.vernacular, _Field.genus, _Field.species, _Field.subspecies];

  @override
  void initState() {
    super.initState();
    _loadDefaultIdentifier();
    // 目録は大きいので、画面を開いたときから読み込んでおく
    ref.read(speciesCatalogProvider.future).ignore();
    for (final MapEntry(:key, :value) in _controllers.entries) {
      value.addListener(() {
        if (!_picking && !_autofilling && _nameFields.contains(key)) {
          if (_focus[key]!.hasFocus) _refreshCandidates(value.text);
          _autoFill();
        }
        setState(() {});
      });
      _focus[key]!.addListener(() {
        if (_focus[key]!.hasFocus) setState(() => _active = key);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  SpeciesName get _name => SpeciesName(
    vernacular: _vernacular.text,
    genus: _genus.text,
    species: _species.text,
    subspecies: _subspecies.text,
    authorship: _authorship.text,
  );

  /// 同定者の既定は、最後に入力した名前。
  Future<void> _loadDefaultIdentifier() async {
    final settings = await ref.read(settingsServiceProvider).read();
    if (mounted && _identifier.text.isEmpty) _identifier.text = settings.lastIdentifier ?? '';
  }

  Future<void> _refreshCandidates(String query) async {
    final generation = ++_generation;
    final fromDictionary = await ref.read(dictionaryServiceProvider).suggestSpecies(query);
    if (!mounted || generation != _generation) return;
    // 自分で使った種(辞書)を先に、目録の種をその後ろに並べる。同じ種名は1つにまとめる
    final catalog = ref.read(speciesCatalogProvider).value ?? SpeciesCatalog.empty;
    final found = <String, _Candidate>{
      for (final n in fromDictionary) n.key: _Candidate(n, fromCatalog: false),
    };
    for (final e in catalog.search(query)) {
      final n = e.toSpeciesName();
      found.putIfAbsent(n.key, () => _Candidate(n, fromCatalog: true));
    }
    setState(() => _candidates = found.values.toList());
  }

  /// 入力した和名・学名が目録の1つの種に一致したら、空の欄を目録から埋める。
  /// 入力済みの欄は書き換えない。
  void _autoFill() {
    final catalog = ref.read(speciesCatalogProvider).value;
    if (catalog == null) return;
    final match = catalog.uniqueMatch(_name);
    if (match == null) {
      _autoFilled = null;
      _autoFillNote = null;
      return;
    }
    if (identical(match, _autoFilled)) return;
    _autoFilled = match;

    final filled = <String>[];
    void fill(TextEditingController c, String? value, String label) {
      if (value != null && c.text.trim().isEmpty) {
        c.text = value;
        filled.add(label);
      }
    }

    _autofilling = true;
    fill(_vernacular, match.vernacular, '和名');
    fill(_genus, match.genus, '属');
    fill(_species, match.species, '種');
    fill(_subspecies, match.subspecies, '亜種');
    fill(_authorship, match.authorship, '命名者・年');
    _autofilling = false;
    _autoFillNote = filled.isEmpty ? null : '目録から入力しました: ${filled.join('・')}';
  }

  /// 候補を選ぶと、和名・学名・命名者・年がまとめて入る。
  void _pick(SpeciesName c) {
    _picking = true;
    _generation++;
    _vernacular.text = c.vernacular ?? '';
    _genus.text = c.genus ?? '';
    _species.text = c.species ?? '';
    _subspecies.text = c.subspecies ?? '';
    _authorship.text = c.authorship ?? '';
    _picking = false;
    // 選んだ種が目録の種と一致するなら、消した欄を勝手に入れ直さない
    _autoFilled = ref.read(speciesCatalogProvider).value?.uniqueMatch(_name);
    _autoFillNote = null;
    setState(() => _candidates = const []);
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_date.year, _date.month, _date.day),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = CalendarDate.fromDateTime(picked));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(identificationServiceProvider).add(
        widget.args.specimenIds,
        name: _name,
        identifiedBy: _identifier.text,
        dateIdentified: _date,
        status: IdentificationService.statusFor(_name, confirmed: _confirmed),
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
    final name = _name;
    final status = IdentificationService.statusFor(name, confirmed: _confirmed);
    return Scaffold(
      appBar: AppBar(title: Text(count > 1 ? '同定入力($count件)' : '同定入力')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FormBlock(
            color: BlockColors.identification,
            title: '種名',
            children: [
              _field(_Field.vernacular, '和名(任意)', hint: '例: オサムシ'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _field(_Field.genus, '属', hint: 'Carabus', italic: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_Field.species, '種', hint: 'insulicola', italic: true)),
                ],
              ),
              const SizedBox(height: 8),
              _field(_Field.subspecies, '亜種', italic: true),
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
              MacronButtons(controller: _controllers[_active]!, onInserted: () {}),
            ],
          ),
          FormBlock(
            color: BlockColors.identification,
            title: '同定',
            children: [
              _field(_Field.identifier, '同定者'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event),
                label: Text('同定日 ${_date.toIso()}'),
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
                  selected: {_confirmed},
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: BlockColors.identification,
                    selectedForegroundColor: Colors.white,
                  ),
                  onSelectionChanged: (s) => setState(() => _confirmed = s.first),
                ),
            ],
          ),
        ],
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

  Widget _field(_Field f, String label, {String? hint, bool italic = false}) => TextField(
    controller: _controllers[f],
    focusNode: _focus[f],
    style: italic ? const TextStyle(fontStyle: FontStyle.italic) : null,
    decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder(), isDense: true),
  );

  Widget _candidateList() => Card(
    margin: const EdgeInsets.only(top: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Text('候補(選ぶとまとめて入ります)', style: TextStyle(fontSize: 12)),
        ),
        for (final c in _candidates)
          ListTile(
            dense: true,
            title: Text(c.name.label),
            subtitle: c.name.authorship == null ? null : Text(c.name.authorship!),
            trailing: c.fromCatalog ? const Text('目録', style: TextStyle(fontSize: 12)) : null,
            onTap: () => _pick(c.name),
          ),
      ],
    ),
  );
}

/// 種名の候補。辞書(自分が使った種)か、甲虫の目録から。
class _Candidate {
  const _Candidate(this.name, {required this.fromCatalog});

  final SpeciesName name;
  final bool fromCatalog;
}

enum _Field { vernacular, genus, species, subspecies, authorship, identifier }
