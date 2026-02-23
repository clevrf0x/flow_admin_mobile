// lib/services/daily_report_service.dart

import 'package:dio/dio.dart';
import 'api_client.dart';

// ── Exception ─────────────────────────────────────────────────────────────────

class DailyReportException implements Exception {
  final String code;
  final String message;

  const DailyReportException(this.code, this.message);

  @override
  String toString() => 'DailyReportException($code): $message';
}

// ── Model ─────────────────────────────────────────────────────────────────────

/// One row in the daily report — one dealer's totals for one date.
///
/// [tSale] = sum of c_amount (full collection) for the dealer on that date.
/// [tWin]  = 0.0 until win payouts are implemented server-side.
/// [balance] = tSale - tWin (computed).
class DailyReportRow {
  final String date;       // "YYYY-MM-DD"
  final int dealerId;
  final String dealerName;
  final String dealerCode;
  final double tSale;
  final double tWin;

  const DailyReportRow({
    required this.date,
    required this.dealerId,
    required this.dealerName,
    required this.dealerCode,
    required this.tSale,
    required this.tWin,
  });

  double get balance => tSale - tWin;

  factory DailyReportRow.fromJson(Map<String, dynamic> json) {
    final dealer = json['dealer'] as Map<String, dynamic>;
    return DailyReportRow(
      date:       json['date'] as String,
      dealerId:   dealer['id'] as int,
      dealerName: dealer['name'] as String,
      dealerCode: dealer['code'] as String,
      tSale:      (json['t_sale'] as num).toDouble(),
      tWin:       (json['t_win']  as num).toDouble(),
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class DailyReportService {
  DailyReportService._();

  /// Fetches the daily report aggregated by (date, dealer).
  ///
  /// GET /api/v1/reports/daily/
  ///
  /// [startDate] and [endDate] are "YYYY-MM-DD" strings.
  /// [gameId] — pass null or 'all' to include all games.
  /// [dealerId] — pass null to include all dealers.
  static Future<List<DailyReportRow>> fetchReport({
    required String startDate,
    required String endDate,
    String? gameId,
    int? dealerId,
  }) async {
    try {
      final params = <String, dynamic>{
        'start_date': startDate,
        'end_date':   endDate,
        'game_id':    gameId ?? 'all',
        if (dealerId != null) 'dealer_id': dealerId,
      };

      final response = await ApiClient.dio.get(
        '/api/v1/reports/daily/',
        queryParameters: params,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final list = data['rows'] as List<dynamic>;
      return list
          .map((r) => DailyReportRow.fromJson(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Never _rethrow(DioException e) {
    if (e.response != null) {
      final error = e.response!.data['error'] as Map<String, dynamic>;
      throw DailyReportException(
        error['code'] as String,
        error['message'] as String,
      );
    }
    throw const DailyReportException(
      'NETWORK_ERROR',
      'Could not reach the server. Check your connection.',
    );
  }
}
