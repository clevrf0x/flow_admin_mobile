// lib/services/today_service.dart

import 'package:dio/dio.dart';
import 'api_client.dart';

// ── Exception ─────────────────────────────────────────────────────────────────

class TodayException implements Exception {
  final String code;
  final String message;

  const TodayException(this.code, this.message);

  @override
  String toString() => 'TodayException($code): $message';
}

// ── Models ────────────────────────────────────────────────────────────────────

/// A single aggregated entry row in the today summary.
///
/// [lsk] is stored uppercase for consistent display and filter matching
/// (API returns "Super"/"Box" title-case; screen filters use "SUPER"/"BOX").
class TodayEntry {
  final String number;
  final String lsk;
  final int count;

  const TodayEntry({
    required this.number,
    required this.lsk,
    required this.count,
  });

  factory TodayEntry.fromJson(Map<String, dynamic> json) => TodayEntry(
        number: json['number'] as String,
        lsk:    (json['lsk'] as String).toUpperCase(),
        count:  (json['count'] as num).toInt(),
      );
}

/// Full response from GET /api/v1/reports/today/.
class TodaySummary {
  final String gameId;
  final String date;       // "YYYY-MM-DD"
  final int totalCount;    // sum of count across ALL entries (unfiltered)
  final List<TodayEntry> entries;

  const TodaySummary({
    required this.gameId,
    required this.date,
    required this.totalCount,
    required this.entries,
  });

  factory TodaySummary.fromJson(Map<String, dynamic> json) => TodaySummary(
        gameId:     json['game_id'] as String,
        date:       json['date'] as String,
        totalCount: (json['total_count'] as num).toInt(),
        entries: (json['entries'] as List<dynamic>)
            .map((e) => TodayEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class TodayService {
  TodayService._();

  /// Fetches today's booking summary for a specific game.
  ///
  /// GET /api/v1/reports/today/?game_id=<gameId>
  ///
  /// [gameId] is required — each game dashboard shows only its own summary.
  /// Returns entries aggregated by (number, lsk) across all dealers, sorted
  /// by number then lsk.
  static Future<TodaySummary> fetchToday(String gameId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/v1/reports/today/',
        queryParameters: {'game_id': gameId},
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return TodaySummary.fromJson(data);
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Never _rethrow(DioException e) {
    if (e.response != null) {
      final error = e.response!.data['error'] as Map<String, dynamic>;
      throw TodayException(
        error['code'] as String,
        error['message'] as String,
      );
    }
    throw const TodayException(
      'NETWORK_ERROR',
      'Could not reach the server. Check your connection.',
    );
  }
}
