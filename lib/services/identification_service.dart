import 'package:drift/drift.dart';

import '../core/db/database.dart';
import '../domain/models/calendar_date.dart';
import '../domain/species_name.dart';
import '../domain/status.dart';
import 'dictionary_service.dart';

/// 同定の追加(要件定義 S-06・F-11)。上書きせず、履歴に積む。
class IdentificationService {
  IdentificationService(this._db, this._dictionary);

  final AppDatabase _db;
  final DictionaryService _dictionary;

  /// 種名を入力して保存したときの状態(半自動)。
  /// 種名が空なら未同定。入力があれば、確定していない限り仮同定。
  static IdentificationStatus statusFor(SpeciesName name, {bool confirmed = false}) {
    if (name.isEmpty) return IdentificationStatus.unidentified;
    return confirmed ? IdentificationStatus.verified : IdentificationStatus.provisional;
  }

  /// 選んだ標本すべてに、同じ同定を追加する。
  ///
  /// 同定者は、入力があれば設定に覚えて次回の既定にする。種名は辞書に溜める。
  /// 状態は [status] で渡す(画面は [statusFor] の結果を初期値にする)。種名が空なら、
  /// 渡された状態によらず未同定にする。
  Future<void> add(
    Iterable<int> specimenIds, {
    required SpeciesName name,
    String? identifiedBy,
    CalendarDate? dateIdentified,
    required IdentificationStatus status,
  }) {
    final ids = specimenIds.toSet();
    if (ids.isEmpty) throw ArgumentError('標本を選んでください');
    final by = identifiedBy?.trim();
    final byValue = by == null || by.isEmpty ? null : by;
    final effective = name.isEmpty ? IdentificationStatus.unidentified : status;

    return _db.transaction(() async {
      for (final id in ids) {
        await _db.into(_db.identifications).insert(
          IdentificationsCompanion.insert(
            specimenId: id,
            status: effective,
            vernacularName: Value(name.vernacular),
            genus: Value(name.genus),
            species: Value(name.species),
            subspecies: Value(name.subspecies),
            authorship: Value(name.authorship),
            identifiedBy: Value(byValue),
            dateIdentified: Value(dateIdentified),
          ),
        );
      }
      if (byValue != null) {
        await _db.update(_db.appSettings).write(AppSettingsCompanion(lastIdentifier: Value(byValue)));
      }
      await _dictionary.rememberSpecies(name);
    });
  }
}
