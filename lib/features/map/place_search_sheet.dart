import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gsi/gsi_api.dart';
import '../../services/service_providers.dart';

/// 地名・住所の検索(地理院の地名検索API。通信が要る)。選んだ場所を返す。
/// 山や川などの自然地名・施設名・住所を、漢字でもひらがなでも引ける。
Future<PlaceHit?> showPlaceSearch(BuildContext context) =>
    showModalBottomSheet<PlaceHit>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _PlaceSearchSheet(),
    );

class _PlaceSearchSheet extends ConsumerStatefulWidget {
  const _PlaceSearchSheet();

  @override
  ConsumerState<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends ConsumerState<_PlaceSearchSheet> {
  final _query = TextEditingController();
  Timer? _debounce;

  var _searching = false;
  String? _error;
  List<PlaceHit>? _hits;

  /// 古い検索の結果が新しい結果を上書きしないよう、検索ごとに番号を付ける。
  var _serial = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  /// 入力が止まって0.6秒たったら検索する(1文字ごとに通信しない)。
  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _search);
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final text = _query.text.trim();
    final serial = ++_serial;
    if (text.isEmpty) {
      setState(() {
        _hits = null;
        _error = null;
        _searching = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final hits = await ref.read(gsiApiProvider).searchPlaces(text);
      if (!mounted || serial != _serial) return;
      setState(() {
        _hits = hits;
        _searching = false;
      });
    } on GsiNetworkException {
      if (!mounted || serial != _serial) return;
      setState(() {
        _hits = null;
        _searching = false;
        _error = '通信できません。地名検索は、電波がある場所で使えます';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hits = _hits;
    // シートの高さは最初から固定する(キーボードで高さが変わると、開く途中で止まって広がる動きになる)。
    // キーボードの分は、中身だけを縮めて避ける
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '地名・山名・住所(例: 武尊山、ほたか)',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _query.clear();
                            _search();
                          },
                        ),
                ),
                onChanged: (v) {
                  setState(() {}); // 消去ボタンの出し入れ
                  _onChanged(v);
                },
                onSubmitted: (_) => _search(),
              ),
            ),
            if (_searching) const LinearProgressIndicator(),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!),
                      ),
                    )
                  : hits == null
                  ? const SizedBox.shrink()
                  : hits.isEmpty
                  ? const Center(child: Text('見つかりませんでした'))
                  : ListView.builder(
                      itemCount: hits.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(hits[i].title),
                        subtitle: Text(
                          '${hits[i].latitude.toStringAsFixed(4)}, ${hits[i].longitude.toStringAsFixed(4)}',
                        ),
                        onTap: () => Navigator.pop(context, hits[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
