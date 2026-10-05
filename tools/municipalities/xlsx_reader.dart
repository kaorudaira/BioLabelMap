import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// xlsx のシートを、行ごとの「列名(A, B, …)→ 文字列」として読む。最小限の実装。
List<Map<String, String>> readXlsxSheet(String path, int sheetNumber) {
  final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
  XmlDocument xmlOf(String name) =>
      XmlDocument.parse(utf8.decode(archive.findFile(name)!.content as List<int>));

  final shared = archive.findFile('xl/sharedStrings.xml') == null
      ? <String>[]
      : xmlOf('xl/sharedStrings.xml')
            .findAllElements('si')
            .map(_textOf)
            .toList();

  final rows = <Map<String, String>>[];
  for (final row in xmlOf('xl/worksheets/sheet$sheetNumber.xml').findAllElements('row')) {
    final cells = <String, String>{};
    for (final c in row.findElements('c')) {
      final column = c.getAttribute('r')!.replaceAll(RegExp(r'\d'), '');
      final v = c.getElement('v')?.innerText;
      final value = switch (c.getAttribute('t')) {
        's' => v == null ? '' : shared[int.parse(v)],
        'inlineStr' => c.getElement('is') == null ? '' : _textOf(c.getElement('is')!),
        _ => v ?? '',
      };
      cells[column] = value.trim();
    }
    rows.add(cells);
  }
  return rows;
}

/// 文字列要素の本文。ふりがな(rPh)は含めない。
/// 本文は `<si><t>` か、書式付きなら `<si><r><t>` に入っている。
String _textOf(XmlElement si) => [
  ...si.findElements('t'),
  for (final r in si.findElements('r')) ...r.findElements('t'),
].map((t) => t.innerText).join();
