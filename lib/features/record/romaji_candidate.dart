import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/gsi/oaza_romaji_table.dart';

/// 公的データから作った大字のローマ字の候補。「使う」で入力欄に入れる(要件定義 第5章)。
///
/// マクロンを含む候補は、語の境目の「ou」「oo」まで長音にしていることがあるので、確認を促す。
class RomajiCandidate extends StatelessWidget {
  const RomajiCandidate({super.key, required this.candidate, required this.onUse});

  final OazaRomaji candidate;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('公的データの候補: ${candidate.value}'),
                if (candidate.needsConfirmation)
                  Text(
                    '長音(ō・ū)が正しいか確かめてください。語の境目(丸の内=Marunouchi など)は長音にしません',
                    style: small?.copyWith(color: warningColor),
                  ),
              ],
            ),
          ),
          TextButton(onPressed: onUse, child: const Text('使う')),
        ],
      ),
    );
  }
}
