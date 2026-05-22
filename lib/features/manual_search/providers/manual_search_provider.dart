// ============================================================================
// Manual Search Provider — Search flow state management
//
// ARCHITECTURE DECISION — Notifier<ManualSearchState>:
// The search screen needs simultaneous access to:
// - Current query text (synchronous, always visible)
// - Loading flag (independent of result)
// - Current result (nullable)
// - Check-in loading flag (separate from search loading)
// - Check-in success flag
// - Error message (nullable)
//
// AsyncNotifier would collapse this into loading/data/error which is too
// coarse for this screen's needs. Notifier<ManualSearchState> gives precise
// control over all fields simultaneously.
//
// STATE MACHINE:
// idle → (search) → loading
//                → result(found) → canCheckIn?
//                                   → (confirmCheckin) → checkingIn
//                                                      → checkedIn (success)
//                                                      → checkInError
//                → notFound
//                → error(message)
// any → (reset) → idle
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../scanner/data/scanner_repository.dart';
import '../../scanner/models/ticket_validation_result.dart';
import '../data/manual_search_repository.dart';
import '../models/search_result_model.dart';

part 'manual_search_provider.g.dart';

// ============================================================================
// STATE SEALED CLASS
// ============================================================================

/// Complete state of the manual ticket search screen.
sealed class ManualSearchState {
  const ManualSearchState();
}

/// Initial state — search bar is empty, nothing displayed.
final class ManualSearchIdleState extends ManualSearchState {
  const ManualSearchIdleState();
}

/// Search API call in progress.
/// [query] is the active search term — shown in the search bar.
final class ManualSearchLoadingState extends ManualSearchState {
  const ManualSearchLoadingState({required this.query});
  final String query;
}

/// Search returned a result.
/// [isCheckingIn] is true while the check-in API call is in progress.
/// [checkInSuccess] is true after a successful check-in.
/// [checkInError] is non-null if the check-in API call failed.
final class ManualSearchResultState extends ManualSearchState {
  const ManualSearchResultState({
    required this.query,
    required this.result,
    this.isCheckingIn = false,
    this.checkInSuccess = false,
    this.checkInError,
    this.updatedResult,
  });

  final String query;
  final SearchResultModel result;
  final bool isCheckingIn;
  final bool checkInSuccess;
  final String? checkInError;

  /// Updated result after a successful check-in.
  /// If non-null, the UI shows this result instead of [result].
  final TicketValidationResult? updatedResult;

  ManualSearchResultState copyWith({
    bool? isCheckingIn,
    bool? checkInSuccess,
    String? checkInError,
    TicketValidationResult? updatedResult,
    bool clearCheckInError = false,
  }) {
    return ManualSearchResultState(
      query: query,
      result: result,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
      checkInSuccess: checkInSuccess ?? this.checkInSuccess,
      checkInError:
          clearCheckInError ? null : (checkInError ?? this.checkInError),
      updatedResult: updatedResult ?? this.updatedResult,
    );
  }
}

/// Search returned no results (404).
final class ManualSearchNotFoundState extends ManualSearchState {
  const ManualSearchNotFoundState({required this.query});
  final String query;
}

/// Search failed with an error.
final class ManualSearchErrorState extends ManualSearchState {
  const ManualSearchErrorState({
    required this.query,
    required this.message,
    this.isNetworkError = false,
  });

  final String query;
  final String message;
  final bool isNetworkError;
}

// ============================================================================
// NOTIFIER
// ============================================================================

/// Riverpod provider for [ManualSearchNotifier].
@riverpod
class ManualSearch extends _$ManualSearch {
  @override
  ManualSearchState build() {
    _log('build → idle state');
    return const ManualSearchIdleState();
  }

  // ==========================================================================
  // SEARCH
  // ==========================================================================

  /// Searches for a ticket by [query].
  ///
  /// Transitions: idle/result/error/notFound → loading → result/notFound/error
  ///
  /// Does nothing if [query] is empty after trimming.
  /// Does nothing if a search for the same query is already in progress.
  Future<void> search(String query) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    // Guard: don't re-search if already loading the same query.
    final current = state;
    if (current is ManualSearchLoadingState &&
        current.query == trimmedQuery) {
      _log('search → already loading "$trimmedQuery", skipping');
      return;
    }

    _log('search → starting: "$trimmedQuery"');
    state = ManualSearchLoadingState(query: trimmedQuery);

    try {
      final ManualSearchRepository repository =
          ref.read(manualSearchRepositoryProvider);
      final SearchResultModel result =
          await repository.searchTicket(trimmedQuery);

      _log('search → found: ${result.ticketReference} (${result.validationStatus})');
      state = ManualSearchResultState(
        query: trimmedQuery,
        result: result,
      );
    } on SearchNotFoundException {
      _log('search → not found: "$trimmedQuery"');
      state = ManualSearchNotFoundState(query: trimmedQuery);
    } on ApiException catch (e) {
      _log('search → ApiException: $e');
      state = ManualSearchErrorState(
        query: trimmedQuery,
        message: e.message,
        isNetworkError: e.isNetworkError,
      );
    } catch (e) {
      _log('search → unexpected error: $e');
      state = ManualSearchErrorState(
        query: trimmedQuery,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ==========================================================================
  // CONFIRM CHECKIN
  // ==========================================================================

  /// Calls the check-in API for the ticket in the current result.
  ///
  /// Only valid when state is [ManualSearchResultState] and
  /// [result.canCheckIn] is true.
  ///
  /// On success: updates state with [checkInSuccess = true] and the
  ///             updated [ValidResult] returned by the API.
  /// On failure: updates state with [checkInError] message.
  Future<void> confirmCheckin(String ticketRef) async {
    final current = state;
    if (current is! ManualSearchResultState) {
      _log('confirmCheckin → state is not ResultState, skipping');
      return;
    }

    if (current.isCheckingIn) {
      _log('confirmCheckin → already checking in, skipping');
      return;
    }

    _log('confirmCheckin → starting for: $ticketRef');
    state = current.copyWith(
      isCheckingIn: true,
      clearCheckInError: true,
    );

    try {
      // Re-use ScannerRepository.checkinTicket — same endpoint, same payload.
      final ScannerRepository scannerRepository =
          ref.read(scannerRepositoryProvider);
      final TicketValidationResult result =
          await scannerRepository.checkinTicket(ticketRef);

      _log('confirmCheckin → success: ${result.runtimeType}');
      state = current.copyWith(
        isCheckingIn: false,
        checkInSuccess: true,
        updatedResult: result,
      );
    } on ApiException catch (e) {
      _log('confirmCheckin → ApiException: $e');
      state = current.copyWith(
        isCheckingIn: false,
        checkInError: e.message,
      );
    } catch (e) {
      _log('confirmCheckin → unexpected error: $e');
      state = current.copyWith(
        isCheckingIn: false,
        checkInError: 'Check-in failed unexpectedly. Please try again.',
      );
    }
  }

  // ==========================================================================
  // RESET
  // ==========================================================================

  /// Resets the search state to idle.
  ///
  /// Called when the user clears the search field or navigates back.
  void reset() {
    _log('reset → idle');
    state = const ManualSearchIdleState();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[ManualSearchNotifier] $message');
  }
}