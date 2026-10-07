import '../../core/db/database.dart';
import '../../domain/models/calendar_date.dart';
import '../../domain/models/collection_period.dart';
import '../../domain/models/place_info.dart';
import '../../domain/sampling_method.dart';
import '../../domain/status.dart';
import '../../services/record_service.dart';

/// 記録画面(S-02)の入力内容。下書きでは、この内容を JSON で丸ごと保存する。
///
/// 位置と日時は、画面を開いた時点(下書きなら下書きにした時点)の値を持ち、再開しても変わらない。
class RecordForm {
  RecordForm({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.isManualPosition = false,
    this.existingLocalityId,
    this.elevationMeters,
    this.place,
    required this.startDate,
    required this.endDate,
    this.isPeriod = false,
    required this.recordedAt,
    this.samplingMethod = SamplingMethod.general,
    this.samplingMethodOther = '',
    this.lightSource = '',
    this.bait = '',
    this.habitat = '',
    this.hostPlant = '',
    this.count = 1,
    this.sex,
    this.remarks = '',
  });

  /// 現在地(または地図で指した位置)で、新しく記録する。
  factory RecordForm.at({
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    bool isManualPosition = false,
    int? existingLocalityId,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    final today = CalendarDate.fromDateTime(time);
    return RecordForm(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      isManualPosition: isManualPosition,
      existingLocalityId: existingLocalityId,
      startDate: today,
      endDate: today,
      recordedAt: time,
    );
  }

  /// 保存済みの採集をもとに、同じ地点へ追加する(標本詳細・地点詳細の「同地点で追加」)。
  /// 地点・日時・採集方法・環境をコピーし、標本の項目は空にする。
  factory RecordForm.fromEvent(CollectionEvent event, Locality locality, {DateTime? now}) => RecordForm(
    latitude: locality.latitude,
    longitude: locality.longitude,
    accuracyMeters: locality.accuracyMeters,
    isManualPosition: locality.isManualPosition,
    existingLocalityId: locality.id,
    startDate: event.startDate,
    endDate: event.endDate,
    isPeriod: event.startDate != event.endDate,
    recordedAt: now ?? DateTime.now(),
    samplingMethod: event.samplingMethod,
    samplingMethodOther: event.samplingMethodOther ?? '',
    lightSource: event.lightSource ?? '',
    bait: event.bait ?? '',
    habitat: event.habitat ?? '',
    hostPlant: event.hostPlant ?? '',
  );

  double latitude;
  double longitude;
  double? accuracyMeters;
  bool isManualPosition;

  /// 「この地点に追加」のとき、使う地点の ID。
  int? existingLocalityId;

  /// 記録画面で取得できた標高・地名。null なら取得待ち。
  double? elevationMeters;
  PlaceInfo? place;

  CalendarDate startDate;
  CalendarDate endDate;
  bool isPeriod;
  DateTime recordedAt;

  SamplingMethod samplingMethod;
  String samplingMethodOther;
  String lightSource;
  String bait;
  String habitat;
  String hostPlant;

  int count;
  Sex? sex;
  String remarks;

  /// 位置を手動で補正する(F-06)。精度は「手動」になり、標高と地名は取り直すので空にする。
  void correctPosition(double newLatitude, double newLongitude) {
    latitude = newLatitude;
    longitude = newLongitude;
    accuracyMeters = null;
    isManualPosition = true;
    elevationMeters = null;
    place = null;
  }

  CollectionPeriod get period => isPeriod
      ? CollectionPeriod(startDate, endDate)
      : CollectionPeriod.singleDay(startDate);

  /// 保存用の入力に変える。
  RecordInput toInput({int? draftId}) => RecordInput(
    position: existingLocalityId != null
        ? ExistingLocality(existingLocalityId!)
        : NewPosition(
            latitude: latitude,
            longitude: longitude,
            accuracyMeters: accuracyMeters,
            isManual: isManualPosition,
            elevationMeters: elevationMeters,
            place: place,
          ),
    period: period,
    recordedAt: recordedAt,
    samplingMethod: samplingMethod,
    samplingMethodOther: samplingMethodOther,
    lightSource: samplingMethod.hasLightSource ? lightSource : null,
    bait: samplingMethod.hasBait ? bait : null,
    habitat: habitat,
    hostPlant: hostPlant,
    count: count,
    sex: sex,
    remarks: remarks,
    draftId: draftId,
  );

  /// 「保存して同地点で追加」用。地点・日時・採集方法・環境をコピーし、標本の項目は空にする。
  RecordForm nextAtSameLocality(int localityId) => RecordForm(
    latitude: latitude,
    longitude: longitude,
    accuracyMeters: accuracyMeters,
    isManualPosition: isManualPosition,
    existingLocalityId: localityId,
    elevationMeters: elevationMeters,
    place: place,
    startDate: startDate,
    endDate: endDate,
    isPeriod: isPeriod,
    recordedAt: recordedAt,
    samplingMethod: samplingMethod,
    samplingMethodOther: samplingMethodOther,
    lightSource: lightSource,
    bait: bait,
    habitat: habitat,
    hostPlant: hostPlant,
  );

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMeters': accuracyMeters,
    'isManualPosition': isManualPosition,
    'existingLocalityId': existingLocalityId,
    'elevationMeters': elevationMeters,
    if (place case final p?)
      'place': {
        'municipalityCode': p.municipalityCode,
        'prefectureJa': p.prefectureJa,
        'countyJa': p.countyJa,
        'municipalityJa': p.municipalityJa,
        'localityJa': p.localityJa,
        'prefectureEn': p.prefectureEn,
        'countyEn': p.countyEn,
        'municipalityEn': p.municipalityEn,
        'localityEn': p.localityEn,
      },
    'startDate': startDate.toIso(),
    'endDate': endDate.toIso(),
    'isPeriod': isPeriod,
    'recordedAt': recordedAt.toIso8601String(),
    'samplingMethod': samplingMethod.name,
    'samplingMethodOther': samplingMethodOther,
    'lightSource': lightSource,
    'bait': bait,
    'habitat': habitat,
    'hostPlant': hostPlant,
    'count': count,
    'sex': sex?.name,
    'remarks': remarks,
  };

