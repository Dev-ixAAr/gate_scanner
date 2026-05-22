// ============================================================================
// Manual Search Screen — Type-in ticket reference lookup
//
// LAYOUT:
// ┌─────────────────────────────────────┐
// │  AppBar: "Manual Ticket Search" ←   │
// ├─────────────────────────────────────┤
// │  [Search Bar]  [Search Button]      │
// ├─────────────────────────────────────┤
// │                                     │
// │  [idle]    → instruction text       │
// │  [loading] → CircularProgressIndicator │
// │  [found]   → ticket info card       │
// │                │                    │
// │                ├─ valid: Check In button │
// │                ├─ already_used: audit info │
// │                ├─ wrong_event: warning  │
// │                └─ revoked/cancelled/invalid: deny info │
// │                                     │
// │  [notFound] → "No ticket found" msg │
// │  [error]    → error + retry         │
// │                                     │
// └─────────────────────────────────────┘
//
// CHECK-IN FLOW:
// 1. Valid ticket found → "Check In" button appears
// 2. Tap "Check In" → confirmation dialog
// 3. Confirm → API call → success banner shown
// 4. Result refreshes to show "already_used" state
//
// KEYBOARD HANDLING:
// - Search triggers on keyboard "done/search" action
// - TextInputAction.search sends the query
// - Manual tap on search icon button also triggers
// - Clearing the field resets to idle state
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/datetime_extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/info_row_widget.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../scanner/models/ticket_validation_result.dart';
import '../models/search_result_model.dart';
import '../providers/manual_search_provider.dart';

/// Manual ticket search screen.
///
/// Allows gate operators to look up tickets by reference number,
/// order number, or holder name without using the camera scanner.
class ManualSearchScreen extends ConsumerStatefulWidget {
  const ManualSearchScreen({super.key});

  @override
  ConsumerState<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends ConsumerState<ManualSearchScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Reset search state when entering screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(manualSearchProvider.notifier).reset();
      // Auto-focus the search field.
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // SEARCH ACTIONS
  // --------------------------------------------------------------------------

  void _onSearch() {
    final String query = _searchController.text.trim();
    if (query.isEmpty) return;
    _searchFocusNode.unfocus();
    ref.read(manualSearchProvider.notifier).search(query);
  }

  void _onClear() {
    _searchController.clear();
    ref.read(manualSearchProvider.notifier).reset();
    _searchFocusNode.requestFocus();
  }

  // --------------------------------------------------------------------------
  // CHECK-IN
  // --------------------------------------------------------------------------

