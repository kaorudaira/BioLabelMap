/// ごみ箱の保持期間(日)。過ぎると完全に削除する(要件定義 S-04「ごみ箱」。設定で変えられるのは段階4)。
const trashRetentionDays = 30;

/// 完全に削除するまでの残り日数。削除した日(24時間ごとに1日)から数え、0 以上。
int daysUntilPurge(DateTime deletedAt, DateTime now, {int retentionDays = trashRetentionDays}) {
  final elapsed = now.difference(deletedAt).inDays;
  final left = retentionDays - elapsed;
  return left < 0 ? 0 : left;
}

/// 完全に削除する期限を過ぎているか。
bool isPurgeDue(DateTime deletedAt, DateTime now, {int retentionDays = trashRetentionDays}) =>
    now.difference(deletedAt) >= Duration(days: retentionDays);

/// ごみ箱の行に出す残り日数。
String purgeCountdownText(DateTime deletedAt, DateTime now, {int retentionDays = trashRetentionDays}) {
  final days = daysUntilPurge(deletedAt, now, retentionDays: retentionDays);
  return days == 0 ? 'まもなく完全に削除' : 'あと$days日で完全に削除';
}
