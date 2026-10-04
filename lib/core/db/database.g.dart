// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LocalitiesTable extends Localities
    with TableInfo<$LocalitiesTable, Locality> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latE4Meta = const VerificationMeta('latE4');
  @override
  late final GeneratedColumn<int> latE4 = GeneratedColumn<int>(
    'lat_e4',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonE4Meta = const VerificationMeta('lonE4');
  @override
  late final GeneratedColumn<int> lonE4 = GeneratedColumn<int>(
    'lon_e4',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMetersMeta = const VerificationMeta(
    'accuracyMeters',
  );
  @override
  late final GeneratedColumn<double> accuracyMeters = GeneratedColumn<double>(
    'accuracy_meters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isManualPositionMeta = const VerificationMeta(
    'isManualPosition',
  );
  @override
  late final GeneratedColumn<bool> isManualPosition = GeneratedColumn<bool>(
    'is_manual_position',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_manual_position" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _elevationMetersMeta = const VerificationMeta(
    'elevationMeters',
  );
  @override
  late final GeneratedColumn<double> elevationMeters = GeneratedColumn<double>(
    'elevation_meters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FetchStatus, String>
  elevationStatus = GeneratedColumn<String>(
    'elevation_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<FetchStatus>($LocalitiesTable.$converterelevationStatus);
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('JAPAN'),
  );
  static const VerificationMeta _municipalityCodeMeta = const VerificationMeta(
    'municipalityCode',
  );
  @override
  late final GeneratedColumn<String> municipalityCode = GeneratedColumn<String>(
    'municipality_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prefectureJaMeta = const VerificationMeta(
    'prefectureJa',
  );
  @override
  late final GeneratedColumn<String> prefectureJa = GeneratedColumn<String>(
    'prefecture_ja',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countyJaMeta = const VerificationMeta(
    'countyJa',
  );
  @override
  late final GeneratedColumn<String> countyJa = GeneratedColumn<String>(
    'county_ja',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _municipalityJaMeta = const VerificationMeta(
    'municipalityJa',
  );
  @override
  late final GeneratedColumn<String> municipalityJa = GeneratedColumn<String>(
    'municipality_ja',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localityJaMeta = const VerificationMeta(
    'localityJa',
  );
  @override
  late final GeneratedColumn<String> localityJa = GeneratedColumn<String>(
    'locality_ja',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prefectureEnMeta = const VerificationMeta(
    'prefectureEn',
  );
  @override
  late final GeneratedColumn<String> prefectureEn = GeneratedColumn<String>(
    'prefecture_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countyEnMeta = const VerificationMeta(
    'countyEn',
  );
  @override
  late final GeneratedColumn<String> countyEn = GeneratedColumn<String>(
    'county_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _municipalityEnMeta = const VerificationMeta(
    'municipalityEn',
  );
  @override
  late final GeneratedColumn<String> municipalityEn = GeneratedColumn<String>(
    'municipality_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localityEnMeta = const VerificationMeta(
    'localityEn',
  );
  @override
  late final GeneratedColumn<String> localityEn = GeneratedColumn<String>(
    'locality_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FetchStatus, String> placeStatus =
      GeneratedColumn<String>(
        'place_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FetchStatus>($LocalitiesTable.$converterplaceStatus);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    latitude,
    longitude,
    latE4,
    lonE4,
    accuracyMeters,
    isManualPosition,
    elevationMeters,
    elevationStatus,
    country,
    municipalityCode,
    prefectureJa,
    countyJa,
    municipalityJa,
    localityJa,
    prefectureEn,
    countyEn,
    municipalityEn,
    localityEn,
    placeStatus,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'localities';
  @override
  VerificationContext validateIntegrity(
    Insertable<Locality> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('lat_e4')) {
      context.handle(
        _latE4Meta,
        latE4.isAcceptableOrUnknown(data['lat_e4']!, _latE4Meta),
      );
    } else if (isInserting) {
      context.missing(_latE4Meta);
    }
    if (data.containsKey('lon_e4')) {
      context.handle(
        _lonE4Meta,
        lonE4.isAcceptableOrUnknown(data['lon_e4']!, _lonE4Meta),
      );
    } else if (isInserting) {
      context.missing(_lonE4Meta);
    }
    if (data.containsKey('accuracy_meters')) {
      context.handle(
        _accuracyMetersMeta,
        accuracyMeters.isAcceptableOrUnknown(
          data['accuracy_meters']!,
          _accuracyMetersMeta,
        ),
      );
    }
    if (data.containsKey('is_manual_position')) {
      context.handle(
        _isManualPositionMeta,
        isManualPosition.isAcceptableOrUnknown(
          data['is_manual_position']!,
          _isManualPositionMeta,
        ),
      );
    }
    if (data.containsKey('elevation_meters')) {
      context.handle(
        _elevationMetersMeta,
        elevationMeters.isAcceptableOrUnknown(
          data['elevation_meters']!,
          _elevationMetersMeta,
        ),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('municipality_code')) {
      context.handle(
        _municipalityCodeMeta,
        municipalityCode.isAcceptableOrUnknown(
          data['municipality_code']!,
          _municipalityCodeMeta,
        ),
      );
    }
    if (data.containsKey('prefecture_ja')) {
      context.handle(
        _prefectureJaMeta,
        prefectureJa.isAcceptableOrUnknown(
          data['prefecture_ja']!,
          _prefectureJaMeta,
        ),
      );
    }
    if (data.containsKey('county_ja')) {
      context.handle(
        _countyJaMeta,
        countyJa.isAcceptableOrUnknown(data['county_ja']!, _countyJaMeta),
      );
    }
    if (data.containsKey('municipality_ja')) {
      context.handle(
        _municipalityJaMeta,
        municipalityJa.isAcceptableOrUnknown(
          data['municipality_ja']!,
          _municipalityJaMeta,
        ),
      );
    }
    if (data.containsKey('locality_ja')) {
      context.handle(
        _localityJaMeta,
        localityJa.isAcceptableOrUnknown(data['locality_ja']!, _localityJaMeta),
      );
    }
    if (data.containsKey('prefecture_en')) {
      context.handle(
        _prefectureEnMeta,
        prefectureEn.isAcceptableOrUnknown(
          data['prefecture_en']!,
          _prefectureEnMeta,
        ),
      );
    }
    if (data.containsKey('county_en')) {
      context.handle(
        _countyEnMeta,
        countyEn.isAcceptableOrUnknown(data['county_en']!, _countyEnMeta),
      );
    }
    if (data.containsKey('municipality_en')) {
      context.handle(
        _municipalityEnMeta,
        municipalityEn.isAcceptableOrUnknown(
          data['municipality_en']!,
          _municipalityEnMeta,
        ),
      );
    }
    if (data.containsKey('locality_en')) {
      context.handle(
        _localityEnMeta,
        localityEn.isAcceptableOrUnknown(data['locality_en']!, _localityEnMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Locality map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Locality(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      latE4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lat_e4'],
      )!,
      lonE4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lon_e4'],
      )!,
      accuracyMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_meters'],
      ),
      isManualPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_manual_position'],
      )!,
      elevationMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation_meters'],
      ),
      elevationStatus: $LocalitiesTable.$converterelevationStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}elevation_status'],
        )!,
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      )!,
      municipalityCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_code'],
      ),
      prefectureJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prefecture_ja'],
      ),
      countyJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}county_ja'],
      ),
      municipalityJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_ja'],
      ),
      localityJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locality_ja'],
      ),
      prefectureEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prefecture_en'],
      ),
      countyEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}county_en'],
      ),
      municipalityEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_en'],
      ),
      localityEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locality_en'],
      ),
      placeStatus: $LocalitiesTable.$converterplaceStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}place_status'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalitiesTable createAlias(String alias) {
    return $LocalitiesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FetchStatus, String, String>
  $converterelevationStatus = const EnumNameConverter<FetchStatus>(
    FetchStatus.values,
  );
  static JsonTypeConverter2<FetchStatus, String, String> $converterplaceStatus =
      const EnumNameConverter<FetchStatus>(FetchStatus.values);
}

class Locality extends DataClass implements Insertable<Locality> {
  final int id;
  final double latitude;
  final double longitude;

  /// 同一地点の判定キー(LocalityKey)。
  final int latE4;
  final int lonE4;

  /// GPS の精度(m)。手動で補正したときは null。
  final double? accuracyMeters;
  final bool isManualPosition;

  /// 標高(m)。丸める前の値を持ち、ラベル出力時に丸める。
  final double? elevationMeters;
  final FetchStatus elevationStatus;
  final String country;

  /// 自治体コード(逆ジオコーダの muniCd)。県・市町村の英語名の変換に使う。
  final String? municipalityCode;
  final String? prefectureJa;

  /// 郡(町村のみ)。
  final String? countyJa;
  final String? municipalityJa;

  /// 大字(逆ジオコーダの lv01Nm)。
  final String? localityJa;
  final String? prefectureEn;
  final String? countyEn;
  final String? municipalityEn;