  Future<void> _onCheckInTapped(String ticketRef, String holderName) async {
    // Show confirmation dialog before check-in.
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _CheckInConfirmDialog(
        holderName: holderName,
        ticketRef: ticketRef,
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    await ref.read(manualSearchProvider.notifier).confirmCheckin(ticketRef);
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(manualSearchProvider);

    // Sync controller text with loading state query (for restoration).
    if (searchState is ManualSearchLoadingState &&
        _searchController.text != searchState.query) {
      _searchController.text = searchState.query;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Manual Search'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(RouteNames.home),
          tooltip: 'Back to home',
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ─────────────────────────────────────────────────
          _SearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            isLoading: searchState is ManualSearchLoadingState,
            onSearch: _onSearch,
            onClear: _onClear,
          ),

          // Divider between search bar and results.
          const Divider(height: 1, color: AppColors.borderSecondary),

          // ── Body content based on state ─────────────────────────────────
          Expanded(
            child: switch (searchState) {
              ManualSearchIdleState() => const _IdleView(),
              ManualSearchLoadingState() => const _LoadingView(),
              ManualSearchResultState() => _ResultView(
                  state: searchState,
                  onCheckIn: _onCheckInTapped,
                ),
              ManualSearchNotFoundState() => _NotFoundView(
                  query: searchState.query,
                ),
              ManualSearchErrorState() => _ErrorView(
                  state: searchState,
                  onRetry: _onSearch,
                ),
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SEARCH BAR
// ============================================================================

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSearch,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundSecondary,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Text input.
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isLoading,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: 'Enter ticket or order reference...',
                hintStyle: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textTertiary,
                  size: 22,
                ),
                // Show clear button when there is text.
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: onClear,
                      tooltip: 'Clear search',
                    );
                  },
                ),
                filled: true,
                fillColor: AppColors.backgroundTertiary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.borderPrimary,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.brandPrimary,
                    width: 1.5,
                  ),
                ),
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Search button.
          SizedBox(
            width: 52,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                disabledBackgroundColor: AppColors.backgroundTertiary,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textInverse,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.search_rounded,
                      color: AppColors.textInverse,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// IDLE VIEW
// ============================================================================

class _IdleView extends StatelessWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimarySurface,
                border: Border.all(color: AppColors.brandPrimaryBorder),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.brandPrimary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Search for a Ticket',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter a ticket reference, order number, or '
              'holder name in the search field above.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Search tip chips.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _TipChip(label: 'e.g. TKT-2024-00123', icon: Icons.qr_code_outlined),
                _TipChip(label: 'e.g. ORD-2024-00456', icon: Icons.receipt_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LOADING VIEW
// ============================================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Searching...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RESULT VIEW
// ============================================================================

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.state,
    required this.onCheckIn,
  });

  final ManualSearchResultState state;
  final Future<void> Function(String ticketRef, String holderName) onCheckIn;

  @override
  Widget build(BuildContext context) {
    final SearchResultModel result = state.result;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Check-in success banner ─────────────────────────────────────
          if (state.checkInSuccess) ...[
            _CheckInSuccessBanner(
              holderName: result.holderName,
            ),
            const SizedBox(height: 16),
          ],

          // ── Ticket header card ──────────────────────────────────────────
          _TicketHeaderCard(result: result),
          const SizedBox(height: 16),

          // ── Status-specific content ─────────────────────────────────────
          if (result.canCheckIn && !state.checkInSuccess)
            _ValidTicketSection(
              result: result,
              isCheckingIn: state.isCheckingIn,
              checkInError: state.checkInError,
              onCheckIn: () => onCheckIn(result.ticketReference, result.holderName),
            )
          else if (result.isAlreadyUsed || state.checkInSuccess)
            _AlreadyUsedSection(
              checkedInAt: result.checkedInAt,
              checkedInByDevice: result.checkedInByDevice,
              checkedInByUser: result.checkedInByUser,
              updatedResult: state.updatedResult,
            )
          else if (result.isWrongEvent)
            _WrongEventSection(result: result)
          else if (result.isRevoked)
            _RevokedSection(result: result)
          else if (result.isCancelled)
            _CancelledSection(result: result)
          else
            _InvalidSection(result: result),
        ],
      ),
    );
  }
}

// ============================================================================
// TICKET HEADER CARD — Shows core ticket fields for all status variants
// ============================================================================

class _TicketHeaderCard extends StatelessWidget {
  const _TicketHeaderCard({required this.result});

  final SearchResultModel result;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Ticket Details',
      titleTrailing: StatusPill(
        status: result.validationStatus,
        fontSize: 10,
        verticalPadding: 4,
        horizontalPadding: 10,
      ),
      children: [
        // Holder name — most important field.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.holderName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.borderSecondary, height: 1),
        InfoRowWidget(
          label: 'Ticket Ref',
          value: result.ticketReference,
          icon: Icons.qr_code_outlined,
          monospace: true,
          valueCopyable: true,
          isLast: false,
        ),
        InfoRowWidget(
          label: 'Order Ref',
          value: result.orderReference,
          icon: Icons.receipt_outlined,
          monospace: true,
          isLast: false,
        ),
        InfoRowWidget(
          label: 'Category',
          value: result.ticketCategory,
          icon: Icons.confirmation_number_outlined,
          isLast: false,
        ),
        InfoRowWidget(
          label: 'Source',
          value: _formatSourceType(result.ticketSourceType),
          icon: _sourceIcon(result.ticketSourceType),
          isLast: false,
        ),
        InfoRowWidget(
          label: 'Event',
          value: result.eventName,
          icon: Icons.event_outlined,
          isLast: true,
        ),
      ],
    );
  }

  String _formatSourceType(String type) {
    switch (type.toLowerCase()) {
      case 'online':
        return 'Online Purchase';
      case 'physical':
        return 'Physical Ticket';
      case 'complimentary':
        return 'Complimentary';
      default:
        return type;
    }
  }

  IconData _sourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'online':
        return Icons.shopping_cart_outlined;
      case 'physical':
        return Icons.confirmation_number_outlined;
      case 'complimentary':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

