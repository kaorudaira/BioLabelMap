import 'dart:convert';

import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/models/place_info.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/services/backup_service.dart';
import 'package:biolabelmap/services/draft_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BackupService backup;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    backup = BackupService(db);
  });

  tearDown(() => db.close());

  /// 地点2つ・採集2つ・標本4件(うち1件はごみ箱)・同定・下書き・辞書を入れる。
  Future<void> seed(AppDatabase target) async {
    final settings = SettingsService(target);
    final records = RecordService(target);
    await settings.setCollectorName('Kaoru Yoshihara');
    await settings.initializeCatalog(122);
    final first = await records.save(
      RecordInput(
        position: const NewPosition(
          latitude: 36.94471,
          longitude: 139.24258,
          accuracyMeters: 8,
          elevationMeters: 1391.4,
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
        recordedAt: DateTime(2026, 6, 20, 10, 30),
        samplingMethod: SamplingMethod.sweeping,
        habitat: 'ブナ林',
        count: 3,
      ),
    );
    await records.save(
      RecordInput(
        position: const NewPosition(latitude: 36.8834, longitude: 138.8205, accuracyMeters: 40),
        period: CollectionPeriod(CalendarDate(2026, 6, 19), CalendarDate(2026, 7, 2)),
        recordedAt: DateTime(2026, 7, 2, 18),
        samplingMethod: SamplingMethod.lightTrap,
        lightSource: 'UV LED',
      ),
    );
    await target.into(target.identifications).insert(
      IdentificationsCompanion.insert(
        specimenId: first.specimenIds.first,
        vernacularName: const Value('スゲハムシ'),
        genus: const Value('Plateumaris'),
        species: const Value('sericea'),
        authorship: const Value('(Linnaeus 1761)'),
        status: IdentificationStatus.provisional,
      ),
    );
    await (target.update(target.specimens)..where((s) => s.id.equals(first.specimenIds.last)))
        .write(SpecimensCompanion(deletedAt: Value(DateTime(2026, 7, 3))));
    await DraftService(target).save({'habitat': '草地'});
  }

  Future<Map<String, List<Map<String, Object?>>>> dump(AppDatabase target) async => {
    for (final t in target.allTables)
      t.actualTableName: [
        for (final r in await target.customSelect('SELECT * FROM "${t.actualTableName}" ORDER BY rowid').get())
          r.data,
      ],
  };

  test('全テーブルを書き出し、ファイル名に日付を付ける', () async {
    await seed(db);
    final file = await backup.export(now: DateTime(2026, 10, 4, 9));

    expect(file.fileName, 'konchu-backup-20261004.json');
    final json = jsonDecode(utf8.decode(file.bytes)) as Map<String, Object?>;
    expect(json['format'], backupFormatName);
    expect(json['schemaVersion'], db.schemaVersion);
    final tables = json['tables']! as Map<String, Object?>;
    expect(tables.keys, containsAll([for (final t in db.allTables) t.actualTableName]));
    expect((tables['specimens']! as List).length, 4);
    expect((tables['place_romaji_dict']! as List).length, 1);
  });

  test('概要はごみ箱を除いた標本数と、採集日の範囲', () async {
    await seed(db);
    final file = await backup.export();
    expect(file.summary.specimenCount, 3);
    expect(file.summary.firstDate, '2026-06-19');
    expect(file.summary.lastDate, '2026-07-02');

    final read = backup.inspect(file.bytes);
    expect(read.specimenCount, 3);
    expect(read.lastDate, '2026-07-02');
  });

  test('標本が無くても書き出せる', () async {
    final file = await backup.export();
    expect(file.summary.specimenCount, 0);
    expect(file.summary.firstDate, isNull);
  });

  test('書き出したファイルで、別の端末に全データを元どおり復元できる', () async {
    await seed(db);
    await SettingsService(db).markBackedUp(DateTime(2026, 10, 1));
    final file = await backup.export();

    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    // 復元先にあったデータは消える(置き換え)
    await SettingsService(other).initializeCatalog(5000);
    await DraftService(other).save({'habitat': '消える下書き'});

    await BackupService(other).restore(file.bytes);
    expect(await dump(other), await dump(db));

    // 復元後も番号は続きから発行され、外部キーも保たれている
    final next = await RecordService(other).save(
      RecordInput(
        position: const ExistingLocality(1),
        period: CollectionPeriod.singleDay(CalendarDate(2026, 8, 1)),
        recordedAt: DateTime(2026, 8, 1),
        samplingMethod: SamplingMethod.looking,
      ),
    );
    expect(next.catalogRange, 'KYC00127');
  });

  test('バックアップでないファイルは読み込まない', () async {
    final notJson = Uint8List.fromList(utf8.encode('label,pdf'));
    final otherJson = Uint8List.fromList(utf8.encode('{"format":"something"}'));
    expect(() => backup.inspect(notJson), throwsA(isA<InvalidBackupException>()));
    expect(() => backup.restore(otherJson), throwsA(isA<InvalidBackupException>()));
  });

  test('新しい版のアプリで作ったバックアップは読み込まない', () async {
    final file = await backup.export();
    final json = jsonDecode(utf8.decode(file.bytes)) as Map<String, Object?>;
    json['schemaVersion'] = db.schemaVersion + 1;
    final newer = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    expect(() => backup.restore(newer), throwsA(isA<InvalidBackupException>()));
  });
}
