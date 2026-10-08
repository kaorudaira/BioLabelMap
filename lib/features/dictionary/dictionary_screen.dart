import 'package:flutter/material.dart';

import '../common/clear_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../domain/dictionary.dart';
import '../../domain/species_name.dart';
import '../../services/dictionary_service.dart';
import '../../services/service_providers.dart';
import '../record/macron_buttons.dart';

/// 辞書管理(要件定義 S-10)。地名のローマ字、種、環境、寄主植物の候補を編集する。
/// 辞書を変えても、保存済みの標本は変わらない。
class DictionaryScreen extends ConsumerWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(dictionaryServiceProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('辞書管理'),
          bottom: const TabBar(
            tabs: [Tab(text: '地名'), Tab(text: '種'), Tab(text: '環境'), Tab(text: '寄主植物')],
          ),
        ),
        body: TabBarView(
          children: [
            _DictTab(
              stream: service.watchPlaces().map((rows) => [
                for (final r in rows)
                  _Item(
                    id: r.entry.id,
                    title: _placeTitle(ref, r.entry.municipalityCode, r.entry.localityJa),
                    subtitle: r.entry.localityEn,
                    usedBy: r.usedBy,
                    search: '${r.entry.localityJa} ${r.entry.localityEn}',
                  ),
              ]),
              empty: '大字のローマ字は、入力すると自動で溜まります',
              onEdit: (item) async {
                final en = await _askText(context, '大字のローマ字', initial: item.subtitle ?? '', macron: true);
                if (en != null) await service.updatePlaceRomaji(item.id, en);
              },
              onDelete: (ids) async {
                for (final id in ids) {
                  await service.deletePlace(id);
                }
              },
            ),
            _DictTab(
              stream: service.watchSpecies().map((rows) => [
                for (final r in rows)
                  _Item(
                    id: r.entry.id,
                    title: speciesNameOfEntry(r.entry).label,
                    subtitle: r.entry.authorship.isEmpty ? null : r.entry.authorship,
                    usedBy: r.usedBy,
                    search: '${r.entry.vernacular} ${r.entry.genus} ${r.entry.species} ${r.entry.subspecies}',
                    italicFrom: r.entry.vernacular.isEmpty ? 0 : r.entry.vernacular.length + 1,
                    name: speciesNameOfEntry(r.entry),
                  ),
              ]),
              empty: '同定を入力すると、種名が自動で溜まります',
              onAdd: () async {
                final name = await _askSpecies(context);
                if (name != null) await service.addSpecies(name);
              },
              onEdit: (item) async {
                final name = await _askSpecies(context, initial: item.name);
                if (name != null) await service.updateSpecies(item.id, name);
              },
              onDelete: (ids) async {
                for (final id in ids) {
                  await service.deleteSpecies(id);
                }
              },
              onMerge: service.mergeSpecies,
            ),
            _textTab(context, service, DictTextKind.habitat),
            _textTab(context, service, DictTextKind.hostPlant),
          ],
        ),
      ),
    );
  }

  Widget _textTab(BuildContext context, DictionaryService service, DictTextKind kind) => _DictTab(
    stream: service.watchTexts(kind).map((rows) => [
      for (final r in rows) _Item(id: r.entry.id, title: r.entry.value, usedBy: r.usedBy, search: r.entry.value),
    ]),
    empty: '${kind.label}は、記録すると自動で溜まります',
    onAdd: () async {
      final v = await _askText(context, '${kind.label}を追加');
      if (v != null) await service.addText(kind, v);
    },
    onEdit: (item) async {
      final v = await _askText(context, '${kind.label}を編集', initial: item.title);
      if (v != null) await service.updateText(item.id, v);
    },
    onDelete: (ids) async {
      for (final id in ids) {
        await service.deleteText(id);
      }
    },
    onMerge: service.mergeTexts,
  );

  /// 自治体名と大字。自治体コードが対応表に無ければコードのまま出す。
  static String _placeTitle(WidgetRef ref, String code, String localityJa) {
    String? municipality;
    try {
      municipality = ref.read(municipalityDirectoryProvider).lookup(code)?.municipalityJa;
    } on Object {
      // 対応表が読み込まれていないとき(テストなど)
    }
    return '${municipality ?? code} $localityJa';
  }
}

