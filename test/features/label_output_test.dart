import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/label/label_pdf.dart';
import 'package:biolabelmap/domain/elevation_rounding.dart';
import 'package:biolabelmap/domain/label/data_label_builder.dart';
import 'package:biolabelmap/domain/label/data_label_layout.dart';
import 'package:biolabelmap/domain/label/label_sheet.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/models/place_info.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/services/label_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

ByteData _font(String name) => ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());

void main() {
  final fonts = LabelFonts(
    latin: _font('FiraSansCondensed-Regular.ttf'),
    japanese: _font('BIZUDPGothic-Regular.ttf'),
  );

  group('LabelSheetSpec', () {
    test('はがきに 15×10mm は 6列×14行=84枚', () {
      const sheet = LabelSheetSpec.postcard;
      expect(sheet.columns, 6);
      expect(sheet.rows, 14);
      expect(sheet.perPage, 84);
      expect(sheet.pagesFor(0), 0);
      expect(sheet.pagesFor(84), 1);
      expect(sheet.pagesFor(85), 2);
    });

    test('余白が足りないプリンタ向けに上下余白を広げると13行(78枚)', () {
      const sheet = LabelSheetSpec(marginYMm: 9);
      expect(sheet.rows, 13);
      expect(sheet.perPage, 78);
    });
  });

  group('arrangeLabels', () {
    final layout = layoutDataLabel(
      buildDataLabel(DataLabelSource(
        latitude: 36.9447,
        longitude: 139.2426,
        period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
      )),
      measurer: fonts.measurer,
    );
    final specimens = [
      for (final n in [123, 124, 125])
        SpecimenLabels(specimenId: n, catalogText: 'KYC00$n', dataLabel: layout),
    ];
    String describe(PlacedLabel l) => '${l.kind.name}:${l.specimen.catalogText}';

    test('標本ごとに並べると、データとコレクションが隣り合う', () {
      expect(arrangeLabels(specimens, LabelArrangement.bySpecimen).map(describe), [
        'data:KYC00123', 'collection:KYC00123',
        'data:KYC00124', 'collection:KYC00124',
        'data:KYC00125', 'collection:KYC00125',
      ]);
    });

    test('種類ごとにまとめると、データを全部並べてからコレクションを並べる', () {
      expect(arrangeLabels(specimens, LabelArrangement.byKind).map(describe), [
        'data:KYC00123', 'data:KYC00124', 'data:KYC00125',
        'collection:KYC00123', 'collection:KYC00124', 'collection:KYC00125',
      ]);
    });
  });

  group('ラベル出力の流れ(DB → データラベル → PDF → 印刷済み)', () {
    late AppDatabase db;
    late LabelService labels;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      labels = LabelService(db);
      final settings = SettingsService(db);
      await settings.initializeCatalog(122);
      await settings.setCollectorName('Kaoru Yoshihara');
      await RecordService(db).save(RecordInput(
        position: const NewPosition(
          latitude: 36.94471,
          longitude: 139.24262,
          elevationMeters: 1388.4,
          place: PlaceInfo(
            municipalityCode: '15225',
            prefectureJa: '新潟県',
            municipalityJa: '魚沼市',
            localityJa: '下折立',
            prefectureEn: 'Niigata-ken',
            municipalityEn: 'Uonuma-shi',
            localityEn: 'Shimooritate',
          ),
        ),
        period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
        recordedAt: DateTime(2026, 6, 20),
        samplingMethod: SamplingMethod.sweeping,
        count: 3,
      ));
    });

    tearDown(() => db.close());

    test('候補から要件定義の例どおりのデータラベルを作る', () async {
      final candidates = await labels.watchCandidates().first;
      expect(candidates.map((c) => c.specimen.catalogText), ['KYC00123', 'KYC00124', 'KYC00125']);
      expect(candidates.first.pendingEnrichment, isFalse);

      final lines = buildDataLabel(candidates.first.toSource(ElevationRounding.tenMeters));
      expect(
        dataLabelAsSingleLine(lines),
        'JAPAN: Niigata-ken, Uonuma-shi, Shimooritate, (alt. 1390 m), '
        '36.9447°N 139.2426°E, 20. VI. 2026, K. YOSHIHARA, 魚沼市下折立',
      );
    });

    test('PDF を作れる(1ページ、フォントを埋め込む)', () async {
      final candidates = await labels.watchCandidates().first;
      final pdf = await buildLabelPdf(
        labels: arrangeLabels(
          [
            for (final c in candidates)
              SpecimenLabels(
                specimenId: c.specimen.id,
                catalogText: c.specimen.catalogText,
                dataLabel: layoutDataLabel(
                  buildDataLabel(c.toSource(ElevationRounding.tenMeters)),
                  measurer: fonts.measurer,
                ),
              ),
          ],
          LabelArrangement.bySpecimen,
        ),
        fonts: fonts,
      );
      final text = String.fromCharCodes(pdf.take(8));
      expect(text, startsWith('%PDF-'));
      final body = latin1.decode(pdf, allowInvalid: true);
      expect(RegExp(r'/Type\s*/Page[^s]').allMatches(body), hasLength(1));
      // 和文は使った文字だけを埋め込むので、フォント全体(4.5MB)より十分小さい
      expect(pdf.length, lessThan(1024 * 1024));
    });

    test('印刷済みにすると、印字した標高と地名を残す', () async {
      final candidates = await labels.watchCandidates().first;
      final layouts = {
        for (final c in candidates)
          c.specimen.id: layoutDataLabel(
            buildDataLabel(c.toSource(ElevationRounding.tenMeters)),
            measurer: fonts.measurer,
          ),
      };
      await labels.markPrinted(layouts, now: DateTime(2026, 6, 21, 20));

      final after = await labels.watchCandidates().first;
      expect(after.every((c) => c.printed), isTrue);
      expect(after.first.specimen.printedElevation, '1390');
      expect(after.first.specimen.printedPlace, 'JAPAN: Niigata-ken Uonuma-shi, Shimooritate 魚沼市下折立');
    });
  });
}
