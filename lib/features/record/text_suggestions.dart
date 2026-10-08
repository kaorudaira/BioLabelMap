import 'package:flutter/material.dart';

/// 入力中の文字に合う辞書の候補を、欄の下に並べる(要件定義 F-10)。タップで入力欄に入れる。
/// 何も入力していないときは出さない。
class TextSuggestions extends StatefulWidget {
  const TextSuggestions({super.key, required this.controller, required this.fetch, this.onPicked});

  final TextEditingController controller;

  /// 入力中の文字から、候補を引く。
  final Future<List<String>> Function(String query) fetch;

  /// 候補を選んだとき(入力済みの扱いにするなど)。
  final VoidCallback? onPicked;

  @override
  State<TextSuggestions> createState() => _TextSuggestionsState();
}

class _TextSuggestionsState extends State<TextSuggestions> {
  var _candidates = const <String>[];
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    final query = widget.controller.text.trim();
    final generation = ++_generation;
    if (query.isEmpty) {
      if (_candidates.isNotEmpty) setState(() => _candidates = const []);
      return;
    }
    final found = await widget.fetch(query);
    // 打ち込みが進んで古くなった結果は捨てる
    if (!mounted || generation != _generation) return;
    setState(() => _candidates = found);
  }

  @override
  Widget build(BuildContext context) {
    if (_candidates.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 0,
        children: [
          for (final c in _candidates)
            ActionChip(
              label: Text(c),
              onPressed: () {
                widget.controller.text = c;
                widget.controller.selection = TextSelection.collapsed(offset: c.length);
                widget.onPicked?.call();
              },
            ),
        ],
      ),
    );
  }
}
