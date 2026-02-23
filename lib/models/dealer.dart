// lib/models/dealer.dart

/// Per-dealer pricing multipliers fetched from the API.
///
/// Four rate pairs — one per ticket type — so the client can display correct
/// preview amounts for each LSK:
///   A / B / C    → singleDRate / singleCRate
///   AB / AC / BC → doubleDRate / doubleCRate
///   Super        → superDRate  / superCRate
///   Box          → boxDRate    / boxCRate
///
/// These are only used on the client for preview purposes.
/// The server always recalculates final amounts from its own stored package
/// data — prices are never trusted from the client.
class DealerPackage {
  final double singleDRate;
  final double singleCRate;
  final double doubleDRate;
  final double doubleCRate;
  final double superDRate;
  final double superCRate;
  final double boxDRate;
  final double boxCRate;

  const DealerPackage({
    required this.singleDRate,
    required this.singleCRate,
    required this.doubleDRate,
    required this.doubleCRate,
    required this.superDRate,
    required this.superCRate,
    required this.boxDRate,
    required this.boxCRate,
  });

  factory DealerPackage.fromJson(Map<String, dynamic> json) => DealerPackage(
        singleDRate: (json['single_d_rate'] as num).toDouble(),
        singleCRate: (json['single_c_rate'] as num).toDouble(),
        doubleDRate: (json['double_d_rate'] as num).toDouble(),
        doubleCRate: (json['double_c_rate'] as num).toDouble(),
        superDRate:  (json['super_d_rate']  as num).toDouble(),
        superCRate:  (json['super_c_rate']  as num).toDouble(),
        boxDRate:    (json['box_d_rate']    as num).toDouble(),
        boxCRate:    (json['box_c_rate']    as num).toDouble(),
      );
}

class Dealer {
  final int id;
  final String name;
  final String code;
  final DealerPackage package;

  const Dealer({
    required this.id,
    required this.name,
    required this.code,
    required this.package,
  });

  factory Dealer.fromJson(Map<String, dynamic> json) => Dealer(
        id: json['id'] as int,
        name: json['name'] as String,
        code: json['code'] as String,
        package: DealerPackage.fromJson(
          json['package'] as Map<String, dynamic>,
        ),
      );
}
