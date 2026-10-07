import 'package:flutter/material.dart';

import '../../domain/species_name.dart';

/// 種名の表示。和名は立体、学名はイタリック体にする。和名も学名も無ければ「未同定」。
/// [suffix] は、種名の後ろに続ける文字(件数など)で、立体にする。
class SpeciesNameText extends StatelessWidget {
  const SpeciesNameText(this.name, {super.key, this.style, this.suffix});

  final SpeciesName name;
  final TextStyle? style;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final scientific = name.scientific;
    return Text.rich(
      TextSpan(
        children: [
          if (name.vernacular != null) TextSpan(text: name.vernacular),
          if (name.vernacular != null && scientific != null) const TextSpan(text: ' '),
          if (scientific != null) TextSpan(text: scientific, style: const TextStyle(fontStyle: FontStyle.italic)),
          if (name.isEmpty) TextSpan(text: name.label),
          if (suffix != null) TextSpan(text: suffix),
        ],
      ),
      style: style,
    );
  }
}