  /// 大字のローマ字。手入力し、辞書で補完する。
  final String? localityEn;
  final FetchStatus placeStatus;
  final DateTime createdAt;
  const Locality({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.latE4,
    required this.lonE4,
    this.accuracyMeters,
    required this.isManualPosition,
    this.elevationMeters,
    required this.elevationStatus,
    required this.country,
    this.municipalityCode,
    this.prefectureJa,
    this.countyJa,
    this.municipalityJa,
    this.localityJa,
    this.prefectureEn,
    this.countyEn,
    this.municipalityEn,
    this.localityEn,
    required this.placeStatus,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['lat_e4'] = Variable<int>(latE4);
    map['lon_e4'] = Variable<int>(lonE4);
    if (!nullToAbsent || accuracyMeters != null) {
      map['accuracy_meters'] = Variable<double>(accuracyMeters);
    }
    map['is_manual_position'] = Variable<bool>(isManualPosition);
    if (!nullToAbsent || elevationMeters != null) {
      map['elevation_meters'] = Variable<double>(elevationMeters);
    }
    {
      map['elevation_status'] = Variable<String>(
        $LocalitiesTable.$converterelevationStatus.toSql(elevationStatus),
      );
    }
    map['country'] = Variable<String>(country);
    if (!nullToAbsent || municipalityCode != null) {
      map['municipality_code'] = Variable<String>(municipalityCode);
    }
    if (!nullToAbsent || prefectureJa != null) {
      map['prefecture_ja'] = Variable<String>(prefectureJa);
    }
    if (!nullToAbsent || countyJa != null) {
      map['county_ja'] = Variable<String>(countyJa);
    }
    if (!nullToAbsent || municipalityJa != null) {
      map['municipality_ja'] = Variable<String>(municipalityJa);
    }
    if (!nullToAbsent || localityJa != null) {
      map['locality_ja'] = Variable<String>(localityJa);
    }
    if (!nullToAbsent || prefectureEn != null) {
      map['prefecture_en'] = Variable<String>(prefectureEn);
    }
    if (!nullToAbsent || countyEn != null) {
      map['county_en'] = Variable<String>(countyEn);
    }
    if (!nullToAbsent || municipalityEn != null) {
      map['municipality_en'] = Variable<String>(municipalityEn);
    }
    if (!nullToAbsent || localityEn != null) {
      map['locality_en'] = Variable<String>(localityEn);
    }
    {
      map['place_status'] = Variable<String>(
        $LocalitiesTable.$converterplaceStatus.toSql(placeStatus),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalitiesCompanion toCompanion(bool nullToAbsent) {
    return LocalitiesCompanion(
      id: Value(id),
      latitude: Value(latitude),
      longitude: Value(longitude),
      latE4: Value(latE4),
      lonE4: Value(lonE4),
      accuracyMeters: accuracyMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyMeters),
      isManualPosition: Value(isManualPosition),
      elevationMeters: elevationMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(elevationMeters),
      elevationStatus: Value(elevationStatus),
      country: Value(country),
      municipalityCode: municipalityCode == null && nullToAbsent
          ? const Value.absent()
          : Value(municipalityCode),
      prefectureJa: prefectureJa == null && nullToAbsent
          ? const Value.absent()
          : Value(prefectureJa),
      countyJa: countyJa == null && nullToAbsent
          ? const Value.absent()
          : Value(countyJa),
      municipalityJa: municipalityJa == null && nullToAbsent
          ? const Value.absent()
          : Value(municipalityJa),
      localityJa: localityJa == null && nullToAbsent
          ? const Value.absent()
          : Value(localityJa),
      prefectureEn: prefectureEn == null && nullToAbsent
          ? const Value.absent()
          : Value(prefectureEn),
      countyEn: countyEn == null && nullToAbsent
          ? const Value.absent()
          : Value(countyEn),
      municipalityEn: municipalityEn == null && nullToAbsent
          ? const Value.absent()
          : Value(municipalityEn),
      localityEn: localityEn == null && nullToAbsent
          ? const Value.absent()
          : Value(localityEn),
      placeStatus: Value(placeStatus),
      createdAt: Value(createdAt),
    );
  }

  factory Locality.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Locality(
      id: serializer.fromJson<int>(json['id']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      latE4: serializer.fromJson<int>(json['latE4']),
      lonE4: serializer.fromJson<int>(json['lonE4']),
      accuracyMeters: serializer.fromJson<double?>(json['accuracyMeters']),
      isManualPosition: serializer.fromJson<bool>(json['isManualPosition']),
      elevationMeters: serializer.fromJson<double?>(json['elevationMeters']),
      elevationStatus: $LocalitiesTable.$converterelevationStatus.fromJson(
        serializer.fromJson<String>(json['elevationStatus']),
      ),
      country: serializer.fromJson<String>(json['country']),
      municipalityCode: serializer.fromJson<String?>(json['municipalityCode']),
      prefectureJa: serializer.fromJson<String?>(json['prefectureJa']),
      countyJa: serializer.fromJson<String?>(json['countyJa']),
      municipalityJa: serializer.fromJson<String?>(json['municipalityJa']),
      localityJa: serializer.fromJson<String?>(json['localityJa']),
      prefectureEn: serializer.fromJson<String?>(json['prefectureEn']),
      countyEn: serializer.fromJson<String?>(json['countyEn']),
      municipalityEn: serializer.fromJson<String?>(json['municipalityEn']),
      localityEn: serializer.fromJson<String?>(json['localityEn']),
      placeStatus: $LocalitiesTable.$converterplaceStatus.fromJson(
        serializer.fromJson<String>(json['placeStatus']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'latE4': serializer.toJson<int>(latE4),
      'lonE4': serializer.toJson<int>(lonE4),
      'accuracyMeters': serializer.toJson<double?>(accuracyMeters),
      'isManualPosition': serializer.toJson<bool>(isManualPosition),
      'elevationMeters': serializer.toJson<double?>(elevationMeters),
      'elevationStatus': serializer.toJson<String>(
        $LocalitiesTable.$converterelevationStatus.toJson(elevationStatus),
      ),
      'country': serializer.toJson<String>(country),
      'municipalityCode': serializer.toJson<String?>(municipalityCode),
      'prefectureJa': serializer.toJson<String?>(prefectureJa),
      'countyJa': serializer.toJson<String?>(countyJa),
      'municipalityJa': serializer.toJson<String?>(municipalityJa),
      'localityJa': serializer.toJson<String?>(localityJa),
      'prefectureEn': serializer.toJson<String?>(prefectureEn),
      'countyEn': serializer.toJson<String?>(countyEn),
      'municipalityEn': serializer.toJson<String?>(municipalityEn),
      'localityEn': serializer.toJson<String?>(localityEn),
      'placeStatus': serializer.toJson<String>(
        $LocalitiesTable.$converterplaceStatus.toJson(placeStatus),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Locality copyWith({
    int? id,
    double? latitude,
    double? longitude,
    int? latE4,
    int? lonE4,
    Value<double?> accuracyMeters = const Value.absent(),
    bool? isManualPosition,
    Value<double?> elevationMeters = const Value.absent(),
    FetchStatus? elevationStatus,
    String? country,
    Value<String?> municipalityCode = const Value.absent(),
    Value<String?> prefectureJa = const Value.absent(),
    Value<String?> countyJa = const Value.absent(),
    Value<String?> municipalityJa = const Value.absent(),
    Value<String?> localityJa = const Value.absent(),
    Value<String?> prefectureEn = const Value.absent(),
    Value<String?> countyEn = const Value.absent(),
    Value<String?> municipalityEn = const Value.absent(),
    Value<String?> localityEn = const Value.absent(),
    FetchStatus? placeStatus,
    DateTime? createdAt,
  }) => Locality(
    id: id ?? this.id,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    latE4: latE4 ?? this.latE4,
    lonE4: lonE4 ?? this.lonE4,
    accuracyMeters: accuracyMeters.present
        ? accuracyMeters.value
        : this.accuracyMeters,
    isManualPosition: isManualPosition ?? this.isManualPosition,
    elevationMeters: elevationMeters.present
        ? elevationMeters.value
        : this.elevationMeters,
    elevationStatus: elevationStatus ?? this.elevationStatus,
    country: country ?? this.country,
    municipalityCode: municipalityCode.present
        ? municipalityCode.value
        : this.municipalityCode,
    prefectureJa: prefectureJa.present ? prefectureJa.value : this.prefectureJa,
    countyJa: countyJa.present ? countyJa.value : this.countyJa,
    municipalityJa: municipalityJa.present
        ? municipalityJa.value
        : this.municipalityJa,
    localityJa: localityJa.present ? localityJa.value : this.localityJa,
    prefectureEn: prefectureEn.present ? prefectureEn.value : this.prefectureEn,
    countyEn: countyEn.present ? countyEn.value : this.countyEn,
    municipalityEn: municipalityEn.present
        ? municipalityEn.value
        : this.municipalityEn,
    localityEn: localityEn.present ? localityEn.value : this.localityEn,
    placeStatus: placeStatus ?? this.placeStatus,
    createdAt: createdAt ?? this.createdAt,
  );
  Locality copyWithCompanion(LocalitiesCompanion data) {
    return Locality(
      id: data.id.present ? data.id.value : this.id,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      latE4: data.latE4.present ? data.latE4.value : this.latE4,
      lonE4: data.lonE4.present ? data.lonE4.value : this.lonE4,
      accuracyMeters: data.accuracyMeters.present
          ? data.accuracyMeters.value
          : this.accuracyMeters,
      isManualPosition: data.isManualPosition.present
          ? data.isManualPosition.value
          : this.isManualPosition,
      elevationMeters: data.elevationMeters.present
          ? data.elevationMeters.value
          : this.elevationMeters,
      elevationStatus: data.elevationStatus.present
          ? data.elevationStatus.value
          : this.elevationStatus,
      country: data.country.present ? data.country.value : this.country,
      municipalityCode: data.municipalityCode.present
          ? data.municipalityCode.value
          : this.municipalityCode,
      prefectureJa: data.prefectureJa.present
          ? data.prefectureJa.value
          : this.prefectureJa,
      countyJa: data.countyJa.present ? data.countyJa.value : this.countyJa,
      municipalityJa: data.municipalityJa.present
          ? data.municipalityJa.value
          : this.municipalityJa,
      localityJa: data.localityJa.present
          ? data.localityJa.value
          : this.localityJa,
      prefectureEn: data.prefectureEn.present
          ? data.prefectureEn.value
          : this.prefectureEn,
      countyEn: data.countyEn.present ? data.countyEn.value : this.countyEn,
      municipalityEn: data.municipalityEn.present
          ? data.municipalityEn.value
          : this.municipalityEn,
      localityEn: data.localityEn.present
          ? data.localityEn.value
          : this.localityEn,
      placeStatus: data.placeStatus.present
          ? data.placeStatus.value
          : this.placeStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Locality(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('latE4: $latE4, ')
          ..write('lonE4: $lonE4, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('isManualPosition: $isManualPosition, ')
          ..write('elevationMeters: $elevationMeters, ')
          ..write('elevationStatus: $elevationStatus, ')
          ..write('country: $country, ')
          ..write('municipalityCode: $municipalityCode, ')
          ..write('prefectureJa: $prefectureJa, ')
          ..write('countyJa: $countyJa, ')
          ..write('municipalityJa: $municipalityJa, ')
          ..write('localityJa: $localityJa, ')
          ..write('prefectureEn: $prefectureEn, ')
          ..write('countyEn: $countyEn, ')
          ..write('municipalityEn: $municipalityEn, ')
          ..write('localityEn: $localityEn, ')
          ..write('placeStatus: $placeStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    latitude,
    longitude,
    latE4,
    lonE4,
    accuracyMeters,
    isManualPosition,
    elevationMeters,
    elevationStatus,
    country,
    municipalityCode,
    prefectureJa,
    countyJa,
    municipalityJa,
    localityJa,
    prefectureEn,
    countyEn,
    municipalityEn,
    localityEn,
    placeStatus,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Locality &&
          other.id == this.id &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.latE4 == this.latE4 &&
          other.lonE4 == this.lonE4 &&
          other.accuracyMeters == this.accuracyMeters &&
          other.isManualPosition == this.isManualPosition &&
          other.elevationMeters == this.elevationMeters &&
          other.elevationStatus == this.elevationStatus &&
          other.country == this.country &&
          other.municipalityCode == this.municipalityCode &&
          other.prefectureJa == this.prefectureJa &&
          other.countyJa == this.countyJa &&
          other.municipalityJa == this.municipalityJa &&
          other.localityJa == this.localityJa &&
          other.prefectureEn == this.prefectureEn &&
          other.countyEn == this.countyEn &&
          other.municipalityEn == this.municipalityEn &&
          other.localityEn == this.localityEn &&
          other.placeStatus == this.placeStatus &&
          other.createdAt == this.createdAt);
}

class LocalitiesCompanion extends UpdateCompanion<Locality> {
  final Value<int> id;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int> latE4;
  final Value<int> lonE4;
  final Value<double?> accuracyMeters;
  final Value<bool> isManualPosition;
  final Value<double?> elevationMeters;
  final Value<FetchStatus> elevationStatus;
  final Value<String> country;
  final Value<String?> municipalityCode;
  final Value<String?> prefectureJa;
  final Value<String?> countyJa;
  final Value<String?> municipalityJa;
  final Value<String?> localityJa;
  final Value<String?> prefectureEn;
  final Value<String?> countyEn;
  final Value<String?> municipalityEn;
  final Value<String?> localityEn;
  final Value<FetchStatus> placeStatus;
  final Value<DateTime> createdAt;
  const LocalitiesCompanion({
    this.id = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.latE4 = const Value.absent(),
    this.lonE4 = const Value.absent(),
    this.accuracyMeters = const Value.absent(),
    this.isManualPosition = const Value.absent(),
    this.elevationMeters = const Value.absent(),
    this.elevationStatus = const Value.absent(),
    this.country = const Value.absent(),
    this.municipalityCode = const Value.absent(),
    this.prefectureJa = const Value.absent(),
    this.countyJa = const Value.absent(),
    this.municipalityJa = const Value.absent(),
    this.localityJa = const Value.absent(),
    this.prefectureEn = const Value.absent(),
    this.countyEn = const Value.absent(),
    this.municipalityEn = const Value.absent(),
    this.localityEn = const Value.absent(),
    this.placeStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalitiesCompanion.insert({
    this.id = const Value.absent(),
    required double latitude,
    required double longitude,
    required int latE4,
    required int lonE4,
    this.accuracyMeters = const Value.absent(),
    this.isManualPosition = const Value.absent(),
    this.elevationMeters = const Value.absent(),
    required FetchStatus elevationStatus,
    this.country = const Value.absent(),
    this.municipalityCode = const Value.absent(),
    this.prefectureJa = const Value.absent(),
    this.countyJa = const Value.absent(),
    this.municipalityJa = const Value.absent(),
    this.localityJa = const Value.absent(),
    this.prefectureEn = const Value.absent(),
    this.countyEn = const Value.absent(),
    this.municipalityEn = const Value.absent(),
    this.localityEn = const Value.absent(),
    required FetchStatus placeStatus,
    this.createdAt = const Value.absent(),
  }) : latitude = Value(latitude),
       longitude = Value(longitude),
       latE4 = Value(latE4),
       lonE4 = Value(lonE4),
       elevationStatus = Value(elevationStatus),
       placeStatus = Value(placeStatus);
  static Insertable<Locality> custom({
    Expression<int>? id,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? latE4,
    Expression<int>? lonE4,
    Expression<double>? accuracyMeters,
    Expression<bool>? isManualPosition,
    Expression<double>? elevationMeters,
    Expression<String>? elevationStatus,
    Expression<String>? country,
    Expression<String>? municipalityCode,
    Expression<String>? prefectureJa,
    Expression<String>? countyJa,
    Expression<String>? municipalityJa,
    Expression<String>? localityJa,
    Expression<String>? prefectureEn,
    Expression<String>? countyEn,
    Expression<String>? municipalityEn,
    Expression<String>? localityEn,
    Expression<String>? placeStatus,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (latE4 != null) 'lat_e4': latE4,
      if (lonE4 != null) 'lon_e4': lonE4,
      if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
      if (isManualPosition != null) 'is_manual_position': isManualPosition,
      if (elevationMeters != null) 'elevation_meters': elevationMeters,
      if (elevationStatus != null) 'elevation_status': elevationStatus,
      if (country != null) 'country': country,
      if (municipalityCode != null) 'municipality_code': municipalityCode,
      if (prefectureJa != null) 'prefecture_ja': prefectureJa,
      if (countyJa != null) 'county_ja': countyJa,
      if (municipalityJa != null) 'municipality_ja': municipalityJa,
      if (localityJa != null) 'locality_ja': localityJa,
      if (prefectureEn != null) 'prefecture_en': prefectureEn,
      if (countyEn != null) 'county_en': countyEn,
      if (municipalityEn != null) 'municipality_en': municipalityEn,
      if (localityEn != null) 'locality_en': localityEn,
      if (placeStatus != null) 'place_status': placeStatus,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalitiesCompanion copyWith({
    Value<int>? id,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<int>? latE4,
    Value<int>? lonE4,
    Value<double?>? accuracyMeters,
    Value<bool>? isManualPosition,
    Value<double?>? elevationMeters,
    Value<FetchStatus>? elevationStatus,
    Value<String>? country,
    Value<String?>? municipalityCode,
    Value<String?>? prefectureJa,
    Value<String?>? countyJa,
    Value<String?>? municipalityJa,
    Value<String?>? localityJa,
    Value<String?>? prefectureEn,
    Value<String?>? countyEn,
    Value<String?>? municipalityEn,
    Value<String?>? localityEn,
    Value<FetchStatus>? placeStatus,
    Value<DateTime>? createdAt,
  }) {
    return LocalitiesCompanion(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      latE4: latE4 ?? this.latE4,
      lonE4: lonE4 ?? this.lonE4,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      isManualPosition: isManualPosition ?? this.isManualPosition,
      elevationMeters: elevationMeters ?? this.elevationMeters,
      elevationStatus: elevationStatus ?? this.elevationStatus,
      country: country ?? this.country,
      municipalityCode: municipalityCode ?? this.municipalityCode,
      prefectureJa: prefectureJa ?? this.prefectureJa,
      countyJa: countyJa ?? this.countyJa,
      municipalityJa: municipalityJa ?? this.municipalityJa,
      localityJa: localityJa ?? this.localityJa,
      prefectureEn: prefectureEn ?? this.prefectureEn,
      countyEn: countyEn ?? this.countyEn,
      municipalityEn: municipalityEn ?? this.municipalityEn,
      localityEn: localityEn ?? this.localityEn,
      placeStatus: placeStatus ?? this.placeStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (latE4.present) {
      map['lat_e4'] = Variable<int>(latE4.value);
    }
    if (lonE4.present) {
      map['lon_e4'] = Variable<int>(lonE4.value);
    }
    if (accuracyMeters.present) {
      map['accuracy_meters'] = Variable<double>(accuracyMeters.value);
    }
    if (isManualPosition.present) {
      map['is_manual_position'] = Variable<bool>(isManualPosition.value);
    }
    if (elevationMeters.present) {
      map['elevation_meters'] = Variable<double>(elevationMeters.value);
    }
    if (elevationStatus.present) {
      map['elevation_status'] = Variable<String>(
        $LocalitiesTable.$converterelevationStatus.toSql(elevationStatus.value),
      );
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (municipalityCode.present) {
      map['municipality_code'] = Variable<String>(municipalityCode.value);
    }
    if (prefectureJa.present) {
      map['prefecture_ja'] = Variable<String>(prefectureJa.value);
    }
    if (countyJa.present) {
      map['county_ja'] = Variable<String>(countyJa.value);
    }
    if (municipalityJa.present) {
      map['municipality_ja'] = Variable<String>(municipalityJa.value);
    }
    if (localityJa.present) {
      map['locality_ja'] = Variable<String>(localityJa.value);
    }
    if (prefectureEn.present) {
      map['prefecture_en'] = Variable<String>(prefectureEn.value);
    }
    if (countyEn.present) {
      map['county_en'] = Variable<String>(countyEn.value);
    }
    if (municipalityEn.present) {
      map['municipality_en'] = Variable<String>(municipalityEn.value);
    }
    if (localityEn.present) {
      map['locality_en'] = Variable<String>(localityEn.value);
    }
    if (placeStatus.present) {
      map['place_status'] = Variable<String>(
        $LocalitiesTable.$converterplaceStatus.toSql(placeStatus.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalitiesCompanion(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('latE4: $latE4, ')
          ..write('lonE4: $lonE4, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('isManualPosition: $isManualPosition, ')
          ..write('elevationMeters: $elevationMeters, ')
          ..write('elevationStatus: $elevationStatus, ')
          ..write('country: $country, ')
          ..write('municipalityCode: $municipalityCode, ')
          ..write('prefectureJa: $prefectureJa, ')
          ..write('countyJa: $countyJa, ')
          ..write('municipalityJa: $municipalityJa, ')
          ..write('localityJa: $localityJa, ')
          ..write('prefectureEn: $prefectureEn, ')
          ..write('countyEn: $countyEn, ')
          ..write('municipalityEn: $municipalityEn, ')
          ..write('localityEn: $localityEn, ')
          ..write('placeStatus: $placeStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CollectionEventsTable extends CollectionEvents
    with TableInfo<$CollectionEventsTable, CollectionEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localityIdMeta = const VerificationMeta(
    'localityId',
  );
  @override
  late final GeneratedColumn<int> localityId = GeneratedColumn<int>(
    'locality_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES localities (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate, String> startDate =
      GeneratedColumn<String>(
        'start_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CalendarDate>($CollectionEventsTable.$converterstartDate);
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate, String> endDate =
      GeneratedColumn<String>(
        'end_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CalendarDate>($CollectionEventsTable.$converterendDate);
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SamplingMethod, String>
  samplingMethod =
      GeneratedColumn<String>(
        'sampling_method',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SamplingMethod>(
        $CollectionEventsTable.$convertersamplingMethod,
      );
  static const VerificationMeta _samplingMethodOtherMeta =
      const VerificationMeta('samplingMethodOther');
  @override
  late final GeneratedColumn<String> samplingMethodOther =
      GeneratedColumn<String>(
        'sampling_method_other',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lightSourceMeta = const VerificationMeta(
    'lightSource',
  );
  @override
  late final GeneratedColumn<String> lightSource = GeneratedColumn<String>(
    'light_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baitMeta = const VerificationMeta('bait');
  @override
  late final GeneratedColumn<String> bait = GeneratedColumn<String>(
    'bait',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _habitatMeta = const VerificationMeta(
    'habitat',
  );
  @override
  late final GeneratedColumn<String> habitat = GeneratedColumn<String>(
    'habitat',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hostPlantMeta = const VerificationMeta(
    'hostPlant',
  );
  @override
  late final GeneratedColumn<String> hostPlant = GeneratedColumn<String>(
    'host_plant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _collectorMeta = const VerificationMeta(
    'collector',
  );
  @override
  late final GeneratedColumn<String> collector = GeneratedColumn<String>(
    'collector',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localityId,
    startDate,
    endDate,
    recordedAt,
    samplingMethod,
    samplingMethodOther,
    lightSource,
    bait,
    habitat,
    hostPlant,
    collector,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('locality_id')) {
      context.handle(
        _localityIdMeta,
        localityId.isAcceptableOrUnknown(data['locality_id']!, _localityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localityIdMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('sampling_method_other')) {
      context.handle(
        _samplingMethodOtherMeta,
        samplingMethodOther.isAcceptableOrUnknown(
          data['sampling_method_other']!,
          _samplingMethodOtherMeta,
        ),
      );
    }
    if (data.containsKey('light_source')) {
      context.handle(
        _lightSourceMeta,
        lightSource.isAcceptableOrUnknown(
          data['light_source']!,
          _lightSourceMeta,
        ),
      );
    }
    if (data.containsKey('bait')) {
      context.handle(
        _baitMeta,
        bait.isAcceptableOrUnknown(data['bait']!, _baitMeta),
      );
    }
    if (data.containsKey('habitat')) {
      context.handle(
        _habitatMeta,
        habitat.isAcceptableOrUnknown(data['habitat']!, _habitatMeta),
      );
    }
    if (data.containsKey('host_plant')) {
      context.handle(
        _hostPlantMeta,
        hostPlant.isAcceptableOrUnknown(data['host_plant']!, _hostPlantMeta),
      );
    }
    if (data.containsKey('collector')) {
      context.handle(
        _collectorMeta,
        collector.isAcceptableOrUnknown(data['collector']!, _collectorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}locality_id'],
      )!,
      startDate: $CollectionEventsTable.$converterstartDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}start_date'],
        )!,
      ),
      endDate: $CollectionEventsTable.$converterendDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}end_date'],
        )!,
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      samplingMethod: $CollectionEventsTable.$convertersamplingMethod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sampling_method'],
        )!,
      ),
      samplingMethodOther: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sampling_method_other'],
      ),
      lightSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}light_source'],
      ),
      bait: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bait'],
      ),
      habitat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habitat'],
      ),
      hostPlant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host_plant'],
      ),
      collector: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collector'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CollectionEventsTable createAlias(String alias) {
    return $CollectionEventsTable(attachedDatabase, alias);
  }

  static TypeConverter<CalendarDate, String> $converterstartDate =
      const CalendarDateConverter();
  static TypeConverter<CalendarDate, String> $converterendDate =
      const CalendarDateConverter();
  static JsonTypeConverter2<SamplingMethod, String, String>
  $convertersamplingMethod = const EnumNameConverter<SamplingMethod>(
    SamplingMethod.values,
  );
}

class CollectionEvent extends DataClass implements Insertable<CollectionEvent> {
  final int id;
  final int localityId;

  /// 採集日。1日のみのときは endDate と同じ値を入れる。
  final CalendarDate startDate;
  final CalendarDate endDate;

  /// 記録した日時(端末時刻)。
  final DateTime recordedAt;
  final SamplingMethod samplingMethod;

  /// 「その他」を選んだときの自由入力。
  final String? samplingMethodOther;
  final String? lightSource;
  final String? bait;
  final String? habitat;
  final String? hostPlant;

  /// 採集者名(英語表記、整形前)。
  final String? collector;
  final DateTime createdAt;
  const CollectionEvent({
    required this.id,
    required this.localityId,
    required this.startDate,
    required this.endDate,
    required this.recordedAt,
    required this.samplingMethod,
    this.samplingMethodOther,
    this.lightSource,
    this.bait,
    this.habitat,
    this.hostPlant,
    this.collector,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['locality_id'] = Variable<int>(localityId);
    {
      map['start_date'] = Variable<String>(
        $CollectionEventsTable.$converterstartDate.toSql(startDate),
      );
    }
    {
      map['end_date'] = Variable<String>(
        $CollectionEventsTable.$converterendDate.toSql(endDate),
      );
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    {
      map['sampling_method'] = Variable<String>(
        $CollectionEventsTable.$convertersamplingMethod.toSql(samplingMethod),
      );
    }
    if (!nullToAbsent || samplingMethodOther != null) {
      map['sampling_method_other'] = Variable<String>(samplingMethodOther);
    }
    if (!nullToAbsent || lightSource != null) {
      map['light_source'] = Variable<String>(lightSource);
    }
    if (!nullToAbsent || bait != null) {
      map['bait'] = Variable<String>(bait);
    }
    if (!nullToAbsent || habitat != null) {
      map['habitat'] = Variable<String>(habitat);
    }
    if (!nullToAbsent || hostPlant != null) {
      map['host_plant'] = Variable<String>(hostPlant);
    }
    if (!nullToAbsent || collector != null) {
      map['collector'] = Variable<String>(collector);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CollectionEventsCompanion toCompanion(bool nullToAbsent) {
    return CollectionEventsCompanion(
      id: Value(id),
      localityId: Value(localityId),
      startDate: Value(startDate),
      endDate: Value(endDate),
      recordedAt: Value(recordedAt),
      samplingMethod: Value(samplingMethod),
      samplingMethodOther: samplingMethodOther == null && nullToAbsent
          ? const Value.absent()
          : Value(samplingMethodOther),
      lightSource: lightSource == null && nullToAbsent
          ? const Value.absent()
          : Value(lightSource),
      bait: bait == null && nullToAbsent ? const Value.absent() : Value(bait),
      habitat: habitat == null && nullToAbsent
          ? const Value.absent()
          : Value(habitat),
      hostPlant: hostPlant == null && nullToAbsent
          ? const Value.absent()
          : Value(hostPlant),
      collector: collector == null && nullToAbsent
          ? const Value.absent()
          : Value(collector),
      createdAt: Value(createdAt),
    );
  }

  factory CollectionEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionEvent(
      id: serializer.fromJson<int>(json['id']),
      localityId: serializer.fromJson<int>(json['localityId']),
      startDate: serializer.fromJson<CalendarDate>(json['startDate']),
      endDate: serializer.fromJson<CalendarDate>(json['endDate']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      samplingMethod: $CollectionEventsTable.$convertersamplingMethod.fromJson(
        serializer.fromJson<String>(json['samplingMethod']),
      ),
      samplingMethodOther: serializer.fromJson<String?>(
        json['samplingMethodOther'],
      ),
      lightSource: serializer.fromJson<String?>(json['lightSource']),
      bait: serializer.fromJson<String?>(json['bait']),
      habitat: serializer.fromJson<String?>(json['habitat']),
      hostPlant: serializer.fromJson<String?>(json['hostPlant']),
      collector: serializer.fromJson<String?>(json['collector']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localityId': serializer.toJson<int>(localityId),
      'startDate': serializer.toJson<CalendarDate>(startDate),
      'endDate': serializer.toJson<CalendarDate>(endDate),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'samplingMethod': serializer.toJson<String>(
        $CollectionEventsTable.$convertersamplingMethod.toJson(samplingMethod),
      ),
      'samplingMethodOther': serializer.toJson<String?>(samplingMethodOther),
      'lightSource': serializer.toJson<String?>(lightSource),
      'bait': serializer.toJson<String?>(bait),
      'habitat': serializer.toJson<String?>(habitat),
      'hostPlant': serializer.toJson<String?>(hostPlant),
      'collector': serializer.toJson<String?>(collector),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CollectionEvent copyWith({
    int? id,
    int? localityId,
    CalendarDate? startDate,
    CalendarDate? endDate,
    DateTime? recordedAt,
    SamplingMethod? samplingMethod,
    Value<String?> samplingMethodOther = const Value.absent(),
    Value<String?> lightSource = const Value.absent(),
    Value<String?> bait = const Value.absent(),
    Value<String?> habitat = const Value.absent(),
    Value<String?> hostPlant = const Value.absent(),
    Value<String?> collector = const Value.absent(),
    DateTime? createdAt,
  }) => CollectionEvent(
    id: id ?? this.id,
    localityId: localityId ?? this.localityId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    recordedAt: recordedAt ?? this.recordedAt,
    samplingMethod: samplingMethod ?? this.samplingMethod,
    samplingMethodOther: samplingMethodOther.present
        ? samplingMethodOther.value
        : this.samplingMethodOther,
    lightSource: lightSource.present ? lightSource.value : this.lightSource,
    bait: bait.present ? bait.value : this.bait,
    habitat: habitat.present ? habitat.value : this.habitat,
    hostPlant: hostPlant.present ? hostPlant.value : this.hostPlant,
    collector: collector.present ? collector.value : this.collector,
    createdAt: createdAt ?? this.createdAt,
  );
  CollectionEvent copyWithCompanion(CollectionEventsCompanion data) {
    return CollectionEvent(
      id: data.id.present ? data.id.value : this.id,
      localityId: data.localityId.present
          ? data.localityId.value
          : this.localityId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      samplingMethod: data.samplingMethod.present
          ? data.samplingMethod.value
          : this.samplingMethod,
      samplingMethodOther: data.samplingMethodOther.present
          ? data.samplingMethodOther.value
          : this.samplingMethodOther,
      lightSource: data.lightSource.present
          ? data.lightSource.value
          : this.lightSource,
      bait: data.bait.present ? data.bait.value : this.bait,
      habitat: data.habitat.present ? data.habitat.value : this.habitat,
      hostPlant: data.hostPlant.present ? data.hostPlant.value : this.hostPlant,
      collector: data.collector.present ? data.collector.value : this.collector,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionEvent(')
          ..write('id: $id, ')
          ..write('localityId: $localityId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('samplingMethod: $samplingMethod, ')
          ..write('samplingMethodOther: $samplingMethodOther, ')
          ..write('lightSource: $lightSource, ')
          ..write('bait: $bait, ')
          ..write('habitat: $habitat, ')
          ..write('hostPlant: $hostPlant, ')
          ..write('collector: $collector, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localityId,
    startDate,
    endDate,
    recordedAt,
    samplingMethod,
    samplingMethodOther,
    lightSource,
    bait,
    habitat,
    hostPlant,
    collector,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionEvent &&
          other.id == this.id &&
          other.localityId == this.localityId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.recordedAt == this.recordedAt &&
          other.samplingMethod == this.samplingMethod &&
          other.samplingMethodOther == this.samplingMethodOther &&
          other.lightSource == this.lightSource &&
          other.bait == this.bait &&
          other.habitat == this.habitat &&
          other.hostPlant == this.hostPlant &&
          other.collector == this.collector &&
          other.createdAt == this.createdAt);
}

class CollectionEventsCompanion extends UpdateCompanion<CollectionEvent> {
  final Value<int> id;
  final Value<int> localityId;
  final Value<CalendarDate> startDate;
  final Value<CalendarDate> endDate;
  final Value<DateTime> recordedAt;
  final Value<SamplingMethod> samplingMethod;
  final Value<String?> samplingMethodOther;
  final Value<String?> lightSource;
  final Value<String?> bait;
  final Value<String?> habitat;
  final Value<String?> hostPlant;
  final Value<String?> collector;
  final Value<DateTime> createdAt;
  const CollectionEventsCompanion({
    this.id = const Value.absent(),
    this.localityId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.samplingMethod = const Value.absent(),
    this.samplingMethodOther = const Value.absent(),
    this.lightSource = const Value.absent(),
    this.bait = const Value.absent(),
    this.habitat = const Value.absent(),
    this.hostPlant = const Value.absent(),
    this.collector = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CollectionEventsCompanion.insert({
    this.id = const Value.absent(),
    required int localityId,
    required CalendarDate startDate,
    required CalendarDate endDate,
    required DateTime recordedAt,
    required SamplingMethod samplingMethod,
    this.samplingMethodOther = const Value.absent(),
    this.lightSource = const Value.absent(),
    this.bait = const Value.absent(),
    this.habitat = const Value.absent(),
    this.hostPlant = const Value.absent(),
    this.collector = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : localityId = Value(localityId),
       startDate = Value(startDate),
       endDate = Value(endDate),
       recordedAt = Value(recordedAt),
       samplingMethod = Value(samplingMethod);
  static Insertable<CollectionEvent> custom({
    Expression<int>? id,
    Expression<int>? localityId,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<DateTime>? recordedAt,
    Expression<String>? samplingMethod,
    Expression<String>? samplingMethodOther,
    Expression<String>? lightSource,
    Expression<String>? bait,
    Expression<String>? habitat,
    Expression<String>? hostPlant,
    Expression<String>? collector,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localityId != null) 'locality_id': localityId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (samplingMethod != null) 'sampling_method': samplingMethod,
      if (samplingMethodOther != null)
        'sampling_method_other': samplingMethodOther,
      if (lightSource != null) 'light_source': lightSource,
      if (bait != null) 'bait': bait,
      if (habitat != null) 'habitat': habitat,
      if (hostPlant != null) 'host_plant': hostPlant,
      if (collector != null) 'collector': collector,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CollectionEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? localityId,
    Value<CalendarDate>? startDate,
    Value<CalendarDate>? endDate,
    Value<DateTime>? recordedAt,
    Value<SamplingMethod>? samplingMethod,
    Value<String?>? samplingMethodOther,
    Value<String?>? lightSource,
    Value<String?>? bait,
    Value<String?>? habitat,
    Value<String?>? hostPlant,
    Value<String?>? collector,
    Value<DateTime>? createdAt,
  }) {
    return CollectionEventsCompanion(
      id: id ?? this.id,
      localityId: localityId ?? this.localityId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      recordedAt: recordedAt ?? this.recordedAt,
      samplingMethod: samplingMethod ?? this.samplingMethod,
      samplingMethodOther: samplingMethodOther ?? this.samplingMethodOther,
      lightSource: lightSource ?? this.lightSource,
      bait: bait ?? this.bait,
      habitat: habitat ?? this.habitat,
      hostPlant: hostPlant ?? this.hostPlant,
      collector: collector ?? this.collector,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localityId.present) {
      map['locality_id'] = Variable<int>(localityId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(
        $CollectionEventsTable.$converterstartDate.toSql(startDate.value),
      );
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(
        $CollectionEventsTable.$converterendDate.toSql(endDate.value),
      );
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (samplingMethod.present) {
      map['sampling_method'] = Variable<String>(
        $CollectionEventsTable.$convertersamplingMethod.toSql(
          samplingMethod.value,
        ),
      );
    }
    if (samplingMethodOther.present) {
      map['sampling_method_other'] = Variable<String>(
        samplingMethodOther.value,
      );
    }
    if (lightSource.present) {
      map['light_source'] = Variable<String>(lightSource.value);
    }
    if (bait.present) {
      map['bait'] = Variable<String>(bait.value);
    }
    if (habitat.present) {
      map['habitat'] = Variable<String>(habitat.value);
    }
    if (hostPlant.present) {
      map['host_plant'] = Variable<String>(hostPlant.value);
    }
    if (collector.present) {
      map['collector'] = Variable<String>(collector.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionEventsCompanion(')
          ..write('id: $id, ')
          ..write('localityId: $localityId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('samplingMethod: $samplingMethod, ')
          ..write('samplingMethodOther: $samplingMethodOther, ')
          ..write('lightSource: $lightSource, ')
          ..write('bait: $bait, ')
          ..write('habitat: $habitat, ')
          ..write('hostPlant: $hostPlant, ')
          ..write('collector: $collector, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SpecimensTable extends Specimens
    with TableInfo<$SpecimensTable, Specimen> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpecimensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _collectionEventIdMeta = const VerificationMeta(
    'collectionEventId',
  );
  @override
  late final GeneratedColumn<int> collectionEventId = GeneratedColumn<int>(
    'collection_event_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES collection_events (id)',
    ),
  );
  static const VerificationMeta _catalogNumberMeta = const VerificationMeta(
    'catalogNumber',
  );
  @override
  late final GeneratedColumn<int> catalogNumber = GeneratedColumn<int>(
    'catalog_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catalogTextMeta = const VerificationMeta(
    'catalogText',
  );
  @override
  late final GeneratedColumn<String> catalogText = GeneratedColumn<String>(
    'catalog_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Sex?, String> sex =
      GeneratedColumn<String>(
        'sex',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Sex?>($SpecimensTable.$convertersexn);
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _printedAtMeta = const VerificationMeta(
    'printedAt',
  );
  @override
  late final GeneratedColumn<DateTime> printedAt = GeneratedColumn<DateTime>(
    'printed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _printedElevationMeta = const VerificationMeta(
    'printedElevation',
  );
  @override
  late final GeneratedColumn<String> printedElevation = GeneratedColumn<String>(
    'printed_elevation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _printedPlaceMeta = const VerificationMeta(
    'printedPlace',
  );
  @override
  late final GeneratedColumn<String> printedPlace = GeneratedColumn<String>(
    'printed_place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    collectionEventId,
    catalogNumber,
    catalogText,
    sex,
    remarks,
    printedAt,
    printedElevation,
    printedPlace,
    deletedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'specimens';
  @override
  VerificationContext validateIntegrity(
    Insertable<Specimen> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('collection_event_id')) {
      context.handle(
        _collectionEventIdMeta,
        collectionEventId.isAcceptableOrUnknown(
          data['collection_event_id']!,
          _collectionEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionEventIdMeta);
    }
    if (data.containsKey('catalog_number')) {
      context.handle(
        _catalogNumberMeta,
        catalogNumber.isAcceptableOrUnknown(
          data['catalog_number']!,
          _catalogNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogNumberMeta);
    }
    if (data.containsKey('catalog_text')) {
      context.handle(
        _catalogTextMeta,
        catalogText.isAcceptableOrUnknown(
          data['catalog_text']!,
          _catalogTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogTextMeta);
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('printed_at')) {
      context.handle(
        _printedAtMeta,
        printedAt.isAcceptableOrUnknown(data['printed_at']!, _printedAtMeta),
      );
    }
    if (data.containsKey('printed_elevation')) {
      context.handle(
        _printedElevationMeta,
        printedElevation.isAcceptableOrUnknown(
          data['printed_elevation']!,
          _printedElevationMeta,
        ),
      );
    }
    if (data.containsKey('printed_place')) {
      context.handle(
        _printedPlaceMeta,
        printedPlace.isAcceptableOrUnknown(
          data['printed_place']!,
          _printedPlaceMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Specimen map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Specimen(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      collectionEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}collection_event_id'],
      )!,
      catalogNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}catalog_number'],
      )!,
      catalogText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_text'],
      )!,
      sex: $SpecimensTable.$convertersexn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sex'],
        ),
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      printedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}printed_at'],
      ),
      printedElevation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}printed_elevation'],
      ),
      printedPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}printed_place'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SpecimensTable createAlias(String alias) {
    return $SpecimensTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Sex, String, String> $convertersex =
      const EnumNameConverter<Sex>(Sex.values);
  static JsonTypeConverter2<Sex?, String?, String?> $convertersexn =
      JsonTypeConverter2.asNullable($convertersex);
}

class Specimen extends DataClass implements Insertable<Specimen> {
  final int id;
  final int collectionEventId;

  /// 標本番号の数値部分。
  final int catalogNumber;

  /// 作成時の書式で作った標本番号(`KYC00123`)。接頭辞を変えても変わらない。
  /// ごみ箱の中も含めて重複させない。
  final String catalogText;
  final Sex? sex;
  final String? remarks;

  /// ラベル(データ+コレクション)を印刷済みにした日時。
  final DateTime? printedAt;

  /// 印刷時に印字した標高と地名。補完や修正で食い違ったら「ラベルと不一致」にする。
  final String? printedElevation;
  final String? printedPlace;

  /// ごみ箱に移した日時。null なら有効な標本。
  final DateTime? deletedAt;
  final DateTime createdAt;
  const Specimen({
    required this.id,
    required this.collectionEventId,
    required this.catalogNumber,
    required this.catalogText,
    this.sex,
    this.remarks,
    this.printedAt,
    this.printedElevation,
    this.printedPlace,
    this.deletedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['collection_event_id'] = Variable<int>(collectionEventId);
    map['catalog_number'] = Variable<int>(catalogNumber);
    map['catalog_text'] = Variable<String>(catalogText);
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>($SpecimensTable.$convertersexn.toSql(sex));
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    if (!nullToAbsent || printedAt != null) {
      map['printed_at'] = Variable<DateTime>(printedAt);
    }
    if (!nullToAbsent || printedElevation != null) {
      map['printed_elevation'] = Variable<String>(printedElevation);
    }
    if (!nullToAbsent || printedPlace != null) {
      map['printed_place'] = Variable<String>(printedPlace);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SpecimensCompanion toCompanion(bool nullToAbsent) {
    return SpecimensCompanion(
      id: Value(id),
      collectionEventId: Value(collectionEventId),
      catalogNumber: Value(catalogNumber),
      catalogText: Value(catalogText),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      printedAt: printedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(printedAt),
      printedElevation: printedElevation == null && nullToAbsent
          ? const Value.absent()
          : Value(printedElevation),
      printedPlace: printedPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(printedPlace),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Specimen.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Specimen(
      id: serializer.fromJson<int>(json['id']),
      collectionEventId: serializer.fromJson<int>(json['collectionEventId']),
      catalogNumber: serializer.fromJson<int>(json['catalogNumber']),
      catalogText: serializer.fromJson<String>(json['catalogText']),
      sex: $SpecimensTable.$convertersexn.fromJson(
        serializer.fromJson<String?>(json['sex']),
      ),
      remarks: serializer.fromJson<String?>(json['remarks']),
      printedAt: serializer.fromJson<DateTime?>(json['printedAt']),
      printedElevation: serializer.fromJson<String?>(json['printedElevation']),
      printedPlace: serializer.fromJson<String?>(json['printedPlace']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'collectionEventId': serializer.toJson<int>(collectionEventId),
      'catalogNumber': serializer.toJson<int>(catalogNumber),
      'catalogText': serializer.toJson<String>(catalogText),
      'sex': serializer.toJson<String?>(
        $SpecimensTable.$convertersexn.toJson(sex),
      ),
      'remarks': serializer.toJson<String?>(remarks),
      'printedAt': serializer.toJson<DateTime?>(printedAt),
      'printedElevation': serializer.toJson<String?>(printedElevation),
      'printedPlace': serializer.toJson<String?>(printedPlace),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Specimen copyWith({
    int? id,
    int? collectionEventId,
    int? catalogNumber,
    String? catalogText,
    Value<Sex?> sex = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
    Value<DateTime?> printedAt = const Value.absent(),
    Value<String?> printedElevation = const Value.absent(),
    Value<String?> printedPlace = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
  }) => Specimen(
    id: id ?? this.id,
    collectionEventId: collectionEventId ?? this.collectionEventId,
    catalogNumber: catalogNumber ?? this.catalogNumber,
    catalogText: catalogText ?? this.catalogText,
    sex: sex.present ? sex.value : this.sex,
    remarks: remarks.present ? remarks.value : this.remarks,
    printedAt: printedAt.present ? printedAt.value : this.printedAt,
    printedElevation: printedElevation.present
        ? printedElevation.value
        : this.printedElevation,
    printedPlace: printedPlace.present ? printedPlace.value : this.printedPlace,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Specimen copyWithCompanion(SpecimensCompanion data) {
    return Specimen(
      id: data.id.present ? data.id.value : this.id,
      collectionEventId: data.collectionEventId.present
          ? data.collectionEventId.value
          : this.collectionEventId,
      catalogNumber: data.catalogNumber.present
          ? data.catalogNumber.value
          : this.catalogNumber,
      catalogText: data.catalogText.present
          ? data.catalogText.value
          : this.catalogText,
      sex: data.sex.present ? data.sex.value : this.sex,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      printedAt: data.printedAt.present ? data.printedAt.value : this.printedAt,
      printedElevation: data.printedElevation.present
          ? data.printedElevation.value
          : this.printedElevation,
      printedPlace: data.printedPlace.present
          ? data.printedPlace.value
          : this.printedPlace,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Specimen(')
          ..write('id: $id, ')
          ..write('collectionEventId: $collectionEventId, ')
          ..write('catalogNumber: $catalogNumber, ')
          ..write('catalogText: $catalogText, ')
          ..write('sex: $sex, ')
          ..write('remarks: $remarks, ')
          ..write('printedAt: $printedAt, ')
          ..write('printedElevation: $printedElevation, ')
          ..write('printedPlace: $printedPlace, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    collectionEventId,
    catalogNumber,
    catalogText,
    sex,
    remarks,
    printedAt,
    printedElevation,
    printedPlace,
    deletedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Specimen &&
          other.id == this.id &&
          other.collectionEventId == this.collectionEventId &&
          other.catalogNumber == this.catalogNumber &&
          other.catalogText == this.catalogText &&
          other.sex == this.sex &&
          other.remarks == this.remarks &&
          other.printedAt == this.printedAt &&
          other.printedElevation == this.printedElevation &&
          other.printedPlace == this.printedPlace &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt);
}

class SpecimensCompanion extends UpdateCompanion<Specimen> {
  final Value<int> id;
  final Value<int> collectionEventId;
  final Value<int> catalogNumber;
  final Value<String> catalogText;
  final Value<Sex?> sex;
  final Value<String?> remarks;
  final Value<DateTime?> printedAt;
  final Value<String?> printedElevation;
  final Value<String?> printedPlace;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  const SpecimensCompanion({
    this.id = const Value.absent(),
    this.collectionEventId = const Value.absent(),
    this.catalogNumber = const Value.absent(),
    this.catalogText = const Value.absent(),
    this.sex = const Value.absent(),
    this.remarks = const Value.absent(),
    this.printedAt = const Value.absent(),
    this.printedElevation = const Value.absent(),
    this.printedPlace = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SpecimensCompanion.insert({
    this.id = const Value.absent(),
    required int collectionEventId,
    required int catalogNumber,
    required String catalogText,
    this.sex = const Value.absent(),
    this.remarks = const Value.absent(),
    this.printedAt = const Value.absent(),
    this.printedElevation = const Value.absent(),
    this.printedPlace = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : collectionEventId = Value(collectionEventId),
       catalogNumber = Value(catalogNumber),
       catalogText = Value(catalogText);
  static Insertable<Specimen> custom({
    Expression<int>? id,
    Expression<int>? collectionEventId,
    Expression<int>? catalogNumber,
    Expression<String>? catalogText,
    Expression<String>? sex,
    Expression<String>? remarks,
    Expression<DateTime>? printedAt,
    Expression<String>? printedElevation,
    Expression<String>? printedPlace,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectionEventId != null) 'collection_event_id': collectionEventId,
      if (catalogNumber != null) 'catalog_number': catalogNumber,
      if (catalogText != null) 'catalog_text': catalogText,
      if (sex != null) 'sex': sex,
      if (remarks != null) 'remarks': remarks,
      if (printedAt != null) 'printed_at': printedAt,
      if (printedElevation != null) 'printed_elevation': printedElevation,
      if (printedPlace != null) 'printed_place': printedPlace,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SpecimensCompanion copyWith({
    Value<int>? id,
    Value<int>? collectionEventId,
    Value<int>? catalogNumber,
    Value<String>? catalogText,
    Value<Sex?>? sex,
    Value<String?>? remarks,
    Value<DateTime?>? printedAt,
    Value<String?>? printedElevation,
    Value<String?>? printedPlace,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
  }) {
    return SpecimensCompanion(
      id: id ?? this.id,
      collectionEventId: collectionEventId ?? this.collectionEventId,
      catalogNumber: catalogNumber ?? this.catalogNumber,
      catalogText: catalogText ?? this.catalogText,
      sex: sex ?? this.sex,
      remarks: remarks ?? this.remarks,
      printedAt: printedAt ?? this.printedAt,
      printedElevation: printedElevation ?? this.printedElevation,
      printedPlace: printedPlace ?? this.printedPlace,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (collectionEventId.present) {
      map['collection_event_id'] = Variable<int>(collectionEventId.value);
    }
    if (catalogNumber.present) {
      map['catalog_number'] = Variable<int>(catalogNumber.value);
    }
    if (catalogText.present) {
      map['catalog_text'] = Variable<String>(catalogText.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(
        $SpecimensTable.$convertersexn.toSql(sex.value),
      );
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (printedAt.present) {
      map['printed_at'] = Variable<DateTime>(printedAt.value);
    }
    if (printedElevation.present) {
      map['printed_elevation'] = Variable<String>(printedElevation.value);
    }
    if (printedPlace.present) {
      map['printed_place'] = Variable<String>(printedPlace.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpecimensCompanion(')
          ..write('id: $id, ')
          ..write('collectionEventId: $collectionEventId, ')
          ..write('catalogNumber: $catalogNumber, ')
          ..write('catalogText: $catalogText, ')
          ..write('sex: $sex, ')
          ..write('remarks: $remarks, ')
          ..write('printedAt: $printedAt, ')
          ..write('printedElevation: $printedElevation, ')
          ..write('printedPlace: $printedPlace, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $IdentificationsTable extends Identifications
    with TableInfo<$IdentificationsTable, Identification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdentificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _specimenIdMeta = const VerificationMeta(
    'specimenId',
  );
  @override
  late final GeneratedColumn<int> specimenId = GeneratedColumn<int>(
    'specimen_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES specimens (id)',
    ),
  );
  static const VerificationMeta _vernacularNameMeta = const VerificationMeta(
    'vernacularName',
  );
  @override
  late final GeneratedColumn<String> vernacularName = GeneratedColumn<String>(
    'vernacular_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genusMeta = const VerificationMeta('genus');
  @override
  late final GeneratedColumn<String> genus = GeneratedColumn<String>(
    'genus',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speciesMeta = const VerificationMeta(
    'species',
  );
  @override
  late final GeneratedColumn<String> species = GeneratedColumn<String>(
    'species',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subspeciesMeta = const VerificationMeta(
    'subspecies',
  );
  @override
  late final GeneratedColumn<String> subspecies = GeneratedColumn<String>(
    'subspecies',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorshipMeta = const VerificationMeta(
    'authorship',
  );
  @override
  late final GeneratedColumn<String> authorship = GeneratedColumn<String>(
    'authorship',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _identifiedByMeta = const VerificationMeta(
    'identifiedBy',
  );
  @override
  late final GeneratedColumn<String> identifiedBy = GeneratedColumn<String>(
    'identified_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CalendarDate?, String>
  dateIdentified =
      GeneratedColumn<String>(
        'date_identified',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<CalendarDate?>(
        $IdentificationsTable.$converterdateIdentifiedn,
      );
  @override
  late final GeneratedColumnWithTypeConverter<IdentificationStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<IdentificationStatus>($IdentificationsTable.$converterstatus);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    specimenId,
    vernacularName,
    genus,
    species,
    subspecies,
    authorship,
    identifiedBy,
    dateIdentified,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'identifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Identification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('specimen_id')) {
      context.handle(
        _specimenIdMeta,
        specimenId.isAcceptableOrUnknown(data['specimen_id']!, _specimenIdMeta),
      );
    } else if (isInserting) {
      context.missing(_specimenIdMeta);
    }
    if (data.containsKey('vernacular_name')) {
      context.handle(
        _vernacularNameMeta,
        vernacularName.isAcceptableOrUnknown(
          data['vernacular_name']!,
          _vernacularNameMeta,
        ),
      );
    }
    if (data.containsKey('genus')) {
      context.handle(
        _genusMeta,
        genus.isAcceptableOrUnknown(data['genus']!, _genusMeta),
      );
    }
    if (data.containsKey('species')) {
      context.handle(
        _speciesMeta,
        species.isAcceptableOrUnknown(data['species']!, _speciesMeta),
      );
    }
    if (data.containsKey('subspecies')) {
      context.handle(
        _subspeciesMeta,
        subspecies.isAcceptableOrUnknown(data['subspecies']!, _subspeciesMeta),
      );
    }
    if (data.containsKey('authorship')) {
      context.handle(
        _authorshipMeta,
        authorship.isAcceptableOrUnknown(data['authorship']!, _authorshipMeta),
      );
    }
    if (data.containsKey('identified_by')) {
      context.handle(
        _identifiedByMeta,
        identifiedBy.isAcceptableOrUnknown(
          data['identified_by']!,
          _identifiedByMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Identification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Identification(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      specimenId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}specimen_id'],
      )!,
      vernacularName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vernacular_name'],
      ),
      genus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genus'],
      ),
      species: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}species'],
      ),
      subspecies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subspecies'],
      ),
      authorship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authorship'],
      ),
      identifiedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identified_by'],
      ),
      dateIdentified: $IdentificationsTable.$converterdateIdentifiedn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date_identified'],
        ),
      ),
      status: $IdentificationsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IdentificationsTable createAlias(String alias) {
    return $IdentificationsTable(attachedDatabase, alias);
  }

  static TypeConverter<CalendarDate, String> $converterdateIdentified =
      const CalendarDateConverter();
  static TypeConverter<CalendarDate?, String?> $converterdateIdentifiedn =
      NullAwareTypeConverter.wrap($converterdateIdentified);
  static JsonTypeConverter2<IdentificationStatus, String, String>
  $converterstatus = const EnumNameConverter<IdentificationStatus>(
    IdentificationStatus.values,
  );
}

class Identification extends DataClass implements Insertable<Identification> {
  final int id;
  final int specimenId;
  final String? vernacularName;
  final String? genus;
  final String? species;
  final String? subspecies;

  /// 命名者・年。括弧の有無を含めて入力どおり保持する。
  final String? authorship;
  final String? identifiedBy;
  final CalendarDate? dateIdentified;
  final IdentificationStatus status;
  final DateTime createdAt;
  const Identification({
    required this.id,
    required this.specimenId,
    this.vernacularName,
    this.genus,
    this.species,
    this.subspecies,
    this.authorship,
    this.identifiedBy,
    this.dateIdentified,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['specimen_id'] = Variable<int>(specimenId);
    if (!nullToAbsent || vernacularName != null) {
      map['vernacular_name'] = Variable<String>(vernacularName);
    }
    if (!nullToAbsent || genus != null) {
      map['genus'] = Variable<String>(genus);
    }
    if (!nullToAbsent || species != null) {
      map['species'] = Variable<String>(species);
    }
    if (!nullToAbsent || subspecies != null) {
      map['subspecies'] = Variable<String>(subspecies);
    }
    if (!nullToAbsent || authorship != null) {
      map['authorship'] = Variable<String>(authorship);
    }
    if (!nullToAbsent || identifiedBy != null) {
      map['identified_by'] = Variable<String>(identifiedBy);
    }
    if (!nullToAbsent || dateIdentified != null) {
      map['date_identified'] = Variable<String>(
        $IdentificationsTable.$converterdateIdentifiedn.toSql(dateIdentified),
      );
    }
    {
      map['status'] = Variable<String>(
        $IdentificationsTable.$converterstatus.toSql(status),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IdentificationsCompanion toCompanion(bool nullToAbsent) {
    return IdentificationsCompanion(
      id: Value(id),
      specimenId: Value(specimenId),
      vernacularName: vernacularName == null && nullToAbsent
          ? const Value.absent()
          : Value(vernacularName),
      genus: genus == null && nullToAbsent
          ? const Value.absent()
          : Value(genus),
      species: species == null && nullToAbsent
          ? const Value.absent()
          : Value(species),
      subspecies: subspecies == null && nullToAbsent
          ? const Value.absent()
          : Value(subspecies),
      authorship: authorship == null && nullToAbsent
          ? const Value.absent()
          : Value(authorship),
      identifiedBy: identifiedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(identifiedBy),
      dateIdentified: dateIdentified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateIdentified),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Identification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Identification(
      id: serializer.fromJson<int>(json['id']),
      specimenId: serializer.fromJson<int>(json['specimenId']),
      vernacularName: serializer.fromJson<String?>(json['vernacularName']),
      genus: serializer.fromJson<String?>(json['genus']),
      species: serializer.fromJson<String?>(json['species']),
      subspecies: serializer.fromJson<String?>(json['subspecies']),
      authorship: serializer.fromJson<String?>(json['authorship']),
      identifiedBy: serializer.fromJson<String?>(json['identifiedBy']),
      dateIdentified: serializer.fromJson<CalendarDate?>(
        json['dateIdentified'],
      ),
      status: $IdentificationsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'specimenId': serializer.toJson<int>(specimenId),
      'vernacularName': serializer.toJson<String?>(vernacularName),
      'genus': serializer.toJson<String?>(genus),
      'species': serializer.toJson<String?>(species),
      'subspecies': serializer.toJson<String?>(subspecies),
      'authorship': serializer.toJson<String?>(authorship),
      'identifiedBy': serializer.toJson<String?>(identifiedBy),
      'dateIdentified': serializer.toJson<CalendarDate?>(dateIdentified),
      'status': serializer.toJson<String>(
        $IdentificationsTable.$converterstatus.toJson(status),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Identification copyWith({
    int? id,
    int? specimenId,
    Value<String?> vernacularName = const Value.absent(),
    Value<String?> genus = const Value.absent(),
    Value<String?> species = const Value.absent(),
    Value<String?> subspecies = const Value.absent(),
    Value<String?> authorship = const Value.absent(),
    Value<String?> identifiedBy = const Value.absent(),
    Value<CalendarDate?> dateIdentified = const Value.absent(),
    IdentificationStatus? status,
    DateTime? createdAt,
  }) => Identification(
    id: id ?? this.id,
    specimenId: specimenId ?? this.specimenId,
    vernacularName: vernacularName.present
        ? vernacularName.value
        : this.vernacularName,
    genus: genus.present ? genus.value : this.genus,
    species: species.present ? species.value : this.species,
    subspecies: subspecies.present ? subspecies.value : this.subspecies,
    authorship: authorship.present ? authorship.value : this.authorship,
    identifiedBy: identifiedBy.present ? identifiedBy.value : this.identifiedBy,
    dateIdentified: dateIdentified.present
        ? dateIdentified.value
        : this.dateIdentified,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  Identification copyWithCompanion(IdentificationsCompanion data) {
    return Identification(
      id: data.id.present ? data.id.value : this.id,
      specimenId: data.specimenId.present
          ? data.specimenId.value
          : this.specimenId,
      vernacularName: data.vernacularName.present
          ? data.vernacularName.value
          : this.vernacularName,
      genus: data.genus.present ? data.genus.value : this.genus,
      species: data.species.present ? data.species.value : this.species,
      subspecies: data.subspecies.present
          ? data.subspecies.value
          : this.subspecies,
      authorship: data.authorship.present
          ? data.authorship.value
          : this.authorship,
      identifiedBy: data.identifiedBy.present
          ? data.identifiedBy.value
          : this.identifiedBy,
      dateIdentified: data.dateIdentified.present
          ? data.dateIdentified.value
          : this.dateIdentified,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Identification(')
          ..write('id: $id, ')
          ..write('specimenId: $specimenId, ')
          ..write('vernacularName: $vernacularName, ')
          ..write('genus: $genus, ')
          ..write('species: $species, ')
          ..write('subspecies: $subspecies, ')
          ..write('authorship: $authorship, ')
          ..write('identifiedBy: $identifiedBy, ')
          ..write('dateIdentified: $dateIdentified, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    specimenId,
    vernacularName,
    genus,
    species,
    subspecies,
    authorship,
    identifiedBy,
    dateIdentified,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Identification &&
          other.id == this.id &&
          other.specimenId == this.specimenId &&
          other.vernacularName == this.vernacularName &&
          other.genus == this.genus &&
          other.species == this.species &&
          other.subspecies == this.subspecies &&
          other.authorship == this.authorship &&
          other.identifiedBy == this.identifiedBy &&
          other.dateIdentified == this.dateIdentified &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class IdentificationsCompanion extends UpdateCompanion<Identification> {
  final Value<int> id;
  final Value<int> specimenId;
  final Value<String?> vernacularName;
  final Value<String?> genus;
  final Value<String?> species;
  final Value<String?> subspecies;
  final Value<String?> authorship;
  final Value<String?> identifiedBy;
  final Value<CalendarDate?> dateIdentified;
  final Value<IdentificationStatus> status;
  final Value<DateTime> createdAt;
  const IdentificationsCompanion({
    this.id = const Value.absent(),
    this.specimenId = const Value.absent(),
    this.vernacularName = const Value.absent(),
    this.genus = const Value.absent(),
    this.species = const Value.absent(),
    this.subspecies = const Value.absent(),
    this.authorship = const Value.absent(),
    this.identifiedBy = const Value.absent(),
    this.dateIdentified = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  IdentificationsCompanion.insert({
    this.id = const Value.absent(),
    required int specimenId,
    this.vernacularName = const Value.absent(),
    this.genus = const Value.absent(),
    this.species = const Value.absent(),
    this.subspecies = const Value.absent(),
    this.authorship = const Value.absent(),
    this.identifiedBy = const Value.absent(),
    this.dateIdentified = const Value.absent(),
    required IdentificationStatus status,
    this.createdAt = const Value.absent(),
  }) : specimenId = Value(specimenId),
       status = Value(status);
  static Insertable<Identification> custom({
    Expression<int>? id,
    Expression<int>? specimenId,
    Expression<String>? vernacularName,
    Expression<String>? genus,
    Expression<String>? species,
    Expression<String>? subspecies,
    Expression<String>? authorship,
    Expression<String>? identifiedBy,
    Expression<String>? dateIdentified,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (specimenId != null) 'specimen_id': specimenId,
      if (vernacularName != null) 'vernacular_name': vernacularName,
      if (genus != null) 'genus': genus,
      if (species != null) 'species': species,
      if (subspecies != null) 'subspecies': subspecies,
      if (authorship != null) 'authorship': authorship,
      if (identifiedBy != null) 'identified_by': identifiedBy,
      if (dateIdentified != null) 'date_identified': dateIdentified,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  IdentificationsCompanion copyWith({
    Value<int>? id,
    Value<int>? specimenId,
    Value<String?>? vernacularName,
    Value<String?>? genus,
    Value<String?>? species,
    Value<String?>? subspecies,
    Value<String?>? authorship,
    Value<String?>? identifiedBy,
    Value<CalendarDate?>? dateIdentified,
    Value<IdentificationStatus>? status,
    Value<DateTime>? createdAt,
  }) {
    return IdentificationsCompanion(
      id: id ?? this.id,
      specimenId: specimenId ?? this.specimenId,
      vernacularName: vernacularName ?? this.vernacularName,
      genus: genus ?? this.genus,
      species: species ?? this.species,
      subspecies: subspecies ?? this.subspecies,
      authorship: authorship ?? this.authorship,
      identifiedBy: identifiedBy ?? this.identifiedBy,
      dateIdentified: dateIdentified ?? this.dateIdentified,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (specimenId.present) {
      map['specimen_id'] = Variable<int>(specimenId.value);
    }
    if (vernacularName.present) {
      map['vernacular_name'] = Variable<String>(vernacularName.value);
    }
    if (genus.present) {
      map['genus'] = Variable<String>(genus.value);
    }
    if (species.present) {
      map['species'] = Variable<String>(species.value);
    }
    if (subspecies.present) {
      map['subspecies'] = Variable<String>(subspecies.value);
    }
    if (authorship.present) {
      map['authorship'] = Variable<String>(authorship.value);
    }
    if (identifiedBy.present) {
      map['identified_by'] = Variable<String>(identifiedBy.value);
    }
    if (dateIdentified.present) {
      map['date_identified'] = Variable<String>(
        $IdentificationsTable.$converterdateIdentifiedn.toSql(
          dateIdentified.value,
        ),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $IdentificationsTable.$converterstatus.toSql(status.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdentificationsCompanion(')
          ..write('id: $id, ')
          ..write('specimenId: $specimenId, ')
          ..write('vernacularName: $vernacularName, ')
          ..write('genus: $genus, ')
          ..write('species: $species, ')
          ..write('subspecies: $subspecies, ')
          ..write('authorship: $authorship, ')
          ..write('identifiedBy: $identifiedBy, ')
          ..write('dateIdentified: $dateIdentified, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EnrichmentQueueTable extends EnrichmentQueue
    with TableInfo<$EnrichmentQueueTable, EnrichmentTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnrichmentQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localityIdMeta = const VerificationMeta(
    'localityId',
  );
  @override
  late final GeneratedColumn<int> localityId = GeneratedColumn<int>(
    'locality_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES localities (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<EnrichmentKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EnrichmentKind>($EnrichmentQueueTable.$converterkind);
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localityId,
    kind,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'enrichment_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnrichmentTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('locality_id')) {
      context.handle(
        _localityIdMeta,
        localityId.isAcceptableOrUnknown(data['locality_id']!, _localityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localityIdMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {localityId, kind},
  ];
  @override
  EnrichmentTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnrichmentTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}locality_id'],
      )!,
      kind: $EnrichmentQueueTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EnrichmentQueueTable createAlias(String alias) {
    return $EnrichmentQueueTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EnrichmentKind, String, String> $converterkind =
      const EnumNameConverter<EnrichmentKind>(EnrichmentKind.values);
}

class EnrichmentTask extends DataClass implements Insertable<EnrichmentTask> {
  final int id;
  final int localityId;
  final EnrichmentKind kind;

  /// 通信エラーで失敗した回数。3回まで自動で再試行する。
  final int attempts;

  /// 次に再試行してよい日時。null ならすぐ実行してよい。
  final DateTime? nextAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  const EnrichmentTask({
    required this.id,
    required this.localityId,
    required this.kind,
    required this.attempts,
    this.nextAttemptAt,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['locality_id'] = Variable<int>(localityId);
    {
      map['kind'] = Variable<String>(
        $EnrichmentQueueTable.$converterkind.toSql(kind),
      );
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EnrichmentQueueCompanion toCompanion(bool nullToAbsent) {
    return EnrichmentQueueCompanion(
      id: Value(id),
      localityId: Value(localityId),
      kind: Value(kind),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory EnrichmentTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnrichmentTask(
      id: serializer.fromJson<int>(json['id']),
      localityId: serializer.fromJson<int>(json['localityId']),
      kind: $EnrichmentQueueTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localityId': serializer.toJson<int>(localityId),
      'kind': serializer.toJson<String>(
        $EnrichmentQueueTable.$converterkind.toJson(kind),
      ),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EnrichmentTask copyWith({
    int? id,
    int? localityId,
    EnrichmentKind? kind,
    int? attempts,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => EnrichmentTask(
    id: id ?? this.id,
    localityId: localityId ?? this.localityId,
    kind: kind ?? this.kind,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  EnrichmentTask copyWithCompanion(EnrichmentQueueCompanion data) {
    return EnrichmentTask(
      id: data.id.present ? data.id.value : this.id,
      localityId: data.localityId.present
          ? data.localityId.value
          : this.localityId,
      kind: data.kind.present ? data.kind.value : this.kind,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnrichmentTask(')
          ..write('id: $id, ')
          ..write('localityId: $localityId, ')
          ..write('kind: $kind, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localityId,
    kind,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnrichmentTask &&
          other.id == this.id &&
          other.localityId == this.localityId &&
          other.kind == this.kind &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class EnrichmentQueueCompanion extends UpdateCompanion<EnrichmentTask> {
  final Value<int> id;
  final Value<int> localityId;
  final Value<EnrichmentKind> kind;
  final Value<int> attempts;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  const EnrichmentQueueCompanion({
    this.id = const Value.absent(),
    this.localityId = const Value.absent(),
    this.kind = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EnrichmentQueueCompanion.insert({
    this.id = const Value.absent(),
    required int localityId,
    required EnrichmentKind kind,
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : localityId = Value(localityId),
       kind = Value(kind);
  static Insertable<EnrichmentTask> custom({
    Expression<int>? id,
    Expression<int>? localityId,
    Expression<String>? kind,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localityId != null) 'locality_id': localityId,
      if (kind != null) 'kind': kind,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EnrichmentQueueCompanion copyWith({
    Value<int>? id,
    Value<int>? localityId,
    Value<EnrichmentKind>? kind,
    Value<int>? attempts,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
  }) {
    return EnrichmentQueueCompanion(
      id: id ?? this.id,
      localityId: localityId ?? this.localityId,
      kind: kind ?? this.kind,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localityId.present) {
      map['locality_id'] = Variable<int>(localityId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $EnrichmentQueueTable.$converterkind.toSql(kind.value),
      );
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnrichmentQueueCompanion(')
          ..write('id: $id, ')
          ..write('localityId: $localityId, ')
          ..write('kind: $kind, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DraftsTable extends Drafts with TableInfo<$DraftsTable, Draft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _formJsonMeta = const VerificationMeta(
    'formJson',
  );
  @override
  late final GeneratedColumn<String> formJson = GeneratedColumn<String>(
    'form_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, formJson, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Draft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('form_json')) {
      context.handle(
        _formJsonMeta,
        formJson.isAcceptableOrUnknown(data['form_json']!, _formJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_formJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Draft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Draft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      formJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}form_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DraftsTable createAlias(String alias) {
    return $DraftsTable(attachedDatabase, alias);
  }
}

class Draft extends DataClass implements Insertable<Draft> {
  final int id;
  final String formJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Draft({
    required this.id,
    required this.formJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['form_json'] = Variable<String>(formJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DraftsCompanion toCompanion(bool nullToAbsent) {
    return DraftsCompanion(
      id: Value(id),
      formJson: Value(formJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Draft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Draft(
      id: serializer.fromJson<int>(json['id']),
      formJson: serializer.fromJson<String>(json['formJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'formJson': serializer.toJson<String>(formJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Draft copyWith({
    int? id,
    String? formJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Draft(
    id: id ?? this.id,
    formJson: formJson ?? this.formJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Draft copyWithCompanion(DraftsCompanion data) {
    return Draft(
      id: data.id.present ? data.id.value : this.id,
      formJson: data.formJson.present ? data.formJson.value : this.formJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Draft(')
          ..write('id: $id, ')
          ..write('formJson: $formJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, formJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Draft &&
          other.id == this.id &&
          other.formJson == this.formJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DraftsCompanion extends UpdateCompanion<Draft> {
  final Value<int> id;
  final Value<String> formJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DraftsCompanion({
    this.id = const Value.absent(),
    this.formJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DraftsCompanion.insert({
    this.id = const Value.absent(),
    required String formJson,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : formJson = Value(formJson);
  static Insertable<Draft> custom({
    Expression<int>? id,
    Expression<String>? formJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (formJson != null) 'form_json': formJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DraftsCompanion copyWith({
    Value<int>? id,
    Value<String>? formJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DraftsCompanion(
      id: id ?? this.id,
      formJson: formJson ?? this.formJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (formJson.present) {
      map['form_json'] = Variable<String>(formJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftsCompanion(')
          ..write('id: $id, ')
          ..write('formJson: $formJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    check: () => id.equals(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _collectorNameMeta = const VerificationMeta(
    'collectorName',
  );
  @override
  late final GeneratedColumn<String> collectorName = GeneratedColumn<String>(
    'collector_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastIdentifierMeta = const VerificationMeta(
    'lastIdentifier',
  );
  @override
  late final GeneratedColumn<String> lastIdentifier = GeneratedColumn<String>(
    'last_identifier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catalogPrefixMeta = const VerificationMeta(
    'catalogPrefix',
  );
  @override
  late final GeneratedColumn<String> catalogPrefix = GeneratedColumn<String>(
    'catalog_prefix',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('KYC'),
  );
  static const VerificationMeta _catalogDigitsMeta = const VerificationMeta(
    'catalogDigits',
  );
  @override
  late final GeneratedColumn<int> catalogDigits = GeneratedColumn<int>(
    'catalog_digits',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _nextCatalogNumberMeta = const VerificationMeta(
    'nextCatalogNumber',
  );
  @override
  late final GeneratedColumn<int> nextCatalogNumber = GeneratedColumn<int>(
    'next_catalog_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ElevationRounding, String>
  elevationRounding =
      GeneratedColumn<String>(
        'elevation_rounding',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(ElevationRounding.tenMeters.name),
      ).withConverter<ElevationRounding>(
        $AppSettingsTable.$converterelevationRounding,
      );
  static const VerificationMeta _lastBackupAtMeta = const VerificationMeta(
    'lastBackupAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastBackupAt = GeneratedColumn<DateTime>(
    'last_backup_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    collectorName,
    lastIdentifier,
    catalogPrefix,
    catalogDigits,
    nextCatalogNumber,
    elevationRounding,
    lastBackupAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('collector_name')) {
      context.handle(
        _collectorNameMeta,
        collectorName.isAcceptableOrUnknown(
          data['collector_name']!,
          _collectorNameMeta,
        ),
      );
    }
    if (data.containsKey('last_identifier')) {
      context.handle(
        _lastIdentifierMeta,
        lastIdentifier.isAcceptableOrUnknown(
          data['last_identifier']!,
          _lastIdentifierMeta,
        ),
      );
    }
    if (data.containsKey('catalog_prefix')) {
      context.handle(
        _catalogPrefixMeta,
        catalogPrefix.isAcceptableOrUnknown(
          data['catalog_prefix']!,
          _catalogPrefixMeta,
        ),
      );
    }
    if (data.containsKey('catalog_digits')) {
      context.handle(
        _catalogDigitsMeta,
        catalogDigits.isAcceptableOrUnknown(
          data['catalog_digits']!,
          _catalogDigitsMeta,
        ),
      );
    }
    if (data.containsKey('next_catalog_number')) {
      context.handle(
        _nextCatalogNumberMeta,
        nextCatalogNumber.isAcceptableOrUnknown(
          data['next_catalog_number']!,
          _nextCatalogNumberMeta,
        ),
      );
    }
    if (data.containsKey('last_backup_at')) {
      context.handle(
        _lastBackupAtMeta,
        lastBackupAt.isAcceptableOrUnknown(
          data['last_backup_at']!,
          _lastBackupAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      collectorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collector_name'],
      ),
      lastIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_identifier'],
      ),
      catalogPrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_prefix'],
      )!,
      catalogDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}catalog_digits'],
      )!,
      nextCatalogNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_catalog_number'],
      ),
      elevationRounding: $AppSettingsTable.$converterelevationRounding.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}elevation_rounding'],
        )!,
      ),
      lastBackupAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_backup_at'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ElevationRounding, String, String>
  $converterelevationRounding = const EnumNameConverter<ElevationRounding>(
    ElevationRounding.values,
  );
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;

  /// 採集者名(英語表記)。
  final String? collectorName;

  /// 同定者名の既定(最後に入力した名前)。
  final String? lastIdentifier;
  final String catalogPrefix;
  final int catalogDigits;

  /// 次に発行する標本番号。null の間は初回設定が済んでおらず、記録できない。
  final int? nextCatalogNumber;
  final ElevationRounding elevationRounding;

  /// 最後にバックアップを書き出した日時(スキーマ 2 で追加)。
  final DateTime? lastBackupAt;
  const AppSettingsRow({
    required this.id,
    this.collectorName,
    this.lastIdentifier,
    required this.catalogPrefix,
    required this.catalogDigits,
    this.nextCatalogNumber,
    required this.elevationRounding,
    this.lastBackupAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || collectorName != null) {
      map['collector_name'] = Variable<String>(collectorName);
    }
    if (!nullToAbsent || lastIdentifier != null) {
      map['last_identifier'] = Variable<String>(lastIdentifier);
    }
    map['catalog_prefix'] = Variable<String>(catalogPrefix);
    map['catalog_digits'] = Variable<int>(catalogDigits);
    if (!nullToAbsent || nextCatalogNumber != null) {
      map['next_catalog_number'] = Variable<int>(nextCatalogNumber);
    }
    {
      map['elevation_rounding'] = Variable<String>(
        $AppSettingsTable.$converterelevationRounding.toSql(elevationRounding),
      );
    }
    if (!nullToAbsent || lastBackupAt != null) {
      map['last_backup_at'] = Variable<DateTime>(lastBackupAt);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      collectorName: collectorName == null && nullToAbsent
          ? const Value.absent()
          : Value(collectorName),
      lastIdentifier: lastIdentifier == null && nullToAbsent
          ? const Value.absent()
          : Value(lastIdentifier),
      catalogPrefix: Value(catalogPrefix),
      catalogDigits: Value(catalogDigits),
      nextCatalogNumber: nextCatalogNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(nextCatalogNumber),
      elevationRounding: Value(elevationRounding),
      lastBackupAt: lastBackupAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupAt),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      collectorName: serializer.fromJson<String?>(json['collectorName']),
      lastIdentifier: serializer.fromJson<String?>(json['lastIdentifier']),
      catalogPrefix: serializer.fromJson<String>(json['catalogPrefix']),
      catalogDigits: serializer.fromJson<int>(json['catalogDigits']),
      nextCatalogNumber: serializer.fromJson<int?>(json['nextCatalogNumber']),
      elevationRounding: $AppSettingsTable.$converterelevationRounding.fromJson(
        serializer.fromJson<String>(json['elevationRounding']),
      ),
      lastBackupAt: serializer.fromJson<DateTime?>(json['lastBackupAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'collectorName': serializer.toJson<String?>(collectorName),
      'lastIdentifier': serializer.toJson<String?>(lastIdentifier),
      'catalogPrefix': serializer.toJson<String>(catalogPrefix),
      'catalogDigits': serializer.toJson<int>(catalogDigits),
      'nextCatalogNumber': serializer.toJson<int?>(nextCatalogNumber),
      'elevationRounding': serializer.toJson<String>(
        $AppSettingsTable.$converterelevationRounding.toJson(elevationRounding),
      ),
      'lastBackupAt': serializer.toJson<DateTime?>(lastBackupAt),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    Value<String?> collectorName = const Value.absent(),
    Value<String?> lastIdentifier = const Value.absent(),
    String? catalogPrefix,
    int? catalogDigits,
    Value<int?> nextCatalogNumber = const Value.absent(),
    ElevationRounding? elevationRounding,
    Value<DateTime?> lastBackupAt = const Value.absent(),
  }) => AppSettingsRow(
    id: id ?? this.id,
    collectorName: collectorName.present
        ? collectorName.value
        : this.collectorName,
    lastIdentifier: lastIdentifier.present
        ? lastIdentifier.value
        : this.lastIdentifier,
    catalogPrefix: catalogPrefix ?? this.catalogPrefix,
    catalogDigits: catalogDigits ?? this.catalogDigits,
    nextCatalogNumber: nextCatalogNumber.present
        ? nextCatalogNumber.value
        : this.nextCatalogNumber,
    elevationRounding: elevationRounding ?? this.elevationRounding,
    lastBackupAt: lastBackupAt.present ? lastBackupAt.value : this.lastBackupAt,
  );
  AppSettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      collectorName: data.collectorName.present
          ? data.collectorName.value
          : this.collectorName,
      lastIdentifier: data.lastIdentifier.present
          ? data.lastIdentifier.value
          : this.lastIdentifier,
      catalogPrefix: data.catalogPrefix.present
          ? data.catalogPrefix.value
          : this.catalogPrefix,
      catalogDigits: data.catalogDigits.present
          ? data.catalogDigits.value
          : this.catalogDigits,
      nextCatalogNumber: data.nextCatalogNumber.present
          ? data.nextCatalogNumber.value
          : this.nextCatalogNumber,
      elevationRounding: data.elevationRounding.present
          ? data.elevationRounding.value
          : this.elevationRounding,
      lastBackupAt: data.lastBackupAt.present
          ? data.lastBackupAt.value
          : this.lastBackupAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('collectorName: $collectorName, ')
          ..write('lastIdentifier: $lastIdentifier, ')
          ..write('catalogPrefix: $catalogPrefix, ')
          ..write('catalogDigits: $catalogDigits, ')
          ..write('nextCatalogNumber: $nextCatalogNumber, ')
          ..write('elevationRounding: $elevationRounding, ')
          ..write('lastBackupAt: $lastBackupAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    collectorName,
    lastIdentifier,
    catalogPrefix,
    catalogDigits,
    nextCatalogNumber,
    elevationRounding,
    lastBackupAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.collectorName == this.collectorName &&
          other.lastIdentifier == this.lastIdentifier &&
          other.catalogPrefix == this.catalogPrefix &&
          other.catalogDigits == this.catalogDigits &&
          other.nextCatalogNumber == this.nextCatalogNumber &&
          other.elevationRounding == this.elevationRounding &&
          other.lastBackupAt == this.lastBackupAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<String?> collectorName;
  final Value<String?> lastIdentifier;
  final Value<String> catalogPrefix;
  final Value<int> catalogDigits;
  final Value<int?> nextCatalogNumber;
  final Value<ElevationRounding> elevationRounding;
  final Value<DateTime?> lastBackupAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.collectorName = const Value.absent(),
    this.lastIdentifier = const Value.absent(),
    this.catalogPrefix = const Value.absent(),
    this.catalogDigits = const Value.absent(),
    this.nextCatalogNumber = const Value.absent(),
    this.elevationRounding = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.collectorName = const Value.absent(),
    this.lastIdentifier = const Value.absent(),
    this.catalogPrefix = const Value.absent(),
    this.catalogDigits = const Value.absent(),
    this.nextCatalogNumber = const Value.absent(),
    this.elevationRounding = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
  });
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? collectorName,
    Expression<String>? lastIdentifier,
    Expression<String>? catalogPrefix,
    Expression<int>? catalogDigits,
    Expression<int>? nextCatalogNumber,
    Expression<String>? elevationRounding,
    Expression<DateTime>? lastBackupAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectorName != null) 'collector_name': collectorName,
      if (lastIdentifier != null) 'last_identifier': lastIdentifier,
      if (catalogPrefix != null) 'catalog_prefix': catalogPrefix,
      if (catalogDigits != null) 'catalog_digits': catalogDigits,
      if (nextCatalogNumber != null) 'next_catalog_number': nextCatalogNumber,
      if (elevationRounding != null) 'elevation_rounding': elevationRounding,
      if (lastBackupAt != null) 'last_backup_at': lastBackupAt,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? collectorName,
    Value<String?>? lastIdentifier,
    Value<String>? catalogPrefix,
    Value<int>? catalogDigits,
    Value<int?>? nextCatalogNumber,
    Value<ElevationRounding>? elevationRounding,
    Value<DateTime?>? lastBackupAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      collectorName: collectorName ?? this.collectorName,
      lastIdentifier: lastIdentifier ?? this.lastIdentifier,
      catalogPrefix: catalogPrefix ?? this.catalogPrefix,
      catalogDigits: catalogDigits ?? this.catalogDigits,
      nextCatalogNumber: nextCatalogNumber ?? this.nextCatalogNumber,
      elevationRounding: elevationRounding ?? this.elevationRounding,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (collectorName.present) {
      map['collector_name'] = Variable<String>(collectorName.value);
    }
    if (lastIdentifier.present) {
      map['last_identifier'] = Variable<String>(lastIdentifier.value);
    }
    if (catalogPrefix.present) {
      map['catalog_prefix'] = Variable<String>(catalogPrefix.value);
    }
    if (catalogDigits.present) {
      map['catalog_digits'] = Variable<int>(catalogDigits.value);
    }
    if (nextCatalogNumber.present) {
      map['next_catalog_number'] = Variable<int>(nextCatalogNumber.value);
    }
    if (elevationRounding.present) {
      map['elevation_rounding'] = Variable<String>(
        $AppSettingsTable.$converterelevationRounding.toSql(
          elevationRounding.value,
        ),
      );
    }
    if (lastBackupAt.present) {
      map['last_backup_at'] = Variable<DateTime>(lastBackupAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('collectorName: $collectorName, ')
          ..write('lastIdentifier: $lastIdentifier, ')
          ..write('catalogPrefix: $catalogPrefix, ')
          ..write('catalogDigits: $catalogDigits, ')
          ..write('nextCatalogNumber: $nextCatalogNumber, ')
          ..write('elevationRounding: $elevationRounding, ')
          ..write('lastBackupAt: $lastBackupAt')
          ..write(')'))
        .toString();
  }
}

class $PlaceRomajiDictTable extends PlaceRomajiDict
    with TableInfo<$PlaceRomajiDictTable, PlaceRomajiEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaceRomajiDictTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _municipalityCodeMeta = const VerificationMeta(
    'municipalityCode',
  );
  @override
  late final GeneratedColumn<String> municipalityCode = GeneratedColumn<String>(
    'municipality_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localityJaMeta = const VerificationMeta(
    'localityJa',
  );
  @override
  late final GeneratedColumn<String> localityJa = GeneratedColumn<String>(
    'locality_ja',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localityEnMeta = const VerificationMeta(
    'localityEn',
  );
  @override
  late final GeneratedColumn<String> localityEn = GeneratedColumn<String>(
    'locality_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    municipalityCode,
    localityJa,
    localityEn,
    useCount,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'place_romaji_dict';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaceRomajiEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('municipality_code')) {
      context.handle(
        _municipalityCodeMeta,
        municipalityCode.isAcceptableOrUnknown(
          data['municipality_code']!,
          _municipalityCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_municipalityCodeMeta);
    }
    if (data.containsKey('locality_ja')) {
      context.handle(
        _localityJaMeta,
        localityJa.isAcceptableOrUnknown(data['locality_ja']!, _localityJaMeta),
      );
    } else if (isInserting) {
      context.missing(_localityJaMeta);
    }
    if (data.containsKey('locality_en')) {
      context.handle(
        _localityEnMeta,
        localityEn.isAcceptableOrUnknown(data['locality_en']!, _localityEnMeta),
      );
    } else if (isInserting) {
      context.missing(_localityEnMeta);
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {municipalityCode, localityJa},
  ];
  @override
  PlaceRomajiEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaceRomajiEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      municipalityCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}municipality_code'],
      )!,
      localityJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locality_ja'],
      )!,
      localityEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locality_en'],
      )!,
      useCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_count'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaceRomajiDictTable createAlias(String alias) {
    return $PlaceRomajiDictTable(attachedDatabase, alias);
  }
}

class PlaceRomajiEntry extends DataClass
    implements Insertable<PlaceRomajiEntry> {
  final int id;
  final String municipalityCode;
  final String localityJa;
  final String localityEn;
  final int useCount;
  final DateTime updatedAt;
  const PlaceRomajiEntry({
    required this.id,
    required this.municipalityCode,
    required this.localityJa,
    required this.localityEn,
    required this.useCount,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['municipality_code'] = Variable<String>(municipalityCode);
    map['locality_ja'] = Variable<String>(localityJa);
    map['locality_en'] = Variable<String>(localityEn);
    map['use_count'] = Variable<int>(useCount);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaceRomajiDictCompanion toCompanion(bool nullToAbsent) {
    return PlaceRomajiDictCompanion(
      id: Value(id),
      municipalityCode: Value(municipalityCode),
      localityJa: Value(localityJa),
      localityEn: Value(localityEn),
      useCount: Value(useCount),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaceRomajiEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaceRomajiEntry(
      id: serializer.fromJson<int>(json['id']),
      municipalityCode: serializer.fromJson<String>(json['municipalityCode']),
      localityJa: serializer.fromJson<String>(json['localityJa']),
      localityEn: serializer.fromJson<String>(json['localityEn']),
      useCount: serializer.fromJson<int>(json['useCount']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'municipalityCode': serializer.toJson<String>(municipalityCode),
      'localityJa': serializer.toJson<String>(localityJa),
      'localityEn': serializer.toJson<String>(localityEn),
      'useCount': serializer.toJson<int>(useCount),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlaceRomajiEntry copyWith({
    int? id,
    String? municipalityCode,
    String? localityJa,
    String? localityEn,
    int? useCount,
    DateTime? updatedAt,
  }) => PlaceRomajiEntry(
    id: id ?? this.id,
    municipalityCode: municipalityCode ?? this.municipalityCode,
    localityJa: localityJa ?? this.localityJa,
    localityEn: localityEn ?? this.localityEn,
    useCount: useCount ?? this.useCount,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlaceRomajiEntry copyWithCompanion(PlaceRomajiDictCompanion data) {
    return PlaceRomajiEntry(
      id: data.id.present ? data.id.value : this.id,
      municipalityCode: data.municipalityCode.present
          ? data.municipalityCode.value
          : this.municipalityCode,
      localityJa: data.localityJa.present
          ? data.localityJa.value
          : this.localityJa,
      localityEn: data.localityEn.present
          ? data.localityEn.value
          : this.localityEn,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaceRomajiEntry(')
          ..write('id: $id, ')
          ..write('municipalityCode: $municipalityCode, ')
          ..write('localityJa: $localityJa, ')
          ..write('localityEn: $localityEn, ')
          ..write('useCount: $useCount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    municipalityCode,
    localityJa,
    localityEn,
    useCount,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaceRomajiEntry &&
          other.id == this.id &&
          other.municipalityCode == this.municipalityCode &&
          other.localityJa == this.localityJa &&
          other.localityEn == this.localityEn &&
          other.useCount == this.useCount &&
          other.updatedAt == this.updatedAt);
}

class PlaceRomajiDictCompanion extends UpdateCompanion<PlaceRomajiEntry> {
  final Value<int> id;
  final Value<String> municipalityCode;
  final Value<String> localityJa;
  final Value<String> localityEn;
  final Value<int> useCount;
  final Value<DateTime> updatedAt;
  const PlaceRomajiDictCompanion({
    this.id = const Value.absent(),
    this.municipalityCode = const Value.absent(),
    this.localityJa = const Value.absent(),
    this.localityEn = const Value.absent(),
    this.useCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PlaceRomajiDictCompanion.insert({
    this.id = const Value.absent(),
    required String municipalityCode,
    required String localityJa,
    required String localityEn,
    this.useCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : municipalityCode = Value(municipalityCode),
       localityJa = Value(localityJa),
       localityEn = Value(localityEn);
  static Insertable<PlaceRomajiEntry> custom({
    Expression<int>? id,
    Expression<String>? municipalityCode,
    Expression<String>? localityJa,
    Expression<String>? localityEn,
    Expression<int>? useCount,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (municipalityCode != null) 'municipality_code': municipalityCode,
      if (localityJa != null) 'locality_ja': localityJa,
      if (localityEn != null) 'locality_en': localityEn,
      if (useCount != null) 'use_count': useCount,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PlaceRomajiDictCompanion copyWith({
    Value<int>? id,
    Value<String>? municipalityCode,
    Value<String>? localityJa,
    Value<String>? localityEn,
    Value<int>? useCount,
    Value<DateTime>? updatedAt,
  }) {
    return PlaceRomajiDictCompanion(
      id: id ?? this.id,
      municipalityCode: municipalityCode ?? this.municipalityCode,
      localityJa: localityJa ?? this.localityJa,
      localityEn: localityEn ?? this.localityEn,
      useCount: useCount ?? this.useCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (municipalityCode.present) {
      map['municipality_code'] = Variable<String>(municipalityCode.value);
    }
    if (localityJa.present) {
      map['locality_ja'] = Variable<String>(localityJa.value);
    }
    if (localityEn.present) {
      map['locality_en'] = Variable<String>(localityEn.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaceRomajiDictCompanion(')
          ..write('id: $id, ')
          ..write('municipalityCode: $municipalityCode, ')
          ..write('localityJa: $localityJa, ')
          ..write('localityEn: $localityEn, ')
          ..write('useCount: $useCount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalitiesTable localities = $LocalitiesTable(this);
  late final $CollectionEventsTable collectionEvents = $CollectionEventsTable(
    this,
  );
  late final $SpecimensTable specimens = $SpecimensTable(this);
  late final $IdentificationsTable identifications = $IdentificationsTable(
    this,
  );
  late final $EnrichmentQueueTable enrichmentQueue = $EnrichmentQueueTable(
    this,
  );
  late final $DraftsTable drafts = $DraftsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $PlaceRomajiDictTable placeRomajiDict = $PlaceRomajiDictTable(
    this,
  );
  late final Index idxLocalitiesKey = Index(
    'idx_localities_key',
    'CREATE INDEX idx_localities_key ON localities (lat_e4, lon_e4)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localities,
    collectionEvents,
    specimens,
    identifications,
    enrichmentQueue,
    drafts,
    appSettings,
    placeRomajiDict,
    idxLocalitiesKey,
  ];
}

typedef $$LocalitiesTableCreateCompanionBuilder = LocalitiesCompanion Function({
  Value<int> id,
  required double latitude,
  required double longitude,
  required int latE4,
  required int lonE4,
  Value<double?> accuracyMeters,
  Value<bool> isManualPosition,
  Value<double?> elevationMeters,
  required FetchStatus elevationStatus,
  Value<String> country,
  Value<String?> municipalityCode,
  Value<String?> prefectureJa,
  Value<String?> countyJa,
  Value<String?> municipalityJa,
  Value<String?> localityJa,
  Value<String?> prefectureEn,
  Value<String?> countyEn,
  Value<String?> municipalityEn,
  Value<String?> localityEn,
  required FetchStatus placeStatus,
  Value<DateTime> createdAt,
});
typedef $$LocalitiesTableUpdateCompanionBuilder = LocalitiesCompanion Function({
  Value<int> id,
  Value<double> latitude,
  Value<double> longitude,
  Value<int> latE4,
  Value<int> lonE4,
  Value<double?> accuracyMeters,
  Value<bool> isManualPosition,
  Value<double?> elevationMeters,
  Value<FetchStatus> elevationStatus,
  Value<String> country,
  Value<String?> municipalityCode,
  Value<String?> prefectureJa,
  Value<String?> countyJa,
  Value<String?> municipalityJa,
  Value<String?> localityJa,
  Value<String?> prefectureEn,
  Value<String?> countyEn,
  Value<String?> municipalityEn,
  Value<String?> localityEn,
  Value<FetchStatus> placeStatus,
  Value<DateTime> createdAt,
});

final class $$LocalitiesTableReferences
    extends BaseReferences<_$AppDatabase, $LocalitiesTable, Locality> {
  $$LocalitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CollectionEventsTable, List<CollectionEvent>>
  _collectionEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.collectionEvents,
    aliasName: 'localities__id__collection_events__locality_id',
  );

  $$CollectionEventsTableProcessedTableManager get collectionEventsRefs {
    final manager = $$CollectionEventsTableTableManager(
      $_db,
      $_db.collectionEvents,
    ).filter((f) => f.localityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectionEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EnrichmentQueueTable, List<EnrichmentTask>>
  _enrichmentQueueRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.enrichmentQueue,
    aliasName: 'localities__id__enrichment_queue__locality_id',
  );

  $$EnrichmentQueueTableProcessedTableManager get enrichmentQueueRefs {
    final manager = $$EnrichmentQueueTableTableManager(
      $_db,
      $_db.enrichmentQueue,
    ).filter((f) => f.localityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _enrichmentQueueRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalitiesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalitiesTable> {
  $$LocalitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latE4 => $composableBuilder(
    column: $table.latE4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lonE4 => $composableBuilder(
    column: $table.lonE4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyMeters => $composableBuilder(
    column: $table.accuracyMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isManualPosition => $composableBuilder(
    column: $table.isManualPosition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevationMeters => $composableBuilder(
    column: $table.elevationMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FetchStatus, FetchStatus, String>
  get elevationStatus => $composableBuilder(
    column: $table.elevationStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipalityCode => $composableBuilder(
    column: $table.municipalityCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prefectureJa => $composableBuilder(
    column: $table.prefectureJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countyJa => $composableBuilder(
    column: $table.countyJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipalityJa => $composableBuilder(
    column: $table.municipalityJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localityJa => $composableBuilder(
    column: $table.localityJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prefectureEn => $composableBuilder(
    column: $table.prefectureEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countyEn => $composableBuilder(
    column: $table.countyEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipalityEn => $composableBuilder(
    column: $table.municipalityEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localityEn => $composableBuilder(
    column: $table.localityEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FetchStatus, FetchStatus, String>
  get placeStatus => $composableBuilder(
    column: $table.placeStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> collectionEventsRefs(
    Expression<bool> Function($$CollectionEventsTableFilterComposer f) f,
  ) {
    final $$CollectionEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionEvents,
      getReferencedColumn: (t) => t.localityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionEventsTableFilterComposer(
            $db: $db,
            $table: $db.collectionEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> enrichmentQueueRefs(
    Expression<bool> Function($$EnrichmentQueueTableFilterComposer f) f,
  ) {
    final $$EnrichmentQueueTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.enrichmentQueue,
      getReferencedColumn: (t) => t.localityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnrichmentQueueTableFilterComposer(
            $db: $db,
            $table: $db.enrichmentQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalitiesTable> {
  $$LocalitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latE4 => $composableBuilder(
    column: $table.latE4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lonE4 => $composableBuilder(
    column: $table.lonE4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyMeters => $composableBuilder(
    column: $table.accuracyMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isManualPosition => $composableBuilder(
    column: $table.isManualPosition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevationMeters => $composableBuilder(
    column: $table.elevationMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get elevationStatus => $composableBuilder(
    column: $table.elevationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipalityCode => $composableBuilder(
    column: $table.municipalityCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prefectureJa => $composableBuilder(
    column: $table.prefectureJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countyJa => $composableBuilder(
    column: $table.countyJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipalityJa => $composableBuilder(
    column: $table.municipalityJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localityJa => $composableBuilder(
    column: $table.localityJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prefectureEn => $composableBuilder(
    column: $table.prefectureEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countyEn => $composableBuilder(
    column: $table.countyEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipalityEn => $composableBuilder(
    column: $table.municipalityEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localityEn => $composableBuilder(
    column: $table.localityEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placeStatus => $composableBuilder(
    column: $table.placeStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalitiesTable> {
  $$LocalitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get latE4 =>
      $composableBuilder(column: $table.latE4, builder: (column) => column);

  GeneratedColumn<int> get lonE4 =>
      $composableBuilder(column: $table.lonE4, builder: (column) => column);

  GeneratedColumn<double> get accuracyMeters => $composableBuilder(
    column: $table.accuracyMeters,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isManualPosition => $composableBuilder(
    column: $table.isManualPosition,
    builder: (column) => column,
  );

  GeneratedColumn<double> get elevationMeters => $composableBuilder(
    column: $table.elevationMeters,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FetchStatus, String> get elevationStatus =>
      $composableBuilder(
        column: $table.elevationStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get municipalityCode => $composableBuilder(
    column: $table.municipalityCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prefectureJa => $composableBuilder(
    column: $table.prefectureJa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get countyJa =>
      $composableBuilder(column: $table.countyJa, builder: (column) => column);

  GeneratedColumn<String> get municipalityJa => $composableBuilder(
    column: $table.municipalityJa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localityJa => $composableBuilder(
    column: $table.localityJa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prefectureEn => $composableBuilder(
    column: $table.prefectureEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get countyEn =>
      $composableBuilder(column: $table.countyEn, builder: (column) => column);

  GeneratedColumn<String> get municipalityEn => $composableBuilder(
    column: $table.municipalityEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localityEn => $composableBuilder(
    column: $table.localityEn,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FetchStatus, String> get placeStatus =>
      $composableBuilder(
        column: $table.placeStatus,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> collectionEventsRefs<T extends Object>(
    Expression<T> Function($$CollectionEventsTableAnnotationComposer a) f,
  ) {
    final $$CollectionEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionEvents,
      getReferencedColumn: (t) => t.localityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.collectionEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> enrichmentQueueRefs<T extends Object>(
    Expression<T> Function($$EnrichmentQueueTableAnnotationComposer a) f,
  ) {
    final $$EnrichmentQueueTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.enrichmentQueue,
      getReferencedColumn: (t) => t.localityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnrichmentQueueTableAnnotationComposer(
            $db: $db,
            $table: $db.enrichmentQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalitiesTable,
          Locality,
          $$LocalitiesTableFilterComposer,
          $$LocalitiesTableOrderingComposer,
          $$LocalitiesTableAnnotationComposer,
          $$LocalitiesTableCreateCompanionBuilder,
          $$LocalitiesTableUpdateCompanionBuilder,
          (Locality, $$LocalitiesTableReferences),
          Locality,
          PrefetchHooks Function({
            bool collectionEventsRefs,
            bool enrichmentQueueRefs,
          })
        > {
  $$LocalitiesTableTableManager(_$AppDatabase db, $LocalitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<int> latE4 = const Value.absent(),
                Value<int> lonE4 = const Value.absent(),
                Value<double?> accuracyMeters = const Value.absent(),
                Value<bool> isManualPosition = const Value.absent(),
                Value<double?> elevationMeters = const Value.absent(),
                Value<FetchStatus> elevationStatus = const Value.absent(),
                Value<String> country = const Value.absent(),
                Value<String?> municipalityCode = const Value.absent(),
                Value<String?> prefectureJa = const Value.absent(),
                Value<String?> countyJa = const Value.absent(),
                Value<String?> municipalityJa = const Value.absent(),
                Value<String?> localityJa = const Value.absent(),
                Value<String?> prefectureEn = const Value.absent(),
                Value<String?> countyEn = const Value.absent(),
                Value<String?> municipalityEn = const Value.absent(),
                Value<String?> localityEn = const Value.absent(),
                Value<FetchStatus> placeStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocalitiesCompanion(
                id: id,
                latitude: latitude,
                longitude: longitude,
                latE4: latE4,
                lonE4: lonE4,
                accuracyMeters: accuracyMeters,
                isManualPosition: isManualPosition,
                elevationMeters: elevationMeters,
                elevationStatus: elevationStatus,
                country: country,
                municipalityCode: municipalityCode,
                prefectureJa: prefectureJa,
                countyJa: countyJa,
                municipalityJa: municipalityJa,
                localityJa: localityJa,
                prefectureEn: prefectureEn,
                countyEn: countyEn,
                municipalityEn: municipalityEn,
                localityEn: localityEn,
                placeStatus: placeStatus,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double latitude,
                required double longitude,
                required int latE4,
                required int lonE4,
                Value<double?> accuracyMeters = const Value.absent(),
                Value<bool> isManualPosition = const Value.absent(),
                Value<double?> elevationMeters = const Value.absent(),
                required FetchStatus elevationStatus,
                Value<String> country = const Value.absent(),
                Value<String?> municipalityCode = const Value.absent(),
                Value<String?> prefectureJa = const Value.absent(),
                Value<String?> countyJa = const Value.absent(),
                Value<String?> municipalityJa = const Value.absent(),
                Value<String?> localityJa = const Value.absent(),
                Value<String?> prefectureEn = const Value.absent(),
                Value<String?> countyEn = const Value.absent(),
                Value<String?> municipalityEn = const Value.absent(),
                Value<String?> localityEn = const Value.absent(),
                required FetchStatus placeStatus,
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocalitiesCompanion.insert(
                id: id,
                latitude: latitude,
                longitude: longitude,
                latE4: latE4,
                lonE4: lonE4,
                accuracyMeters: accuracyMeters,
                isManualPosition: isManualPosition,
                elevationMeters: elevationMeters,
                elevationStatus: elevationStatus,
                country: country,
                municipalityCode: municipalityCode,
                prefectureJa: prefectureJa,
                countyJa: countyJa,
                municipalityJa: municipalityJa,
                localityJa: localityJa,
                prefectureEn: prefectureEn,
                countyEn: countyEn,
                municipalityEn: municipalityEn,
                localityEn: localityEn,
                placeStatus: placeStatus,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalitiesTable, Locality>(table),
                  $$LocalitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({collectionEventsRefs = false, enrichmentQueueRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (collectionEventsRefs) db.collectionEvents,
                    if (enrichmentQueueRefs) db.enrichmentQueue,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (collectionEventsRefs)
                        await $_getPrefetchedData<
                          Locality,
                          $LocalitiesTable,
                          CollectionEvent
                        >(
                          currentTable: table,
                          referencedTable: $$LocalitiesTableReferences
                              ._collectionEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).collectionEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localityId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (enrichmentQueueRefs)
                        await $_getPrefetchedData<
                          Locality,
                          $LocalitiesTable,
                          EnrichmentTask
                        >(
                          currentTable: table,
                          referencedTable: $$LocalitiesTableReferences
                              ._enrichmentQueueRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).enrichmentQueueRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.localityId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LocalitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalitiesTable,
      Locality,
      $$LocalitiesTableFilterComposer,
      $$LocalitiesTableOrderingComposer,
      $$LocalitiesTableAnnotationComposer,
      $$LocalitiesTableCreateCompanionBuilder,
      $$LocalitiesTableUpdateCompanionBuilder,
      (Locality, $$LocalitiesTableReferences),
      Locality,
      PrefetchHooks Function({
        bool collectionEventsRefs,
        bool enrichmentQueueRefs,
      })
    >;
typedef $$CollectionEventsTableCreateCompanionBuilder =
    CollectionEventsCompanion Function({
      Value<int> id,
      required int localityId,
      required CalendarDate startDate,
      required CalendarDate endDate,
      required DateTime recordedAt,
      required SamplingMethod samplingMethod,
      Value<String?> samplingMethodOther,
      Value<String?> lightSource,
      Value<String?> bait,
      Value<String?> habitat,
      Value<String?> hostPlant,
      Value<String?> collector,
      Value<DateTime> createdAt,
    });
typedef $$CollectionEventsTableUpdateCompanionBuilder =
    CollectionEventsCompanion Function({
      Value<int> id,
      Value<int> localityId,
      Value<CalendarDate> startDate,
      Value<CalendarDate> endDate,
      Value<DateTime> recordedAt,
      Value<SamplingMethod> samplingMethod,
      Value<String?> samplingMethodOther,
      Value<String?> lightSource,
      Value<String?> bait,
      Value<String?> habitat,
      Value<String?> hostPlant,
      Value<String?> collector,
      Value<DateTime> createdAt,
    });

final class $$CollectionEventsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CollectionEventsTable, CollectionEvent> {
  $$CollectionEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalitiesTable _localityIdTable(_$AppDatabase db) => db.localities
      .createAlias('collection_events__locality_id__localities__id');

  $$LocalitiesTableProcessedTableManager get localityId {
    final $_column = $_itemColumn<int>('locality_id')!;

    final manager = $$LocalitiesTableTableManager(
      $_db,
      $_db.localities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SpecimensTable, List<Specimen>>
  _specimensRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.specimens,
    aliasName: 'collection_events__id__specimens__collection_event_id',
  );

  $$SpecimensTableProcessedTableManager get specimensRefs {
    final manager = $$SpecimensTableTableManager(
      $_db,
      $_db.specimens,
    ).filter((f) => f.collectionEventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_specimensRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CollectionEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionEventsTable> {
  $$CollectionEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate, CalendarDate, String>
  get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate, CalendarDate, String>
  get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SamplingMethod, SamplingMethod, String>
  get samplingMethod => $composableBuilder(
    column: $table.samplingMethod,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get samplingMethodOther => $composableBuilder(
    column: $table.samplingMethodOther,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lightSource => $composableBuilder(
    column: $table.lightSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bait => $composableBuilder(
    column: $table.bait,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get habitat => $composableBuilder(
    column: $table.habitat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hostPlant => $composableBuilder(
    column: $table.hostPlant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collector => $composableBuilder(
    column: $table.collector,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalitiesTableFilterComposer get localityId {
    final $$LocalitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localityId,
      referencedTable: $db.localities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalitiesTableFilterComposer(
            $db: $db,
            $table: $db.localities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> specimensRefs(
    Expression<bool> Function($$SpecimensTableFilterComposer f) f,
  ) {
    final $$SpecimensTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.specimens,
      getReferencedColumn: (t) => t.collectionEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpecimensTableFilterComposer(
            $db: $db,
            $table: $db.specimens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionEventsTable> {
  $$CollectionEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get samplingMethod => $composableBuilder(
    column: $table.samplingMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get samplingMethodOther => $composableBuilder(
    column: $table.samplingMethodOther,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lightSource => $composableBuilder(
    column: $table.lightSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bait => $composableBuilder(
    column: $table.bait,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get habitat => $composableBuilder(
    column: $table.habitat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hostPlant => $composableBuilder(
    column: $table.hostPlant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collector => $composableBuilder(
    column: $table.collector,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalitiesTableOrderingComposer get localityId {
    final $$LocalitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localityId,
      referencedTable: $db.localities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalitiesTableOrderingComposer(
            $db: $db,
            $table: $db.localities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionEventsTable> {
  $$CollectionEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarDate, String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarDate, String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SamplingMethod, String> get samplingMethod =>
      $composableBuilder(
        column: $table.samplingMethod,
        builder: (column) => column,
      );

  GeneratedColumn<String> get samplingMethodOther => $composableBuilder(
    column: $table.samplingMethodOther,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lightSource => $composableBuilder(
    column: $table.lightSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bait =>
      $composableBuilder(column: $table.bait, builder: (column) => column);

  GeneratedColumn<String> get habitat =>
      $composableBuilder(column: $table.habitat, builder: (column) => column);

  GeneratedColumn<String> get hostPlant =>
      $composableBuilder(column: $table.hostPlant, builder: (column) => column);

  GeneratedColumn<String> get collector =>
      $composableBuilder(column: $table.collector, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LocalitiesTableAnnotationComposer get localityId {
    final $$LocalitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localityId,
      referencedTable: $db.localities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.localities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> specimensRefs<T extends Object>(
    Expression<T> Function($$SpecimensTableAnnotationComposer a) f,
  ) {
    final $$SpecimensTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.specimens,
      getReferencedColumn: (t) => t.collectionEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpecimensTableAnnotationComposer(
            $db: $db,
            $table: $db.specimens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionEventsTable,
          CollectionEvent,
          $$CollectionEventsTableFilterComposer,
          $$CollectionEventsTableOrderingComposer,
          $$CollectionEventsTableAnnotationComposer,
          $$CollectionEventsTableCreateCompanionBuilder,
          $$CollectionEventsTableUpdateCompanionBuilder,
          (CollectionEvent, $$CollectionEventsTableReferences),
          CollectionEvent,
          PrefetchHooks Function({bool localityId, bool specimensRefs})
        > {
  $$CollectionEventsTableTableManager(
    _$AppDatabase db,
    $CollectionEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> localityId = const Value.absent(),
                Value<CalendarDate> startDate = const Value.absent(),
                Value<CalendarDate> endDate = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<SamplingMethod> samplingMethod = const Value.absent(),
                Value<String?> samplingMethodOther = const Value.absent(),
                Value<String?> lightSource = const Value.absent(),
                Value<String?> bait = const Value.absent(),
                Value<String?> habitat = const Value.absent(),
                Value<String?> hostPlant = const Value.absent(),
                Value<String?> collector = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CollectionEventsCompanion(
                id: id,
                localityId: localityId,
                startDate: startDate,
                endDate: endDate,
                recordedAt: recordedAt,
                samplingMethod: samplingMethod,
                samplingMethodOther: samplingMethodOther,
                lightSource: lightSource,
                bait: bait,
                habitat: habitat,
                hostPlant: hostPlant,
                collector: collector,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int localityId,
                required CalendarDate startDate,
                required CalendarDate endDate,
                required DateTime recordedAt,
                required SamplingMethod samplingMethod,
                Value<String?> samplingMethodOther = const Value.absent(),
                Value<String?> lightSource = const Value.absent(),
                Value<String?> bait = const Value.absent(),
                Value<String?> habitat = const Value.absent(),
                Value<String?> hostPlant = const Value.absent(),
                Value<String?> collector = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CollectionEventsCompanion.insert(
                id: id,
                localityId: localityId,
                startDate: startDate,
                endDate: endDate,
                recordedAt: recordedAt,
                samplingMethod: samplingMethod,
                samplingMethodOther: samplingMethodOther,
                lightSource: lightSource,
                bait: bait,
                habitat: habitat,
                hostPlant: hostPlant,
                collector: collector,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionEventsTable, CollectionEvent>(table),
                  $$CollectionEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localityId = false, specimensRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (specimensRefs) db.specimens],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localityId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localityId,
                        referencedTable: $$CollectionEventsTableReferences
                            ._localityIdTable(db),
                        referencedColumn: $$CollectionEventsTableReferences
                            ._localityIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (specimensRefs)
                    await $_getPrefetchedData<
                      CollectionEvent,
                      $CollectionEventsTable,
                      Specimen
                    >(
                      currentTable: table,
                      referencedTable: $$CollectionEventsTableReferences
                          ._specimensRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CollectionEventsTableReferences(
                            db,
                            table,
                            p0,
                          ).specimensRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.collectionEventId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CollectionEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionEventsTable,
      CollectionEvent,
      $$CollectionEventsTableFilterComposer,
      $$CollectionEventsTableOrderingComposer,
      $$CollectionEventsTableAnnotationComposer,
      $$CollectionEventsTableCreateCompanionBuilder,
      $$CollectionEventsTableUpdateCompanionBuilder,
      (CollectionEvent, $$CollectionEventsTableReferences),
      CollectionEvent,
      PrefetchHooks Function({bool localityId, bool specimensRefs})
    >;
typedef $$SpecimensTableCreateCompanionBuilder = SpecimensCompanion Function({
  Value<int> id,
  required int collectionEventId,
  required int catalogNumber,
  required String catalogText,
  Value<Sex?> sex,
  Value<String?> remarks,
  Value<DateTime?> printedAt,
  Value<String?> printedElevation,
  Value<String?> printedPlace,
  Value<DateTime?> deletedAt,
  Value<DateTime> createdAt,
});
typedef $$SpecimensTableUpdateCompanionBuilder = SpecimensCompanion Function({
  Value<int> id,
  Value<int> collectionEventId,
  Value<int> catalogNumber,
  Value<String> catalogText,
  Value<Sex?> sex,
  Value<String?> remarks,
  Value<DateTime?> printedAt,
  Value<String?> printedElevation,
  Value<String?> printedPlace,
  Value<DateTime?> deletedAt,
  Value<DateTime> createdAt,
});

final class $$SpecimensTableReferences
    extends BaseReferences<_$AppDatabase, $SpecimensTable, Specimen> {
  $$SpecimensTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CollectionEventsTable _collectionEventIdTable(_$AppDatabase db) => db
      .collectionEvents
      .createAlias('specimens__collection_event_id__collection_events__id');

  $$CollectionEventsTableProcessedTableManager get collectionEventId {
    final $_column = $_itemColumn<int>('collection_event_id')!;

    final manager = $$CollectionEventsTableTableManager(
      $_db,
      $_db.collectionEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionEventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$IdentificationsTable, List<Identification>>
  _identificationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.identifications,
    aliasName: 'specimens__id__identifications__specimen_id',
  );

  $$IdentificationsTableProcessedTableManager get identificationsRefs {
    final manager = $$IdentificationsTableTableManager(
      $_db,
      $_db.identifications,
    ).filter((f) => f.specimenId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _identificationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SpecimensTableFilterComposer
    extends Composer<_$AppDatabase, $SpecimensTable> {
  $$SpecimensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get catalogNumber => $composableBuilder(
    column: $table.catalogNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogText => $composableBuilder(
    column: $table.catalogText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Sex?, Sex, String> get sex =>
      $composableBuilder(
        column: $table.sex,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get printedAt => $composableBuilder(
    column: $table.printedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get printedElevation => $composableBuilder(
    column: $table.printedElevation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get printedPlace => $composableBuilder(
    column: $table.printedPlace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CollectionEventsTableFilterComposer get collectionEventId {
    final $$CollectionEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionEventId,
      referencedTable: $db.collectionEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionEventsTableFilterComposer(
            $db: $db,
            $table: $db.collectionEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> identificationsRefs(
    Expression<bool> Function($$IdentificationsTableFilterComposer f) f,
  ) {
    final $$IdentificationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.identifications,
      getReferencedColumn: (t) => t.specimenId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IdentificationsTableFilterComposer(
            $db: $db,
            $table: $db.identifications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SpecimensTableOrderingComposer
    extends Composer<_$AppDatabase, $SpecimensTable> {
  $$SpecimensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get catalogNumber => $composableBuilder(
    column: $table.catalogNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogText => $composableBuilder(
    column: $table.catalogText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get printedAt => $composableBuilder(
    column: $table.printedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get printedElevation => $composableBuilder(
    column: $table.printedElevation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get printedPlace => $composableBuilder(
    column: $table.printedPlace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CollectionEventsTableOrderingComposer get collectionEventId {
    final $$CollectionEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionEventId,
      referencedTable: $db.collectionEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionEventsTableOrderingComposer(
            $db: $db,
            $table: $db.collectionEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpecimensTableAnnotationComposer
    extends Composer<_$AppDatabase, $SpecimensTable> {
  $$SpecimensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get catalogNumber => $composableBuilder(
    column: $table.catalogNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catalogText => $composableBuilder(
    column: $table.catalogText,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Sex?, String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<DateTime> get printedAt =>
      $composableBuilder(column: $table.printedAt, builder: (column) => column);

  GeneratedColumn<String> get printedElevation => $composableBuilder(
    column: $table.printedElevation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get printedPlace => $composableBuilder(
    column: $table.printedPlace,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CollectionEventsTableAnnotationComposer get collectionEventId {
    final $$CollectionEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionEventId,
      referencedTable: $db.collectionEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.collectionEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> identificationsRefs<T extends Object>(
    Expression<T> Function($$IdentificationsTableAnnotationComposer a) f,
  ) {
    final $$IdentificationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.identifications,
      getReferencedColumn: (t) => t.specimenId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IdentificationsTableAnnotationComposer(
            $db: $db,
            $table: $db.identifications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SpecimensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SpecimensTable,
          Specimen,
          $$SpecimensTableFilterComposer,
          $$SpecimensTableOrderingComposer,
          $$SpecimensTableAnnotationComposer,
          $$SpecimensTableCreateCompanionBuilder,
          $$SpecimensTableUpdateCompanionBuilder,
          (Specimen, $$SpecimensTableReferences),
          Specimen,
          PrefetchHooks Function({
            bool collectionEventId,
            bool identificationsRefs,
          })
        > {
  $$SpecimensTableTableManager(_$AppDatabase db, $SpecimensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpecimensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpecimensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpecimensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> collectionEventId = const Value.absent(),
                Value<int> catalogNumber = const Value.absent(),
                Value<String> catalogText = const Value.absent(),
                Value<Sex?> sex = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<DateTime?> printedAt = const Value.absent(),
                Value<String?> printedElevation = const Value.absent(),
                Value<String?> printedPlace = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SpecimensCompanion(
                id: id,
                collectionEventId: collectionEventId,
                catalogNumber: catalogNumber,
                catalogText: catalogText,
                sex: sex,
                remarks: remarks,
                printedAt: printedAt,
                printedElevation: printedElevation,
                printedPlace: printedPlace,
                deletedAt: deletedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int collectionEventId,
                required int catalogNumber,
                required String catalogText,
                Value<Sex?> sex = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<DateTime?> printedAt = const Value.absent(),
                Value<String?> printedElevation = const Value.absent(),
                Value<String?> printedPlace = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SpecimensCompanion.insert(
                id: id,
                collectionEventId: collectionEventId,
                catalogNumber: catalogNumber,
                catalogText: catalogText,
                sex: sex,
                remarks: remarks,
                printedAt: printedAt,
                printedElevation: printedElevation,
                printedPlace: printedPlace,
                deletedAt: deletedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SpecimensTable, Specimen>(table),
                  $$SpecimensTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({collectionEventId = false, identificationsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (identificationsRefs) db.identifications,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (collectionEventId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.collectionEventId,
                            referencedTable: $$SpecimensTableReferences
                                ._collectionEventIdTable(db),
                            referencedColumn: $$SpecimensTableReferences
                                ._collectionEventIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (identificationsRefs)
                        await $_getPrefetchedData<
                          Specimen,
                          $SpecimensTable,
                          Identification
                        >(
                          currentTable: table,
                          referencedTable: $$SpecimensTableReferences
                              ._identificationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SpecimensTableReferences(
                                db,
                                table,
                                p0,
                              ).identificationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.specimenId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SpecimensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SpecimensTable,
      Specimen,
      $$SpecimensTableFilterComposer,
      $$SpecimensTableOrderingComposer,
      $$SpecimensTableAnnotationComposer,
      $$SpecimensTableCreateCompanionBuilder,
      $$SpecimensTableUpdateCompanionBuilder,
      (Specimen, $$SpecimensTableReferences),
      Specimen,
      PrefetchHooks Function({bool collectionEventId, bool identificationsRefs})
    >;
typedef $$IdentificationsTableCreateCompanionBuilder =
    IdentificationsCompanion Function({
      Value<int> id,
      required int specimenId,
      Value<String?> vernacularName,
      Value<String?> genus,
      Value<String?> species,
      Value<String?> subspecies,
      Value<String?> authorship,
      Value<String?> identifiedBy,
      Value<CalendarDate?> dateIdentified,
      required IdentificationStatus status,
      Value<DateTime> createdAt,
    });
typedef $$IdentificationsTableUpdateCompanionBuilder =
    IdentificationsCompanion Function({
      Value<int> id,
      Value<int> specimenId,
      Value<String?> vernacularName,
      Value<String?> genus,
      Value<String?> species,
      Value<String?> subspecies,
      Value<String?> authorship,
      Value<String?> identifiedBy,
      Value<CalendarDate?> dateIdentified,
      Value<IdentificationStatus> status,
      Value<DateTime> createdAt,
    });

final class $$IdentificationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $IdentificationsTable, Identification> {
  $$IdentificationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SpecimensTable _specimenIdTable(_$AppDatabase db) =>
      db.specimens.createAlias('identifications__specimen_id__specimens__id');

  $$SpecimensTableProcessedTableManager get specimenId {
    final $_column = $_itemColumn<int>('specimen_id')!;

    final manager = $$SpecimensTableTableManager(
      $_db,
      $_db.specimens,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_specimenIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IdentificationsTableFilterComposer
    extends Composer<_$AppDatabase, $IdentificationsTable> {
  $$IdentificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vernacularName => $composableBuilder(
    column: $table.vernacularName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genus => $composableBuilder(
    column: $table.genus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get species => $composableBuilder(
    column: $table.species,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subspecies => $composableBuilder(
    column: $table.subspecies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorship => $composableBuilder(
    column: $table.authorship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identifiedBy => $composableBuilder(
    column: $table.identifiedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate?, CalendarDate, String>
  get dateIdentified => $composableBuilder(
    column: $table.dateIdentified,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    IdentificationStatus,
    IdentificationStatus,
    String
  >
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SpecimensTableFilterComposer get specimenId {
    final $$SpecimensTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.specimenId,
      referencedTable: $db.specimens,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpecimensTableFilterComposer(
            $db: $db,
            $table: $db.specimens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IdentificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $IdentificationsTable> {
  $$IdentificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vernacularName => $composableBuilder(
    column: $table.vernacularName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genus => $composableBuilder(
    column: $table.genus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get species => $composableBuilder(
    column: $table.species,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subspecies => $composableBuilder(
    column: $table.subspecies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorship => $composableBuilder(
    column: $table.authorship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identifiedBy => $composableBuilder(
    column: $table.identifiedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateIdentified => $composableBuilder(
    column: $table.dateIdentified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SpecimensTableOrderingComposer get specimenId {
    final $$SpecimensTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.specimenId,
      referencedTable: $db.specimens,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpecimensTableOrderingComposer(
            $db: $db,
            $table: $db.specimens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IdentificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IdentificationsTable> {
  $$IdentificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vernacularName => $composableBuilder(
    column: $table.vernacularName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genus =>
      $composableBuilder(column: $table.genus, builder: (column) => column);

  GeneratedColumn<String> get species =>
      $composableBuilder(column: $table.species, builder: (column) => column);

  GeneratedColumn<String> get subspecies => $composableBuilder(
    column: $table.subspecies,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorship => $composableBuilder(
    column: $table.authorship,
    builder: (column) => column,
  );

  GeneratedColumn<String> get identifiedBy => $composableBuilder(
    column: $table.identifiedBy,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CalendarDate?, String> get dateIdentified =>
      $composableBuilder(
        column: $table.dateIdentified,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<IdentificationStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SpecimensTableAnnotationComposer get specimenId {
    final $$SpecimensTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.specimenId,
      referencedTable: $db.specimens,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpecimensTableAnnotationComposer(
            $db: $db,
            $table: $db.specimens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IdentificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IdentificationsTable,
          Identification,
          $$IdentificationsTableFilterComposer,
          $$IdentificationsTableOrderingComposer,
          $$IdentificationsTableAnnotationComposer,
          $$IdentificationsTableCreateCompanionBuilder,
          $$IdentificationsTableUpdateCompanionBuilder,
          (Identification, $$IdentificationsTableReferences),
          Identification,
          PrefetchHooks Function({bool specimenId})
        > {
  $$IdentificationsTableTableManager(
    _$AppDatabase db,
    $IdentificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdentificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdentificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdentificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> specimenId = const Value.absent(),
                Value<String?> vernacularName = const Value.absent(),
                Value<String?> genus = const Value.absent(),
                Value<String?> species = const Value.absent(),
                Value<String?> subspecies = const Value.absent(),
                Value<String?> authorship = const Value.absent(),
                Value<String?> identifiedBy = const Value.absent(),
                Value<CalendarDate?> dateIdentified = const Value.absent(),
                Value<IdentificationStatus> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => IdentificationsCompanion(
                id: id,
                specimenId: specimenId,
                vernacularName: vernacularName,
                genus: genus,
                species: species,
                subspecies: subspecies,
                authorship: authorship,
                identifiedBy: identifiedBy,
                dateIdentified: dateIdentified,
                status: status,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int specimenId,
                Value<String?> vernacularName = const Value.absent(),
                Value<String?> genus = const Value.absent(),
                Value<String?> species = const Value.absent(),
                Value<String?> subspecies = const Value.absent(),
                Value<String?> authorship = const Value.absent(),
                Value<String?> identifiedBy = const Value.absent(),
                Value<CalendarDate?> dateIdentified = const Value.absent(),
                required IdentificationStatus status,
                Value<DateTime> createdAt = const Value.absent(),
              }) => IdentificationsCompanion.insert(
                id: id,
                specimenId: specimenId,
                vernacularName: vernacularName,
                genus: genus,
                species: species,
                subspecies: subspecies,
                authorship: authorship,
                identifiedBy: identifiedBy,
                dateIdentified: dateIdentified,
                status: status,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IdentificationsTable, Identification>(table),
                  $$IdentificationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({specimenId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (specimenId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.specimenId,
                        referencedTable: $$IdentificationsTableReferences
                            ._specimenIdTable(db),
                        referencedColumn: $$IdentificationsTableReferences
                            ._specimenIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IdentificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IdentificationsTable,
      Identification,
      $$IdentificationsTableFilterComposer,
      $$IdentificationsTableOrderingComposer,
      $$IdentificationsTableAnnotationComposer,
      $$IdentificationsTableCreateCompanionBuilder,
      $$IdentificationsTableUpdateCompanionBuilder,
      (Identification, $$IdentificationsTableReferences),
      Identification,
      PrefetchHooks Function({bool specimenId})
    >;
typedef $$EnrichmentQueueTableCreateCompanionBuilder =
    EnrichmentQueueCompanion Function({
      Value<int> id,
      required int localityId,
      required EnrichmentKind kind,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });
typedef $$EnrichmentQueueTableUpdateCompanionBuilder =
    EnrichmentQueueCompanion Function({
      Value<int> id,
      Value<int> localityId,
      Value<EnrichmentKind> kind,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });

final class $$EnrichmentQueueTableReferences
    extends
        BaseReferences<_$AppDatabase, $EnrichmentQueueTable, EnrichmentTask> {
  $$EnrichmentQueueTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalitiesTable _localityIdTable(_$AppDatabase db) => db.localities
      .createAlias('enrichment_queue__locality_id__localities__id');

  $$LocalitiesTableProcessedTableManager get localityId {
    final $_column = $_itemColumn<int>('locality_id')!;

    final manager = $$LocalitiesTableTableManager(
      $_db,
      $_db.localities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EnrichmentQueueTableFilterComposer
    extends Composer<_$AppDatabase, $EnrichmentQueueTable> {
  $$EnrichmentQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EnrichmentKind, EnrichmentKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalitiesTableFilterComposer get localityId {
    final $$LocalitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localityId,
      referencedTable: $db.localities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalitiesTableFilterComposer(
            $db: $db,
            $table: $db.localities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnrichmentQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $EnrichmentQueueTable> {
  $$EnrichmentQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalitiesTableOrderingComposer get localityId {
    final $$LocalitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localityId,
      referencedTable: $db.localities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalitiesTableOrderingComposer(
            $db: $db,
            $table: $db.localities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnrichmentQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnrichmentQueueTable> {
  $$EnrichmentQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EnrichmentKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LocalitiesTableAnnotationComposer get localityId {
    final $$LocalitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localityId,
      referencedTable: $db.localities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.localities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnrichmentQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EnrichmentQueueTable,
          EnrichmentTask,
          $$EnrichmentQueueTableFilterComposer,
          $$EnrichmentQueueTableOrderingComposer,
          $$EnrichmentQueueTableAnnotationComposer,
          $$EnrichmentQueueTableCreateCompanionBuilder,
          $$EnrichmentQueueTableUpdateCompanionBuilder,
          (EnrichmentTask, $$EnrichmentQueueTableReferences),
          EnrichmentTask,
          PrefetchHooks Function({bool localityId})
        > {
  $$EnrichmentQueueTableTableManager(
    _$AppDatabase db,
    $EnrichmentQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnrichmentQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnrichmentQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnrichmentQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> localityId = const Value.absent(),
                Value<EnrichmentKind> kind = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EnrichmentQueueCompanion(
                id: id,
                localityId: localityId,
                kind: kind,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int localityId,
                required EnrichmentKind kind,
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EnrichmentQueueCompanion.insert(
                id: id,
                localityId: localityId,
                kind: kind,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EnrichmentQueueTable, EnrichmentTask>(table),
                  $$EnrichmentQueueTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localityId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localityId,
                        referencedTable: $$EnrichmentQueueTableReferences
                            ._localityIdTable(db),
                        referencedColumn: $$EnrichmentQueueTableReferences
                            ._localityIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EnrichmentQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EnrichmentQueueTable,
      EnrichmentTask,
      $$EnrichmentQueueTableFilterComposer,
      $$EnrichmentQueueTableOrderingComposer,
      $$EnrichmentQueueTableAnnotationComposer,
      $$EnrichmentQueueTableCreateCompanionBuilder,
      $$EnrichmentQueueTableUpdateCompanionBuilder,
      (EnrichmentTask, $$EnrichmentQueueTableReferences),
      EnrichmentTask,
      PrefetchHooks Function({bool localityId})
    >;
typedef $$DraftsTableCreateCompanionBuilder = DraftsCompanion Function({
  Value<int> id,
  required String formJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$DraftsTableUpdateCompanionBuilder = DraftsCompanion Function({
  Value<int> id,
  Value<String> formJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$DraftsTableFilterComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formJson => $composableBuilder(
    column: $table.formJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formJson => $composableBuilder(
    column: $table.formJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get formJson =>
      $composableBuilder(column: $table.formJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DraftsTable,
          Draft,
          $$DraftsTableFilterComposer,
          $$DraftsTableOrderingComposer,
          $$DraftsTableAnnotationComposer,
          $$DraftsTableCreateCompanionBuilder,
          $$DraftsTableUpdateCompanionBuilder,
          (Draft, BaseReferences<_$AppDatabase, $DraftsTable, Draft>),
          Draft,
          PrefetchHooks Function()
        > {
  $$DraftsTableTableManager(_$AppDatabase db, $DraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> formJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DraftsCompanion(
                id: id,
                formJson: formJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String formJson,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DraftsCompanion.insert(
                id: id,
                formJson: formJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DraftsTable, Draft>(table),
                  BaseReferences<_$AppDatabase, $DraftsTable, Draft>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DraftsTable,
      Draft,
      $$DraftsTableFilterComposer,
      $$DraftsTableOrderingComposer,
      $$DraftsTableAnnotationComposer,
      $$DraftsTableCreateCompanionBuilder,
      $$DraftsTableUpdateCompanionBuilder,
      (Draft, BaseReferences<_$AppDatabase, $DraftsTable, Draft>),
      Draft,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> collectorName,
      Value<String?> lastIdentifier,
      Value<String> catalogPrefix,
      Value<int> catalogDigits,
      Value<int?> nextCatalogNumber,
      Value<ElevationRounding> elevationRounding,
      Value<DateTime?> lastBackupAt,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> collectorName,
      Value<String?> lastIdentifier,
      Value<String> catalogPrefix,
      Value<int> catalogDigits,
      Value<int?> nextCatalogNumber,
      Value<ElevationRounding> elevationRounding,
      Value<DateTime?> lastBackupAt,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectorName => $composableBuilder(
    column: $table.collectorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastIdentifier => $composableBuilder(
    column: $table.lastIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogPrefix => $composableBuilder(
    column: $table.catalogPrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get catalogDigits => $composableBuilder(
    column: $table.catalogDigits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextCatalogNumber => $composableBuilder(
    column: $table.nextCatalogNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ElevationRounding, ElevationRounding, String>
  get elevationRounding => $composableBuilder(
    column: $table.elevationRounding,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectorName => $composableBuilder(
    column: $table.collectorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastIdentifier => $composableBuilder(
    column: $table.lastIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogPrefix => $composableBuilder(
    column: $table.catalogPrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get catalogDigits => $composableBuilder(
    column: $table.catalogDigits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextCatalogNumber => $composableBuilder(
    column: $table.nextCatalogNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get elevationRounding => $composableBuilder(
    column: $table.elevationRounding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get collectorName => $composableBuilder(
    column: $table.collectorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastIdentifier => $composableBuilder(
    column: $table.lastIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catalogPrefix => $composableBuilder(
    column: $table.catalogPrefix,
    builder: (column) => column,
  );

  GeneratedColumn<int> get catalogDigits => $composableBuilder(
    column: $table.catalogDigits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextCatalogNumber => $composableBuilder(
    column: $table.nextCatalogNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ElevationRounding, String>
  get elevationRounding => $composableBuilder(
    column: $table.elevationRounding,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingsRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> collectorName = const Value.absent(),
                Value<String?> lastIdentifier = const Value.absent(),
                Value<String> catalogPrefix = const Value.absent(),
                Value<int> catalogDigits = const Value.absent(),
                Value<int?> nextCatalogNumber = const Value.absent(),
                Value<ElevationRounding> elevationRounding =
                    const Value.absent(),
                Value<DateTime?> lastBackupAt = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                collectorName: collectorName,
                lastIdentifier: lastIdentifier,
                catalogPrefix: catalogPrefix,
                catalogDigits: catalogDigits,
                nextCatalogNumber: nextCatalogNumber,
                elevationRounding: elevationRounding,
                lastBackupAt: lastBackupAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> collectorName = const Value.absent(),
                Value<String?> lastIdentifier = const Value.absent(),
                Value<String> catalogPrefix = const Value.absent(),
                Value<int> catalogDigits = const Value.absent(),
                Value<int?> nextCatalogNumber = const Value.absent(),
                Value<ElevationRounding> elevationRounding =
                    const Value.absent(),
                Value<DateTime?> lastBackupAt = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                collectorName: collectorName,
                lastIdentifier: lastIdentifier,
                catalogPrefix: catalogPrefix,
                catalogDigits: catalogDigits,
                nextCatalogNumber: nextCatalogNumber,
                elevationRounding: elevationRounding,
                lastBackupAt: lastBackupAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSettingsRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsTable,
                    AppSettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingsRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$PlaceRomajiDictTableCreateCompanionBuilder =
    PlaceRomajiDictCompanion Function({
      Value<int> id,
      required String municipalityCode,
      required String localityJa,
      required String localityEn,
      Value<int> useCount,
      Value<DateTime> updatedAt,
    });
typedef $$PlaceRomajiDictTableUpdateCompanionBuilder =
    PlaceRomajiDictCompanion Function({
      Value<int> id,
      Value<String> municipalityCode,
      Value<String> localityJa,
      Value<String> localityEn,
      Value<int> useCount,
      Value<DateTime> updatedAt,
    });

class $$PlaceRomajiDictTableFilterComposer
    extends Composer<_$AppDatabase, $PlaceRomajiDictTable> {
  $$PlaceRomajiDictTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get municipalityCode => $composableBuilder(
    column: $table.municipalityCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localityJa => $composableBuilder(
    column: $table.localityJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localityEn => $composableBuilder(
    column: $table.localityEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaceRomajiDictTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaceRomajiDictTable> {
  $$PlaceRomajiDictTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get municipalityCode => $composableBuilder(
    column: $table.municipalityCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localityJa => $composableBuilder(
    column: $table.localityJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localityEn => $composableBuilder(
    column: $table.localityEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaceRomajiDictTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaceRomajiDictTable> {
  $$PlaceRomajiDictTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get municipalityCode => $composableBuilder(
    column: $table.municipalityCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localityJa => $composableBuilder(
    column: $table.localityJa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localityEn => $composableBuilder(
    column: $table.localityEn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlaceRomajiDictTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaceRomajiDictTable,
          PlaceRomajiEntry,
          $$PlaceRomajiDictTableFilterComposer,
          $$PlaceRomajiDictTableOrderingComposer,
          $$PlaceRomajiDictTableAnnotationComposer,
          $$PlaceRomajiDictTableCreateCompanionBuilder,
          $$PlaceRomajiDictTableUpdateCompanionBuilder,
          (
            PlaceRomajiEntry,
            BaseReferences<
              _$AppDatabase,
              $PlaceRomajiDictTable,
              PlaceRomajiEntry
            >,
          ),
          PlaceRomajiEntry,
          PrefetchHooks Function()
        > {
  $$PlaceRomajiDictTableTableManager(
    _$AppDatabase db,
    $PlaceRomajiDictTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaceRomajiDictTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaceRomajiDictTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaceRomajiDictTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> municipalityCode = const Value.absent(),
                Value<String> localityJa = const Value.absent(),
                Value<String> localityEn = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlaceRomajiDictCompanion(
                id: id,
                municipalityCode: municipalityCode,
                localityJa: localityJa,
                localityEn: localityEn,
                useCount: useCount,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String municipalityCode,
                required String localityJa,
                required String localityEn,
                Value<int> useCount = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlaceRomajiDictCompanion.insert(
                id: id,
                municipalityCode: municipalityCode,
                localityJa: localityJa,
                localityEn: localityEn,
                useCount: useCount,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaceRomajiDictTable, PlaceRomajiEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PlaceRomajiDictTable,
                    PlaceRomajiEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaceRomajiDictTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaceRomajiDictTable,
      PlaceRomajiEntry,
      $$PlaceRomajiDictTableFilterComposer,
      $$PlaceRomajiDictTableOrderingComposer,
      $$PlaceRomajiDictTableAnnotationComposer,
      $$PlaceRomajiDictTableCreateCompanionBuilder,
      $$PlaceRomajiDictTableUpdateCompanionBuilder,
      (
        PlaceRomajiEntry,
        BaseReferences<_$AppDatabase, $PlaceRomajiDictTable, PlaceRomajiEntry>,
      ),
      PlaceRomajiEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalitiesTableTableManager get localities =>
      $$LocalitiesTableTableManager(_db, _db.localities);
  $$CollectionEventsTableTableManager get collectionEvents =>
      $$CollectionEventsTableTableManager(_db, _db.collectionEvents);
  $$SpecimensTableTableManager get specimens =>
      $$SpecimensTableTableManager(_db, _db.specimens);
  $$IdentificationsTableTableManager get identifications =>
      $$IdentificationsTableTableManager(_db, _db.identifications);
  $$EnrichmentQueueTableTableManager get enrichmentQueue =>
      $$EnrichmentQueueTableTableManager(_db, _db.enrichmentQueue);
  $$DraftsTableTableManager get drafts =>
      $$DraftsTableTableManager(_db, _db.drafts);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$PlaceRomajiDictTableTableManager get placeRomajiDict =>
      $$PlaceRomajiDictTableTableManager(_db, _db.placeRomajiDict);
}