// ============================================================================
// VALID TICKET SECTION — Check-in button and action
// ============================================================================

class _ValidTicketSection extends StatelessWidget {
  const _ValidTicketSection({
    required this.result,
    required this.isCheckingIn,
    required this.checkInError,
    required this.onCheckIn,
  });

  final SearchResultModel result;
  final bool isCheckingIn;
  final String? checkInError;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Valid status indicator.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.statusValidSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.statusValidBorder),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.statusValid,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket Valid',
                      style: TextStyle(
                        color: AppColors.statusValid,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'This ticket has not yet been used. Ready to check in.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Check-in error message.
        if (checkInError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.errorSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.errorBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    checkInError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Check-in button.
        AppButton.primary(
          label: isCheckingIn ? 'Checking In...' : 'Check In',
          leadingIcon: isCheckingIn ? null : Icons.how_to_reg_rounded,
          isLoading: isCheckingIn,
          onPressed: isCheckingIn ? null : onCheckIn,
        ),
      ],
    );
  }
}

// ============================================================================
// ALREADY USED SECTION
// ============================================================================

class _AlreadyUsedSection extends StatelessWidget {
  const _AlreadyUsedSection({
    this.checkedInAt,
    this.checkedInByDevice,
    this.checkedInByUser,
    this.updatedResult,
  });

  final DateTime? checkedInAt;
  final String? checkedInByDevice;
  final String? checkedInByUser;
  final TicketValidationResult? updatedResult;

