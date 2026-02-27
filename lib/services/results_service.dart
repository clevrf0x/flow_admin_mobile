// lib/services/results_service.dart

import 'package:dio/dio.dart';

import 'api_client.dart';

class ResultsException implements Exception {
  final String code;
  final String message;

  const ResultsException(this.code, this.message);

  @override
  String toString() => 'ResultsException($code): $message';
}

class ResultsService {
  /// Fetches existing results for [gameId] on [date].
  ///
  /// Returns a map of prize fields (prize_1…prize_5, comp_1…comp_30) when
  /// results exist for that game/date, or `null` if none have been saved yet.
  ///
  /// Throws [ResultsException] on unexpected errors (not on 404).
  static Future<Map<String, String>?> fetchResult({
    required String gameId,
    required DateTime date,
  }) async {
    final dio = ApiClient.dio;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final response = await dio.get(
        '/api/v1/results/',
        queryParameters: {'game_id': gameId, 'date': dateStr},
      );
      if (response.data['success'] == true) {
        final result = response.data['data']['result'] as Map<String, dynamic>;
        // Extract only the prize fields, coerce all values to String
        final prizes = <String, String>{};
        for (final entry in result.entries) {
          if (entry.key.startsWith('prize_') || entry.key.startsWith('comp_')) {
            prizes[entry.key] =
                entry.value == null ? '' : entry.value.toString();
          }
        }
        return prizes;
      }
      return null;
    } on ResultsException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // no results saved yet
      final data = e.response?.data;
      if (data != null && data['error'] != null) {
        throw ResultsException(
          data['error']['code'] as String,
          data['error']['message'] as String,
        );
      }
      throw const ResultsException(
        'NETWORK_ERROR',
        'Network error. Please check your connection.',
      );
    }
  }

  /// Saves draw results for [gameId] on [date].
  ///
  /// [prizes] must contain exactly these keys with their values:
  ///   'prize_1' … 'prize_5'  — main prizes  (prize_1 must be non-empty)
  ///   'comp_1'  … 'comp_30'  — comp prizes
  ///
  /// Each value is either an empty string (not entered) or exactly 3 digits.
  /// The caller (screen) is responsible for client-side validation before
  /// calling this method.
  ///
  /// Throws [ResultsException] on API errors or network failures.
  static Future<void> saveResults({
    required String gameId,
    required DateTime date,
    required Map<String, String> prizes,
  }) async {
    final dio = ApiClient.dio;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final response = await dio.post(
        '/api/v1/results/',
        data: {
          'game_id': gameId,
          'date': dateStr,
          ...prizes, // spreads prize_1…prize_5, comp_1…comp_30 directly
        },
      );

      if (response.data['success'] != true) {
        final err = response.data['error'];
        throw ResultsException(
          err['code'] as String,
          err['message'] as String,
        );
      }
    } on ResultsException {
      rethrow;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data != null && data['error'] != null) {
        throw ResultsException(
          data['error']['code'] as String,
          data['error']['message'] as String,
        );
      }
      throw const ResultsException(
        'NETWORK_ERROR',
        'Network error. Please check your connection.',
      );
    }
  }
}