  factory RecordForm.fromJson(Map<String, Object?> json) {
    final p = json['place'] as Map<String, Object?>?;
    return RecordForm(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
      isManualPosition: json['isManualPosition'] as bool? ?? false,
      existingLocalityId: json['existingLocalityId'] as int?,
      elevationMeters: (json['elevationMeters'] as num?)?.toDouble(),
      place: p == null
          ? null
          : PlaceInfo(
              municipalityCode: p['municipalityCode'] as String?,
              prefectureJa: p['prefectureJa'] as String?,
              countyJa: p['countyJa'] as String?,
              municipalityJa: p['municipalityJa'] as String?,
              localityJa: p['localityJa'] as String?,
              prefectureEn: p['prefectureEn'] as String?,
              countyEn: p['countyEn'] as String?,
              municipalityEn: p['municipalityEn'] as String?,
              localityEn: p['localityEn'] as String?,
            ),
      startDate: CalendarDate.parse(json['startDate'] as String),
      endDate: CalendarDate.parse(json['endDate'] as String),
      isPeriod: json['isPeriod'] as bool? ?? false,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      samplingMethod: SamplingMethod.values.byName(json['samplingMethod'] as String),
      // ↑ byName は enum を名前から引く(Java の Enum.valueOf)
      samplingMethodOther: json['samplingMethodOther'] as String? ?? '',
      lightSource: json['lightSource'] as String? ?? '',
      bait: json['bait'] as String? ?? '',
      habitat: json['habitat'] as String? ?? '',
      hostPlant: json['hostPlant'] as String? ?? '',
      count: json['count'] as int? ?? 1,
      sex: switch (json['sex']) {
        final String name => Sex.values.byName(name),
        _ => null,
      },
      remarks: json['remarks'] as String? ?? '',
    );
  }
}