/// 一覧の1行分。タブごとの違いは、ここに入れてから共通の一覧で扱う。
class _Item {
  const _Item({
    required this.id,
    required this.title,
    this.subtitle,
    required this.usedBy,
    required this.search,
    this.italicFrom,
    this.name,
  });

  final int id;
  final String title;
  final String? subtitle;
  final int usedBy;

  /// 検索の対象にする文字。
  final String search;

  /// 学名を斜体にする、タイトル中の開始位置(種のタブ)。
  final int? italicFrom;

  /// 種のタブで、編集の初期値にする種名。
  final SpeciesName? name;
}

class _DictTab extends StatefulWidget {
  const _DictTab({
    required this.stream,
    required this.empty,
    this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.onMerge,
  });

  final Stream<List<_Item>> stream;
  final String empty;
  final Future<void> Function()? onAdd;
  final Future<void> Function(_Item item) onEdit;
  final Future<void> Function(List<int> ids) onDelete;

  /// 統合。残す候補の ID と、統合する候補の ID(残す候補も含む)を渡す。
  final Future<void> Function(int keepId, Iterable<int> ids)? onMerge;

  @override
  State<_DictTab> createState() => _DictTabState();
}

class _DictTabState extends State<_DictTab> with AutomaticKeepAliveClientMixin {
  var _query = '';
  final _searchController = TextEditingController();
  final _selected = <int>{};

  /// 最後に受け取った一覧(統合の選択肢を作るのに使う)。
  var _all = const <_Item>[];

  @override
  bool get wantKeepAlive => true;

