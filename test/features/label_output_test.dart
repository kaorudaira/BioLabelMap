import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/label/label_pdf.dart';
import 'package:biolabelmap/domain/elevation_rounding.dart';
import 'package:biolabelmap/domain/label/data_label_builder.dart';
import 'package:biolabelmap/domain/label/data_label_layout.dart';
import 'package:biolabelmap/domain/label/identification_label.dart';
import 'package:biolabelmap/domain/label/label_sheet.dart';
import 'package:biolabelmap/domain/label/printed_values.dart';
import 'package:biolabelmap/services/printed_label_values.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/models/place_info.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/services/label_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

ByteData _font(String name) => ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());

void main() {
  final fonts = LabelFonts(
    latin: _font('FiraSansCondensed-Regular.ttf'),
    latinItalic: _font('FiraSansCondensed-Italic.ttf'),
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

    test('候補は最新の同定を持ち、未同定の標本は同定ラベルの材料が無い', () async {
      final before = await labels.watchCandidates().first;
      expect(before.every((c) => c.identificationSource == null), isTrue);

      final id = before.first.specimen.id;
      for (final species in ['old', 'sericea']) {
        await db.into(db.identifications).insert(
          IdentificationsCompanion.insert(
            specimenId: id,
            status: IdentificationStatus.provisional,
            vernacularName: const Value('スゲハムシ'),
            genus: const Value('Plateumaris'),
            species: Value(species),
            authorship: const Value('(Linnaeus 1761)'),
            identifiedBy: const Value('K. Yoshihara'),
          ),
        );
      }
      final after = await labels.watchCandidates().first;
      final source = after.first.identificationSource!;
      expect(source.name.scientific, 'Plateumaris sericea');
      expect(source.identifiedBy, 'K. Yoshihara');
      expect(after.skip(1).every((c) => c.identificationSource == null), isTrue);
    });

    test('同定ラベルを含めて、3種すべてのPDFを作れる', () async {
      final id = (await labels.watchCandidates().first).first.specimen.id;
      await db.into(db.identifications).insert(
        IdentificationsCompanion.insert(
          specimenId: id,
          status: IdentificationStatus.verified,
          vernacularName: const Value('スゲハムシ'),
          genus: const Value('Plateumaris'),
          species: const Value('sericea'),
          authorship: const Value('(Linnaeus 1761)'),
          identifiedBy: const Value('K. Yoshihara'),
        ),
      );
      final candidates = await labels.watchCandidates().first;
      final specimens = [
        for (final c in candidates)
          SpecimenLabels(
            specimenId: c.specimen.id,
            catalogText: c.specimen.catalogText,
            dataLabel: layoutDataLabel(buildDataLabel(c.toSource(ElevationRounding.tenMeters)), measurer: fonts.measurer),
            identificationLabel: switch (c.identificationSource) {
              final s? => layoutIdentificationLabel(s, measurer: fonts.measurer),
              null => null,
            },
          ),
      ];
      final placed = arrangeLabels(specimens, LabelArrangement.bySpecimen, unit: LabelUnit.all);
      // 3標本のデータ・コレクションと、同定した1標本の同定ラベル
      expect(placed, hasLength(7));
      final pdf = await buildLabelPdf(labels: placed, fonts: fonts);
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
      // イタリック体のフォントも埋め込む
      expect(latin1.decode(pdf, allowInvalid: true), contains('FiraSansCondensed-Italic'));
    });

    test('印刷済みにすると、ラベルに載せた元の標高と地名(省略前の値)を残す', () async {
      final candidates = await labels.watchCandidates().first;
      await labels.markPrinted({
        for (final c in candidates) c.specimen.id: currentLabelValues(c.locality, ElevationRounding.tenMeters),
      }, now: DateTime(2026, 6, 21, 20));

      final after = await labels.watchCandidates().first;
      expect(after.every((c) => c.printed), isTrue);
      expect(after.first.specimen.printedElevation, '1390');
      expect(
        after.first.specimen.printedPlace,
        ['JAPAN', 'Niigata-ken', '', 'Uonuma-shi', 'Shimooritate', '', '魚沼市', '下折立'].join(PrintedLabelValues.placeSeparator),
      );
    });

    group('ラベルと不一致', () {
      Future<void> printAll() async {
        final candidates = await labels.watchCandidates().first;
        await labels.markPrinted({
          for (final c in candidates) c.specimen.id: currentLabelValues(c.locality, ElevationRounding.tenMeters),
        });
      }

      Future<bool> mismatch({ElevationRounding rounding = ElevationRounding.tenMeters}) async =>
          (await labels.watchCandidates().first).first.labelMismatch(rounding);

      test('印刷していない標本は、不一致にならない。印刷した直後も不一致ではない', () async {
        expect(await mismatch(), isFalse);
        await printAll();
        expect(await mismatch(), isFalse);
      });

      test('標高が変わると不一致。丸めると同じ値なら、不一致にしない', () async {
        await printAll();
        await db.update(db.localities).write(const LocalitiesCompanion(elevationMeters: Value(1391)));
        expect(await mismatch(), isFalse); // 10m に丸めると 1390 のまま
        await db.update(db.localities).write(const LocalitiesCompanion(elevationMeters: Value(1420)));
        expect(await mismatch(), isTrue);
      });

      test('設定の丸めを変えると、ラベルの値が変わるので不一致', () async {
        await printAll();
        expect(await mismatch(rounding: ElevationRounding.oneMeter), isTrue); // 1388 と 1390
      });

      test('地名(英語・日本語)が変わると不一致', () async {
        await printAll();
        await db.update(db.localities).write(const LocalitiesCompanion(localityEn: Value('Shimooritate-onsen')));
        expect(await mismatch(), isTrue);
      });

      test('そのまま印刷した(標高・地名が未取得だった)標本は、補完で取得できたら不一致になる', () async {
        await db.update(db.localities).write(const LocalitiesCompanion(elevationMeters: Value(null), localityJa: Value(null)));
        await printAll();
        expect(await mismatch(), isFalse);
        await db.update(db.localities).write(const LocalitiesCompanion(elevationMeters: Value(1388.4), localityJa: Value('下折立')));
        expect(await mismatch(), isTrue);
      });

      test('再印刷して印刷済みにし直すと、不一致は解消する', () async {
        await printAll();
        await db.update(db.localities).write(const LocalitiesCompanion(elevationMeters: Value(1420)));
        expect(await mismatch(), isTrue);
        await printAll();
        expect(await mismatch(), isFalse);
      });

      test('古い形式で残した地名(印字した文字列)は、元の値が分からないので、地名では不一致にしない。標高は比べる', () async {
        await printAll();
        await (db.update(db.specimens)).write(
          const SpecimensCompanion(printedPlace: Value('JAPAN: Niigata-ken Uonuma-shi, Shimooritate 魚沼市下折立')),
        );
        await db.update(db.localities).write(const LocalitiesCompanion(localityEn: Value('Other')));
        expect(await mismatch(), isFalse);
        await db.update(db.localities).write(const LocalitiesCompanion(elevationMeters: Value(1420)));
        expect(await mismatch(), isTrue);
      });
    });
  });

  group('大字のローマ字をラベル出力で入れる', () {
    late AppDatabase db;
    late LabelService labels;

    // 圏外で記録し、あとから地名だけ補完された状態(ローマ字は空)
    PlaceInfo place(String localityJa) => PlaceInfo(
      municipalityCode: '15225',
      prefectureJa: '新潟県',
      municipalityJa: '魚沼市',
      localityJa: localityJa,
      prefectureEn: 'Niigata-ken',
      municipalityEn: 'Uonuma-shi',
    );

    Future<void> record(double lat, PlaceInfo? place) => RecordService(db).save(RecordInput(
      position: NewPosition(latitude: lat, longitude: 139.2426, elevationMeters: 1388, place: place),
      period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
      recordedAt: DateTime(2026, 6, 20),
      samplingMethod: SamplingMethod.sweeping,
    ));

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      labels = LabelService(db);
      await SettingsService(db).initializeCatalog(122);
      await record(36.9447, place('下折立')); // KYC00123
      await record(36.9512, place('下折立')); // KYC00124(同じ大字の別地点)
      await record(36.9600, place('上折立')); // KYC00125
      await record(36.9700, null); // KYC00126(地名は補完待ち)
    });

    tearDown(() => db.close());

    Future<Map<String, LabelCandidate>> candidates() async => {
      for (final c in await labels.watchCandidates().first) c.specimen.catalogText: c,
    };

    test('大字があってローマ字が空の地点だけを、未入力として扱う', () async {
      final c = await candidates();
      expect(c['KYC00123']!.missingLocalityRomaji, isTrue);
      expect(c['KYC00125']!.missingLocalityRomaji, isTrue);
      // 補完待ちは大字がまだ分からないので、未入力には数えない(補完待ちとして警告する)
      expect(c['KYC00126']!.missingLocalityRomaji, isFalse);
      expect(c['KYC00126']!.pendingEnrichment, isTrue);
    });

    test('入れたローマ字は、同じ大字の地点すべてと辞書に入り、ラベルに印字される', () async {
      final c = await candidates();
      await labels.setLocalityRomaji(c['KYC00123']!.locality.id, '  Shimooritate ');

      final after = await candidates();
      expect(after['KYC00123']!.locality.localityEn, 'Shimooritate');
      expect(after['KYC00124']!.locality.localityEn, 'Shimooritate');
      expect(after['KYC00125']!.missingLocalityRomaji, isTrue);

      final dict = await db.select(db.placeRomajiDict).getSingle();
      expect((dict.municipalityCode, dict.localityJa, dict.localityEn), ('15225', '下折立', 'Shimooritate'));

      final lines = buildDataLabel(after['KYC00124']!.toSource(ElevationRounding.tenMeters));
      expect(lines.map((l) => l.text).join(' '), contains('Shimooritate'));
    });

    test('入力済みのほかの地点の綴りは変えない', () async {
      final c = await candidates();
      await labels.setLocalityRomaji(c['KYC00124']!.locality.id, 'Shimo-oritate');
      await labels.setLocalityRomaji(c['KYC00123']!.locality.id, 'Shimooritate');

      final after = await candidates();
      expect(after['KYC00124']!.locality.localityEn, 'Shimo-oritate');
      expect(after['KYC00123']!.locality.localityEn, 'Shimooritate');
      // 辞書は最後に入れた綴り
      expect((await db.select(db.placeRomajiDict).getSingle()).localityEn, 'Shimooritate');
    });

    test('空のローマ字は受け付けない', () async {
      final c = await candidates();
      expect(() => labels.setLocalityRomaji(c['KYC00123']!.locality.id, ' '), throwsArgumentError);
    });
  });
}
