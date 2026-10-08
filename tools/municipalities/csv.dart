import 'dart:convert';

/// ダブルクォートで囲まれたフィールドを含む CSV を読む(改行を含むフィールドは扱わない)。
List<List<String>> parseCsv(String content) {
  final rows = <List<String>>[];
  for (final line in const LineSplitter().convert(content)) {
    if (line.isEmpty) continue;
    final fields = <String>[];
    final buf = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (quoted) {
        if (c == '"' && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else if (c == '"') {
          quoted = false;
        } else {
          buf.write(c);
        }
      } else if (c == '"') {
        quoted = true;
      } else if (c == ',') {
        fields.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    fields.add(buf.toString());
    rows.add(fields);
  }
  return rows;
}