  /// 操作に失敗したら、理由を知らせる。
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on DictionaryConflictException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on ArgumentError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<_Item>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        final all = _all = snapshot.data ?? const <_Item>[];
        final words = _query.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
        final shown = [
          for (final i in all)
            if (words.every(i.search.toLowerCase().contains)) i,
        ];
        return Scaffold(
          body: Column(
            children: [
              if (_selected.isNotEmpty) _selectionBar() else _searchBar(),
              Expanded(
                child: !snapshot.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : all.isEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(widget.empty)))
                    : shown.isEmpty
                    ? const Center(child: Text('合う候補はありません'))
                    : ListView.builder(
                        itemCount: shown.length,
                        itemBuilder: (context, i) => _tile(shown[i]),
                      ),
              ),
            ],
          ),
          floatingActionButton: widget.onAdd == null || _selected.isNotEmpty
              ? null
              : FloatingActionButton(
                  tooltip: '追加',
                  onPressed: () => _run(widget.onAdd!),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: TextField(
      controller: _searchController,
      decoration: withClear(
        const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: '検索',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        _searchController,
        onCleared: () => setState(() => _query = ''),
      ),
      onChanged: (v) => setState(() => _query = v),
    ),
  );

  Widget _selectionBar() => Material(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Row(
      children: [
        IconButton(tooltip: '選択を解除', icon: const Icon(Icons.close), onPressed: () => setState(_selected.clear)),
        Expanded(child: Text('${_selected.length}件を選択')),
        if (widget.onMerge != null)
          TextButton(onPressed: _selected.length >= 2 ? _merge : null, child: const Text('統合')),
        TextButton(onPressed: _delete, child: const Text('削除')),
      ],
    ),
  );

  Widget _tile(_Item item) {
    final selected = _selected.contains(item.id);
    final selecting = _selected.isNotEmpty;
    final base = Theme.of(context).textTheme.bodyLarge;
    return ListTile(
      selected: selected,
      leading: selecting ? Icon(selected ? Icons.check_circle : Icons.circle_outlined) : null,
      title: item.italicFrom == null || item.title.length <= item.italicFrom!
          ? Text(item.title)
          : Text.rich(
              TextSpan(
                style: base,
                children: [
                  TextSpan(text: item.title.substring(0, item.italicFrom!)),
                  TextSpan(
                    text: item.title.substring(item.italicFrom!),
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
      subtitle: item.subtitle == null ? null : Text(item.subtitle!),
      trailing: Text(
        item.usedBy == 0 ? '未使用' : '${item.usedBy}件',
        style: TextStyle(color: item.usedBy == 0 ? Theme.of(context).disabledColor : BlockColors.specimen),
      ),
      onTap: () {
        if (selecting) {
          setState(() => selected ? _selected.remove(item.id) : _selected.add(item.id));
        } else {
          _run(() => widget.onEdit(item));
        }
      },
      onLongPress: () => setState(() => selected ? _selected.remove(item.id) : _selected.add(item.id)),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_selected.length}件を辞書から削除しますか'),
        content: const Text('保存済みの標本は変わりません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('やめる')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );
    if (ok != true) return;
    final ids = _selected.toList();
    setState(_selected.clear);
    await _run(() => widget.onDelete(ids));
  }

  /// 選んだ候補を、残す1つにまとめる。
  Future<void> _merge() async {
    // 一覧に出ている中から、選んだものを探す(検索で隠れていても統合できるよう、ID だけで扱う)
    final candidates = [for (final i in _all) if (_selected.contains(i.id)) i];
    final keep = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('どれに統合しますか'),
        children: [
          for (final c in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, c.id),
              child: Text('${c.title}(${c.usedBy}件)'),
            ),
        ],
      ),
    );
    if (keep == null) return;
    final ids = _selected.toList();
    setState(_selected.clear);
    await _run(() => widget.onMerge!(keep, ids));
  }
}

/// 1行の文字を入力する。キャンセルや空のときは null。
Future<String?> _askText(BuildContext context, String title, {String initial = '', bool macron = false}) =>
    showDialog<String>(
      context: context,
      builder: (context) => _TextDialog(title: title, initial: initial, macron: macron),
    );

// 入力欄の controller は、閉じるアニメーションが終わるまで使われるので、
// ダイアログの State が持ち、State の破棄と一緒に捨てる。
class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title, required this.initial, required this.macron});

  final String title;
  final String initial;
  final bool macron;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: withClear(const InputDecoration(border: OutlineInputBorder()), _controller),
          ),
          if (widget.macron) ...[
            const SizedBox(height: 8),
            MacronButtons(controller: _controller, onInserted: () {}),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('やめる')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim().isEmpty ? null : _controller.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 種名を入力する。キャンセルのときは null。
Future<SpeciesName?> _askSpecies(BuildContext context, {SpeciesName? initial}) => showDialog<SpeciesName>(
  context: context,
  builder: (context) => _SpeciesDialog(initial: initial),
);

class _SpeciesDialog extends StatefulWidget {
  const _SpeciesDialog({this.initial});

  final SpeciesName? initial;

  @override
  State<_SpeciesDialog> createState() => _SpeciesDialogState();
}

class _SpeciesDialogState extends State<_SpeciesDialog> {
  static const _labels = ['和名', '属', '種', '亜種', '命名者・年'];

  late final _controllers = [
    TextEditingController(text: widget.initial?.vernacular),
    TextEditingController(text: widget.initial?.genus),
    TextEditingController(text: widget.initial?.species),
    TextEditingController(text: widget.initial?.subspecies),
    TextEditingController(text: widget.initial?.authorship),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '種を追加' : '種を編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _controllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _controllers[i],
                  decoration: withClear(
                    InputDecoration(labelText: _labels[i], border: const OutlineInputBorder(), isDense: true),
                    _controllers[i],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('やめる')),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            SpeciesName(
              vernacular: _controllers[0].text,
              genus: _controllers[1].text,
              species: _controllers[2].text,
              subspecies: _controllers[3].text,
              authorship: _controllers[4].text,
            ),
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