  @override
  Widget build(BuildContext context) {
    // Use the updated result's check-in time if available (after just checking in).
    final DateTime? displayTime = updatedResult is ValidResult
        ? DateTime.now()
        : checkedInAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionCard(
          title: 'Check-in Record',
          children: [
            if (displayTime != null)
              InfoRowWidget(
                label: 'Checked In',
                value: displayTime.formattedDateTime,
                icon: Icons.schedule_outlined,
                valueColor: AppColors.statusAlreadyUsed,
                isLast: checkedInByDevice == null && checkedInByUser == null,
              ),
            if (checkedInByDevice != null)
              InfoRowWidget(
                label: 'By Device',
                value: checkedInByDevice!,
                icon: Icons.smartphone_outlined,
                isLast: checkedInByUser == null,
              ),
            if (checkedInByUser != null)
              InfoRowWidget(
                label: 'By User',
                value: checkedInByUser!,
                icon: Icons.person_outline,
                isLast: true,
              ),
            if (displayTime == null &&
                checkedInByDevice == null &&
                checkedInByUser == null)
              const InfoRowWidget(
                label: 'Status',
                value: 'This ticket has already been used',
                isLast: true,
                valueColor: AppColors.statusAlreadyUsed,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.statusAlreadyUsedSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.statusAlreadyUsedBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.statusAlreadyUsed, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Do not allow re-entry. Verify identity if needed.',
                  style: TextStyle(
                    color: AppColors.statusAlreadyUsed,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// WRONG EVENT SECTION
// ============================================================================

class _WrongEventSection extends StatelessWidget {
  const _WrongEventSection({required this.result});

  final SearchResultModel result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.statusWrongEventSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.statusWrongEventBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_off_rounded,
                      color: AppColors.statusWrongEvent, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Wrong Event',
                    style: TextStyle(
                      color: AppColors.statusWrongEvent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'This ticket belongs to a different event. '
                'Entry cannot be granted at this gate.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DenyNotice(
          message: 'Entry blocked — wrong event.',
          color: AppColors.statusWrongEvent,
        ),
      ],
    );
  }
}

// ============================================================================
// REVOKED SECTION
// ============================================================================

class _RevokedSection extends StatelessWidget {
  const _RevokedSection({required this.result});

  final SearchResultModel result;

  @override
  Widget build(BuildContext context) {
    return _DenyStatusSection(
      color: AppColors.statusRevoked,
      icon: Icons.remove_circle_outline_rounded,
      title: 'Ticket Revoked',
      description: 'This ticket has been revoked by the event organizer.',
      denyMessage: 'Entry blocked — ticket revoked.',
    );
  }
}

// ============================================================================
// CANCELLED SECTION
// ============================================================================

class _CancelledSection extends StatelessWidget {
  const _CancelledSection({required this.result});

  final SearchResultModel result;

  @override
  Widget build(BuildContext context) {
    return _DenyStatusSection(
      color: AppColors.statusCancelled,
      icon: Icons.cancel_outlined,
      title: 'Ticket Cancelled',
      description: 'This ticket or order has been cancelled.',
      denyMessage: 'Entry blocked — ticket cancelled.',
    );
  }
}

// ============================================================================
// INVALID SECTION
// ============================================================================

class _InvalidSection extends StatelessWidget {
  const _InvalidSection({required this.result});

  final SearchResultModel result;

  @override
  Widget build(BuildContext context) {
    return _DenyStatusSection(
      color: AppColors.statusInvalid,
      icon: Icons.help_outline_rounded,
      title: 'Invalid Ticket',
      description:
          'This ticket reference is not valid for this event.',
      denyMessage: 'Entry blocked — invalid ticket.',
    );
  }
}

/// Shared layout for revoked, cancelled, and invalid sections.
class _DenyStatusSection extends StatelessWidget {
  const _DenyStatusSection({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
    required this.denyMessage,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String description;
  final String denyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DenyNotice(message: denyMessage, color: color),
      ],
    );
  }
}

// ============================================================================
// DENY NOTICE — Red block bar
// ============================================================================

class _DenyNotice extends StatelessWidget {
  const _DenyNotice({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(Icons.block_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CHECK-IN SUCCESS BANNER
// ============================================================================

class _CheckInSuccessBanner extends StatelessWidget {
  const _CheckInSuccessBanner({required this.holderName});

  final String holderName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusValidSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusValidBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.statusValid.withAlpha(30),
              border: Border.all(
                  color: AppColors.statusValid.withAlpha(80), width: 1.5),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.statusValid,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Check-In Successful',
                  style: TextStyle(
                    color: AppColors.statusValid,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$holderName has been checked in.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NOT FOUND VIEW
// ============================================================================

class _NotFoundView extends StatelessWidget {
  const _NotFoundView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warningSurface,
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.warning,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Ticket Found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'No ticket found matching:\n"$query"',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Try checking:\n'
              '• Ticket reference (e.g. TKT-2024-00123)\n'
              '• Order reference (e.g. ORD-2024-00456)\n'
              '• Exact holder name',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ERROR VIEW
// ============================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.state,
    required this.onRetry,
  });

  final ManualSearchErrorState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.errorSurface,
                border: Border.all(color: AppColors.errorBorder),
              ),
              child: Icon(
                state.isNetworkError
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                color: AppColors.error,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              state.isNetworkError ? 'Connection Error' : 'Search Failed',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              state.message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton.primary(
              label: 'Try Again',
              leadingIcon: Icons.refresh_rounded,
              onPressed: onRetry,
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CHECK-IN CONFIRMATION DIALOG
// ============================================================================

class _CheckInConfirmDialog extends StatelessWidget {
  const _CheckInConfirmDialog({
    required this.holderName,
    required this.ticketRef,
  });

  final String holderName;
  final String ticketRef;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Check-In'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Check in this ticket holder?'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        holderName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.qr_code_outlined,
                        size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Text(
                      ticketRef,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.how_to_reg_rounded, size: 18),
          label: const Text('Check In'),
        ),
      ],
    );
  }
}