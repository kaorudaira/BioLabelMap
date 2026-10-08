import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../domain/specimen_list.dart';
import '../../domain/status.dart';
import '../../services/service_providers.dart';
import '../specimen/add_at_locality.dart';

/// 地図のピンをタップしたときに、ピンの上に出す吹き出し。登録されている和名と、日本語の住所を出す。
class PinBubble extends ConsumerWidget {
  const PinBubble({
    super.key,
    required this.localityId,
    this.shiftX = 0,
    this.below = false,
  });

  final int localityId;

  /// 画面の端のピンで、吹き出しが画面の外に出ないよう、横にずらす量(右が正)。先の三角は、ずらさない。
  final double shiftX;

  /// ピンの下に置く(画面の上の端のピン)。先の三角は、上に付ける。
  final bool below;

  /// 吹き出しの幅。
  static const width = 220.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locality = ref.watch(localityProvider(localityId)).value;
    final items =
        ref.watch(specimenItemsProvider).value ?? const <SpecimenListItem>[];
    final here = locality == null
        ? const <SpecimenListItem>[]
        : specimensAtLocality(items, locality);
    final lines = speciesSummaryLines(here);
    final theme = Theme.of(context);

    final card = Transform.translate(
      offset: Offset(shiftX, 0),
      child: Material(
        elevation: 4,
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _address(locality),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BlockColors.location,
                ),
              ),
              const SizedBox(height: 4),
              if (lines.isEmpty)
                Text('標本はありません', style: theme.textTheme.bodySmall)
              else
                for (final line in lines)
                  Text(
                    line,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: line.startsWith('未同定')
                          ? theme.disabledColor
                          : BlockColors.identification,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
    // 吹き出しの先(ピンを指す三角)。吹き出しを横にずらしても、ピンを指したまま。ピンの下に置くときは、上に付ける
    final tail = CustomPaint(
      size: const Size(16, 8),
      painter: _TailPainter(pointUp: below),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: below ? [tail, card] : [card, tail],
    );
  }

  /// 日本語の住所(郡+市町村+大字。県を含む)。未取得のときは、その旨。
  static String _address(Locality? l) {
    if (l == null) return '';
    final address = formatPlaceJa(
      prefecture: l.prefectureJa,
      county: l.countyJa,
      municipality: l.municipalityJa,
      locality: l.localityJa,
    );
    if (address.isNotEmpty) return address;
    return l.placeStatus == FetchStatus.pending ? '地名 取得待ち' : '地名なし';
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter({required this.pointUp});

  final bool pointUp;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointUp) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width / 2, 0);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TailPainter oldDelegate) =>
      oldDelegate.pointUp != pointUp;
}

/// ピンをタップしたときに、記録ボタンの上に出すウィンドウ。「この地点で追加」と「詳細をひらく」。
class PinActionCard extends StatelessWidget {
  const PinActionCard({
    super.key,
    required this.onAdd,
    required this.onOpenDetail,
    required this.onClose,
  });

  final VoidCallback onAdd;
  final VoidCallback onOpenDetail;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('この地点で追加'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpenDetail,
                icon: const Icon(Icons.list_alt),
                label: const Text('詳細をひらく'),
              ),
            ),
            IconButton(
              tooltip: '閉じる',
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
