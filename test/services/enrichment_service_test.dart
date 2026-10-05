import 'dart:convert';

import 'package:biolabelmap/core/db/database.dart';
import 'package:biolabelmap/core/gsi/gsi_api.dart';
import 'package:biolabelmap/core/gsi/municipality_directory.dart';
import 'package:biolabelmap/domain/models/calendar_date.dart';
import 'package:biolabelmap/domain/models/collection_period.dart';
import 'package:biolabelmap/domain/sampling_method.dart';
import 'package:biolabelmap/domain/status.dart';
import 'package:biolabelmap/services/enrichment_service.dart';
import 'package:biolabelmap/services/record_service.dart';
import 'package:biolabelmap/services/settings_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late AppDatabase db;
  late DateTime now;

  /// 通信の振る舞いをテストごとに切り替える。
  late Future<http.Response> Function(http.Request) server;

  final directory = JsonMunicipalityDirectory.parse(jsonEncode({
    '15225': {
      'prefJa': '新潟県',
      'muniJa': '魚沼市',
      'prefEn': 'Niigata-ken',
      'muniEn': 'Uonuma-shi',
    },
  }));

  EnrichmentService service() => EnrichmentService(
    db,
    GsiApi(MockClient((request) => server(request))),
    directory,
    clock: () => now,
  );

  http.Response json(Object body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: {'content-type': 'application/json'},
  );

  /// 地理院の正常な応答。
  Future<http.Response> gsiOk(http.Request request) async {
    if (request.url.host.startsWith('cyberjapandata2')) {
      return json({'elevation': 1388.4, 'hsrc': '5m（レーザ）'});
    }
    return json({
      'results': {'muniCd': '15225', 'lv01Nm': '下折立'},
    });
  }

  Future<http.Response> offline(http.Request request) async =>
      throw http.ClientException('Failed host lookup');

  Future<int> recordAt(double lat, double lon) async {
    final result = await RecordService(db).save(RecordInput(
      position: NewPosition(latitude: lat, longitude: lon),
      period: CollectionPeriod.singleDay(CalendarDate(2026, 6, 20)),
      recordedAt: DateTime(2026, 6, 20),
      samplingMethod: SamplingMethod.general,
    ));
    return result.localityId;
  }

  Future<Locality> locality(int id) =>
      (db.select(db.localities)..where((l) => l.id.equals(id))).getSingle();

  Future<List<EnrichmentTask>> queue() => db.select(db.enrichmentQueue).get();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 6, 21, 9);
    server = gsiOk;
    await SettingsService(db).initializeCatalog(0);
  });

  tearDown(() => db.close());

  test('通信できれば標高と地名を補完し、キューから消す', () async {
    final id = await recordAt(36.9447, 139.2426);

    final summary = await service().run(triggered: true);

    expect(summary.fetched, 2);
    final l = await locality(id);
    expect(l.elevationMeters, 1388.4);
    expect(l.elevationStatus, FetchStatus.fetched);
    expect(l.municipalityCode, '15225');
    expect(l.municipalityJa, '魚沼市');
    expect(l.municipalityEn, 'Uonuma-shi');
    expect(l.prefectureEn, 'Niigata-ken');
    expect(l.localityJa, '下折立');
    expect(l.placeStatus, FetchStatus.fetched);
    expect(await queue(), isEmpty);
  });

  test('大字のローマ字が辞書にあれば補う', () async {
    await db.into(db.placeRomajiDict).insert(PlaceRomajiDictCompanion.insert(
      municipalityCode: '15225',
      localityJa: '下折立',
      localityEn: 'Shimooritate',
    ));
    final id = await recordAt(36.9447, 139.2426);

    await service().run(triggered: true);

    expect((await locality(id)).localityEn, 'Shimooritate');
  });

  test('データが無い地点(海上など)は「取得不可」にして、キューから消す', () async {
    server = (request) async => request.url.host.startsWith('cyberjapandata2')
        ? json({'elevation': '-----', 'hsrc': '-----'})
        : json({});
    final id = await recordAt(35.0, 140.5);

    final summary = await service().run(triggered: true);

    expect(summary.unavailable, 2);
    final l = await locality(id);
    expect(l.elevationStatus, FetchStatus.unavailable);
    expect(l.placeStatus, FetchStatus.unavailable);
    expect(await queue(), isEmpty);
  });

  test('補完待ちの地点の数を数える', () async {
    final s = service();
    await recordAt(36.9447, 139.2426);
    await recordAt(36.9500, 139.2500);
    expect(await s.watchPendingLocalityCount().first, 2);

    await s.run(triggered: true);
    expect(await s.watchPendingLocalityCount().first, 0);
  });

  group('通信エラーの再試行(1分後、5分後、30分後)', () {
    test('失敗したら、キューに残して1分後に予約する', () async {
      server = offline;
      final id = await recordAt(36.9447, 139.2426);
      final s = service();

      final summary = await s.run(triggered: true);

      expect(summary.failed, 2);
      expect((await locality(id)).elevationStatus, FetchStatus.pending);
      final tasks = await queue();
      expect(tasks.map((t) => t.attempts), [1, 1]);
      expect(await s.nextScheduledAttempt(), now.add(const Duration(minutes: 1)));
    });

    test('予約時刻の前は、自動の実行では何もしない', () async {
      server = offline;
      await recordAt(36.9447, 139.2426);
      final s = service();
      await s.run(triggered: true);

      now = now.add(const Duration(seconds: 30));
      server = gsiOk;
      final summary = await s.run(triggered: false);

      expect(summary.fetched, 0);
      expect(await queue(), hasLength(2));
    });

    test('3回再試行したら予約をやめ、次のきっかけを待つ', () async {
      server = offline;
      await recordAt(36.9447, 139.2426);
      final s = service();
      final start = now;

      await s.run(triggered: true); // 失敗1 → 1分後
      now = now.add(const Duration(minutes: 1));
      await s.run(triggered: false); // 失敗2 → 5分後
      expect(await s.nextScheduledAttempt(), now.add(const Duration(minutes: 5)));

      now = now.add(const Duration(minutes: 5));
      await s.run(triggered: false); // 失敗3 → 30分後
      expect(await s.nextScheduledAttempt(), now.add(const Duration(minutes: 30)));

      now = now.add(const Duration(minutes: 30));
      await s.run(triggered: false); // 失敗4 → 予約なし
      expect(await s.nextScheduledAttempt(), isNull);
      expect((await queue()).map((t) => t.attempts), [4, 4]);
      expect(now.difference(start), const Duration(minutes: 36));

      // 次のきっかけ(アプリを開いた等)で、通信が戻っていれば補完できる
      server = gsiOk;
      final summary = await s.run(triggered: true);
      expect(summary.fetched, 2);
      expect(await queue(), isEmpty);
    });

    test('きっかけによる実行は、回数を数え直す', () async {
      server = offline;
      await recordAt(36.9447, 139.2426);
      final s = service();
      await s.run(triggered: true);
      now = now.add(const Duration(minutes: 1));
      await s.run(triggered: false);
      expect((await queue()).map((t) => t.attempts), [2, 2]);

      await s.run(triggered: true);
      expect((await queue()).map((t) => t.attempts), [1, 1]);
    });
  });

  test('手入力した標高は、補完で上書きしない', () async {
    final id = await recordAt(36.9447, 139.2426);
    await (db.update(db.localities)..where((l) => l.id.equals(id))).write(
      const LocalitiesCompanion(
        elevationMeters: Value(1400),
        elevationStatus: Value(FetchStatus.manual),
      ),
    );

    await service().run(triggered: true);

    final l = await locality(id);
    expect(l.elevationMeters, 1400);
    expect(l.elevationStatus, FetchStatus.manual);
    expect(await queue(), isEmpty);
  });

  test('実行中に重ねて呼んでも、二重に取得しない', () async {
    var calls = 0;
    server = (request) {
      calls++;
      return gsiOk(request);
    };
    await recordAt(36.9447, 139.2426);
    final s = service();

    await Future.wait([s.run(triggered: true), s.run(triggered: true)]);

    expect(calls, 2); // 標高と地名で1回ずつ
  });
}
