// lib/services/sales_report_service.dart

import 'package:dio/dio.dart';
import 'api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Exception
// ─────────────────────────────────────────────────────────────────────────────

class SalesException implements Exception {
  final String message;
  const SalesException(this.message);
  @override
  String toString() => 'SalesException: $message';
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

/// One ticket entry inside a booking (only present in expanded mode).
class SalesEntryRow {
  final int id;
  final String number;
  final String lsk;
  final int count;
  final double dAmount;
  final double cAmount;

  const SalesEntryRow({
    required this.id,
    required this.number,
    required this.lsk,
    required this.count,
    required this.dAmount,
    required this.cAmount,
  });

  factory SalesEntryRow.fromJson(Map<String, dynamic> json) => SalesEntryRow(
        id:      (json['id'] as num).toInt(),
        number:  json['number'] as String,
        lsk:     json['lsk']    as String,
        count:   (json['count']    as num).toInt(),
        dAmount: (json['d_amount'] as num).toDouble(),
        cAmount: (json['c_amount'] as num).toDouble(),
      );
}

/// One booking row in the sales report.
/// [entries] is non-null only when expanded=true was requested.
class SalesBookingRow {
  final int id;
  final String date;
  final String time;
  final int dealerId;
  final String dealerName;
  final String dealerCode;
  final int count;
  final double dAmount;
  final double cAmount;
  final List<SalesEntryRow>? entries;

  const SalesBookingRow({
    required this.id,
    required this.date,
    required this.time,
    required this.dealerId,
    required this.dealerName,
    required this.dealerCode,
    required this.count,
    required this.dAmount,
    required this.cAmount,
    this.entries,
  });

  factory SalesBookingRow.fromJson(Map<String, dynamic> json) => SalesBookingRow(
        id:         (json['id'] as num).toInt(),
        date:       json['date']        as String,
        time:       json['time']        as String,
        dealerId:   (json['dealer_id'] as num).toInt(),
        dealerName: json['dealer_name'] as String,
        dealerCode: json['dealer_code'] as String,
        count:      (json['count']    as num).toInt(),
        dAmount:    (json['d_amount'] as num).toDouble(),
        cAmount:    (json['c_amount'] as num).toDouble(),
        entries: json['entries'] != null
            ? (json['entries'] as List<dynamic>)
                .map((e) => SalesEntryRow.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
      );
}

class SalesReportTotals {
  final int count;
  final double dAmount;
  final double cAmount;

  const SalesReportTotals({
    required this.count,
    required this.dAmount,
    required this.cAmount,
  });

  factory SalesReportTotals.fromJson(Map<String, dynamic> json) =>
      SalesReportTotals(
        count:   (json['count']    as num).toInt(),
        dAmount: (json['d_amount'] as num).toDouble(),
        cAmount: (json['c_amount'] as num).toDouble(),
      );
}

class SalesReport {
  final List<SalesBookingRow> bookings;
  final SalesReportTotals totals;

  const SalesReport({required this.bookings, required this.totals});

  factory SalesReport.fromJson(Map<String, dynamic> json) => SalesReport(
        bookings: (json['bookings'] as List<dynamic>)
            .map((b) => SalesBookingRow.fromJson(b as Map<String, dynamic>))
            .toList(),
        totals: SalesReportTotals.fromJson(
            json['totals'] as Map<String, dynamic>),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class SalesReportService {
  /// Fetch sales report for [gameId].
  ///
  /// [startDate] and [endDate] must be in 'YYYY-MM-DD' format.
  /// [digit] must be 1, 2, or 3 (omit for all digit counts).
  /// [expanded] = true returns per-booking entry breakdowns.
  static Future<SalesReport> fetchReport({
    required String gameId,
    required String startDate,
    required String endDate,
    int? dealerId,
    int? digit,
    List<String>? lskTypes, // e.g. ['A','B'] or ['Super','Box']
    bool expanded = false,
  }) async {
    try {
      final params = <String, dynamic>{
        'game_id':    gameId,
        'start_date': startDate,
        'end_date':   endDate,
        if (dealerId != null)                      'dealer_id': dealerId,
        if (digit != null)                         'digit':     digit,
        if (lskTypes != null && lskTypes.isNotEmpty) 'lsk':    lskTypes.join(','),
        if (expanded)                              'expanded':  'true',
      };

      final response = await ApiClient.dio.get(
        '/api/v1/reports/sales/',
        queryParameters: params,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return SalesReport.fromJson(data);
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message']
          ?? 'Failed to load sales report.';
      throw SalesException(msg as String);
    }
  }

  /// Permanently deletes a booking and all its entries.
  /// Throws [SalesException] on failure.
  static Future<void> deleteBooking(int bookingId) async {
    try {
      await ApiClient.dio.delete('/api/v1/bookings/$bookingId/');
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message']
          ?? 'Failed to delete booking.';
      throw SalesException(msg as String);
    }
  }

  /// Deletes a single booking entry.
  /// If the parent booking becomes empty it is also deleted server-side.
  /// Throws [SalesException] on failure.
  static Future<void> deleteEntry(int entryId) async {
    try {
      await ApiClient.dio.delete('/api/v1/bookings/entries/$entryId/');
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message']
          ?? 'Failed to delete entry.';
      throw SalesException(msg as String);
    }
  }
}
