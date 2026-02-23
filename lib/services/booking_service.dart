// lib/services/booking_service.dart

import 'package:dio/dio.dart';
import '../models/dealer.dart';
import 'api_client.dart';

// ── Errors ────────────────────────────────────────────────────────────────────

class BookingException implements Exception {
  final String code;
  final String message;

  const BookingException(this.code, this.message);

  @override
  String toString() => 'BookingException($code): $message';
}

// ── Payload / Response models ─────────────────────────────────────────────────

/// A single ticket sent to the server.
///
/// Prices are intentionally excluded — the server calculates D.Amount and
/// C.Amount from the dealer's stored package, preventing any client-side
/// price manipulation.
class TicketPayload {
  final String lsk;
  final String number;
  final int count;

  const TicketPayload({
    required this.lsk,
    required this.number,
    required this.count,
  });

  Map<String, dynamic> toJson() => {
        'lsk': lsk,
        'number': number,
        'count': count,
      };
}

/// Confirmed booking summary returned by the server after saving.
///
/// All amounts here are server-authoritative.
class BookingResult {
  final String bookingId;
  final int ticketCount;
  final int totalCount;
  final int totalDAmount;
  final int totalCAmount;

  const BookingResult({
    required this.bookingId,
    required this.ticketCount,
    required this.totalCount,
    required this.totalDAmount,
    required this.totalCAmount,
  });

  factory BookingResult.fromJson(Map<String, dynamic> json) => BookingResult(
        bookingId: json['booking_id'] as String,
        ticketCount: (json['ticket_count'] as num).toInt(),
        totalCount: (json['total_count'] as num).toInt(),
        totalDAmount: (json['total_d_amount'] as num).toInt(),
        totalCAmount: (json['total_c_amount'] as num).toInt(),
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class BookingService {
  BookingService._();

  /// Returns all dealers available for [gameId].
  ///
  /// GET /api/v1/dealers/?game_id=<gameId>
  ///
  /// Response envelope:
  /// ```json
  /// { "success": true, "data": { "dealers": [ { "id": 1, "name": "...",
  ///   "code": "...", "package": { "d_rate": 9, "c_rate": 10 } } ] } }
  /// ```
  static Future<List<Dealer>> getDealers(String gameId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/v1/dealers/',
        queryParameters: {'game_id': gameId},
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final list = data['dealers'] as List<dynamic>;
      return list
          .map((d) => Dealer.fromJson(d as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  /// Submits a booking and returns the server-confirmed result.
  ///
  /// POST /api/v1/bookings/
  ///
  /// Request body — only ticket type & counts are sent; prices are never
  /// included so they cannot be intercepted and modified in transit:
  /// ```json
  /// {
  ///   "game_id": "game_01pm",
  ///   "dealer_id": 42,
  ///   "tickets": [
  ///     { "lsk": "AB", "number": "12", "count": 5 }
  ///   ]
  /// }
  /// ```
  static Future<BookingResult> createBooking({
    required String gameId,
    required int dealerId,
    required List<TicketPayload> tickets,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/v1/bookings/',
        data: {
          'game_id': gameId,
          'dealer_id': dealerId,
          'tickets': tickets.map((t) => t.toJson()).toList(),
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return BookingResult.fromJson(data['booking'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  static Never _rethrow(DioException e) {
    if (e.response != null) {
      final error = e.response!.data['error'] as Map<String, dynamic>;
      throw BookingException(
        error['code'] as String,
        error['message'] as String,
      );
    }
    throw const BookingException(
      'NETWORK_ERROR',
      'Could not reach the server. Check your connection.',
    );
  }
}
