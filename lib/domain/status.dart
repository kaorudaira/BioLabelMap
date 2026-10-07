// DB に `name` で保存する列挙型をまとめる。名前を変えるときはデータ移行が要る。

/// 標高・地名の取得状態(要件定義 第13章)。
enum FetchStatus {
  /// 未取得(補完待ち)。
  pending,

  /// API から取得済み。
  fetched,

  /// 通信は成功したがデータが無い(海上など)。手入力できる。
  unavailable,

  /// 手入力した。補完で上書きしない。
  manual,
}

/// 補完キューで取得するものの種類。
enum EnrichmentKind { elevation, place }

/// 同定の状態(要件定義 F-11)。
enum IdentificationStatus { unidentified, provisional, verified }

extension IdentificationStatusLabel on IdentificationStatus {
  /// 画面に出す名前。
  String get label => switch (this) {
    IdentificationStatus.unidentified => '未同定',
    IdentificationStatus.provisional => '仮同定',
    IdentificationStatus.verified => '同定済み',
  };
}

/// 性別。
enum Sex { male, female, unknown }
