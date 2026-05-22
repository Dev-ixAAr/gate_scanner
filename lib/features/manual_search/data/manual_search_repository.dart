// ============================================================================
// Manual Search Repository — Ticket lookup by reference
//
// Handles GET /api/scanner/ticket/search
//
// QUERY PARAMETERS SENT:
// ?q=<search_query>&event_public_ref=<ref>
//
// RESPONSE:
// { ticket data fields } — single ticket object
//
// SEARCH QUERY TYPES SUPPORTED (backend-dependent):
// - Ticket reference: 'TKT-2024-00123'
// - Order reference:  'ORD-2024-00456'
// - Holder name:      'John Smith' (if backend supports name search)
//
// ERROR HANDLING:
// - 404: ticket not found → throws SearchNotFoundException (not ApiException)
// - Network/server errors → throws ApiException
// - Parse errors → throws ApiException with descriptive message
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/services/session_service.dart';
import '../models/search_result_model.dart';

/// Riverpod provider for [ManualSearchRepository].
final manualSearchRepositoryProvider =
    Provider<ManualSearchRepository>((ref) {
  return ManualSearchRepository(ref: ref);
});

/// Handles manual ticket search API calls.
class ManualSearchRepository {
  const ManualSearchRepository({required Ref ref}) : _ref = ref;

  final Ref _ref;

  // ==========================================================================
  // SEARCH TICKET
  // ==========================================================================

  /// Searches for a ticket by reference, order number, or holder name.
  ///
  /// Sends a GET request with [query] and the current event's public ref
  /// as query parameters. Returns a [SearchResultModel] on success.
  ///
  /// THROWS:
  /// - [SearchNotFoundException]: when the backend returns 404
  ///   (ticket reference not found in the system)
  /// - [ApiException]: for network errors, server errors, parse failures
  Future<SearchResultModel> searchTicket(String query) async {
    final String trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      throw const ApiException._(
        message: 'Search query cannot be empty.',
      );
    }

    _log('searchTicket → query: "$trimmedQuery"');

    // Read the event public ref from session.
    final SessionService sessionService = _ref.read(sessionServiceProvider);
    final String? eventPublicRef = await sessionService.getEventPublicRef();

    try {
      final Dio dio = await _ref.read(authenticatedDioProvider.future);

      final Response<Map<String, dynamic>> response =
          await dio.get<Map<String, dynamic>>(
        ApiEndpoints.manualTicketSearch,
        queryParameters: {
          'q': trimmedQuery,
          if (eventPublicRef != null && eventPublicRef.isNotEmpty)
            'event_public_ref': eventPublicRef,
        },
      );

      final dynamic responseData = response.data;

      if (responseData == null || responseData is! Map<String, dynamic>) {
        _log('ERROR: null or non-map response');
        throw const ApiException._(
          message: 'Server returned an unexpected response format.',
        );
      }

      final SearchResultModel result =
          SearchResultModel.fromJson(responseData);
      _log('searchTicket → found: ${result.ticketReference}');
      return result;
    } on DioException catch (e) {
      // 404 → specific "not found" exception.
      if (e.response?.statusCode == 404) {
        _log('searchTicket → 404: ticket not found for "$trimmedQuery"');
        throw SearchNotFoundException(query: trimmedQuery);
      }
      final ApiException apiException = ApiException.fromDioException(e);
      _log('DioException: $apiException');
      throw apiException;
    } on SearchNotFoundException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      _log('Unexpected error: $e');
      throw ApiException._(
        message: 'Unexpected error during search: $e',
      );
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[ManualSearchRepository] $message');
  }
}

// ============================================================================
// SEARCH NOT FOUND EXCEPTION
// ============================================================================

/// Thrown when the backend returns 404 for a ticket search.
///
/// Distinct from [ApiException] so the UI can show a specific
/// "No ticket found" message instead of a generic error.
class SearchNotFoundException implements Exception {
  const SearchNotFoundException({required this.query});

  /// The search query that returned no results.
  final String query;

  @override
  String toString() =>
      'SearchNotFoundException: No ticket found for query "$query"';
}