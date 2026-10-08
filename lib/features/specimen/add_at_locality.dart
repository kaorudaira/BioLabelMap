import '../../core/db/database.dart';
import '../../domain/specimen_list.dart';
import '../../services/specimen_service.dart';
import '../record/record_form.dart';

/// 「この地点で追加」で開く記録画面の初期値を作る(地点詳細・地図のピンで共通)。
///
/// その地点でいちばん新しい採集(採集日が新しく、同じなら標本番号が大きいもの)の
/// 地点・日時・採集方法・環境をコピーする。標本が無い地点は、今日の日付で、地点だけを使う。
/// 標本の詳細が読めなかったときは null。
Future<RecordForm?> recordFormForLocality(
  SpecimenService service,
  Locality locality,
  List<SpecimenListItem> specimensHere,
) async {
  if (specimensHere.isEmpty) {
    return RecordForm.at(
      latitude: locality.latitude,
      longitude: locality.longitude,
      existingLocalityId: locality.id,
    );
  }
  final latest = arrangeSpecimens(specimensHere).first.items.last;
  final detail = await service.detail(latest.id);
  if (detail == null) return null;
  return RecordForm.fromEvent(detail.event, detail.locality);
}

/// 同じ場所(緯度経度の判定キーが同じ)の標本。地名の修正で地点の行が複製されても、まとめて扱う。
List<SpecimenListItem> specimensAtLocality(Iterable<SpecimenListItem> items, Locality locality) => [
  for (final i in items)
    if (i.latE4 == locality.latE4 && i.lonE4 == locality.lonE4) i,
];
