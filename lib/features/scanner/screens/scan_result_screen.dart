// ============================================================================
// Scan Result Screen — Modal bottom sheet for all validation outcomes
//
// Implemented as a modal bottom sheet shown over the camera view.
// The camera remains mounted and active behind the sheet.
//
// RENDERS 7 DISTINCT LAYOUTS based on TicketValidationResult variant:
//
// ValidResult       → GREEN  header + holder name + ticket details + Done
// AlreadyUsedResult → AMBER  header + check-in audit info + Done
// WrongEventResult  → ORANGE header + event mismatch message + Done
// RevokedResult     → RED    header + revocation info + Done
// CancelledResult   → RED    header + cancellation info + Done
// InvalidResult     → RED    header + invalid message + Done
// ErrorResult       → RED    header + error message + Retry
//
// DESIGN PRINCIPLES:
// - Color fills the header to be visible at a glance
// - Holder name is the most prominent element on ValidResult
// - All deny-states are clearly red/amber so operators don't admit by mistake
// - Done button always returns to scanning
// - Retry button (ErrorResult only) allows immediate retry
// - Sheet is not dismissable by drag (prevents accidental dismissal)
// ============================================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/datetime_extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/info_row_widget.dart';
import '../models/ticket_validation_result.dart';

/// Modal bottom sheet that displays a ticket validation result.
///
/// Shown by [TicketScanScreen] when [ScannerState.status] is [ScanStatus.result].
///
/// [onDone]: called when operator taps "Done" — camera resumes.
/// [onRetry]: called when operator taps "Retry" (ErrorResult only).
class ScanResultSheet extends StatelessWidget {
  const ScanResultSheet({
    super.key,
    required this.result,
    required this.onDone,
    required this.onConfirmCheckin,
    required this.onRetry,
  });

  final TicketValidationResult result;
  final VoidCallback onDone;
  final Future<void> Function(int? admissionsToUse) onConfirmCheckin;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.borderPrimary,
              borderRadius: BorderRadius.circular(100),
            ),
          ),

          // Content — scrollable to handle long content on small screens.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Result-specific content.
                  switch (result) {
                    ValidResult() => _ValidContent(
                        result: result as ValidResult,
                        onDone: onDone,
                        onConfirmCheckin: onConfirmCheckin,
                      ),
                    AlreadyUsedResult() => _AlreadyUsedContent(
                        result: result as AlreadyUsedResult,
                        onDone: onDone,
                      ),
                    WrongEventResult() => _WrongEventContent(
                        result: result as WrongEventResult,
                        onDone: onDone,
                      ),
                    RevokedResult() => _RevokedContent(
                        result: result as RevokedResult,
                        onDone: onDone,
                      ),
                    CancelledResult() => _CancelledContent(
                        result: result as CancelledResult,
                        onDone: onDone,
                      ),
                    InvalidResult() => _InvalidContent(
                        result: result as InvalidResult,
                        onDone: onDone,
                      ),
                    ErrorResult() => _ErrorContent(
                        result: result as ErrorResult,
                        onDone: onDone,
                        onRetry: onRetry,
                      ),
                  },

                  // Bottom safe area padding.
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================

/// Colored header section used at the top of every result variant.
///
/// Contains: large icon, status title, optional subtitle.
class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        border: Border(
          bottom: BorderSide(color: color.withAlpha(60), width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(30),
              border: Border.all(color: color.withAlpha(100), width: 2),
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Padding wrapper for result content sections.
class _ContentPadding extends StatelessWidget {
  const _ContentPadding({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: child,
    );
  }
}

/// Standard info card used inside result sheets.
class _ResultInfoCard extends StatelessWidget {
  const _ResultInfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(children: children),
    );
  }
}

// ============================================================================
// RESULT 1 — VALID
// ============================================================================

class _ValidContent extends StatelessWidget {
  const _ValidContent({
    required this.result,
    required this.onDone,
    required this.onConfirmCheckin,
  });

  final ValidResult result;
  final VoidCallback onDone;
  final Future<void> Function(int? admissionsToUse) onConfirmCheckin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Green header ──────────────────────────────────────────────────
        _ResultHeader(
          color: AppColors.statusValid,
          icon: Icons.check_circle_rounded,
          title: 'VALID TICKET',
          subtitle: result.validationMessage.isNotEmpty
              ? result.validationMessage
              : 'Admit the holder',
        ),

        _ContentPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (result.admission.admissionProgressLabel != null) ...[
                _AdmissionProgressChip(
                  label: result.admission.admissionProgressLabel!,
                  color: AppColors.statusValid,
                ),
                const SizedBox(height: 12),
              ],

              // ── Holder name — most prominent element ──────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusValidSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.statusValidBorder,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'HOLDER',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result.holderName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.statusValid,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Category + Source badges ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _BadgeChip(
                      label: result.ticketCategory,
                      icon: Icons.confirmation_number_outlined,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BadgeChip(
                      label: result.ticketSourceType,
                      icon: _sourceIcon(result.ticketSourceType),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Ticket details ────────────────────────────────────────
              _ResultInfoCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        InfoRowWidget(
                          label: 'Order Ref',
                          value: result.orderReference,
                          icon: Icons.receipt_outlined,
                          monospace: true,
                          isLast: false,
                        ),
                        InfoRowWidget(
                          label: 'Ticket Ref',
                          value: result.ticketReference,
                          icon: Icons.qr_code_outlined,
                          monospace: true,
                          valueCopyable: true,
                          isLast: false,
                        ),
                        InfoRowWidget(
                          label: 'Event',
                          value: result.eventName,
                          icon: Icons.event_outlined,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (result.admission.isMultiAdmission &&
                  result.admissionsRemaining > 0) ...[
                _MultiAdmissionCheckinPanel(
                  maxSelectable: result.admissionsRemaining,
                  onConfirm: (count) => onConfirmCheckin(count),
                ),
                const SizedBox(height: 12),
              ],

              // ── Done button ───────────────────────────────────────────
              AppButton.primary(
                label: 'Done — Next Ticket',
                leadingIcon: Icons.arrow_forward_rounded,
                onPressed: onDone,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _sourceIcon(String sourceType) {
    switch (sourceType.toLowerCase()) {
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

class _MultiAdmissionCheckinPanel extends StatefulWidget {
  const _MultiAdmissionCheckinPanel({
    required this.maxSelectable,
    required this.onConfirm,
  });

  final int maxSelectable;
  final Future<void> Function(int admissionsToUse) onConfirm;

  @override
  State<_MultiAdmissionCheckinPanel> createState() =>
      _MultiAdmissionCheckinPanelState();
}

class _MultiAdmissionCheckinPanelState extends State<_MultiAdmissionCheckinPanel> {
  int _count = 1;
  bool _isSubmitting = false;

  @override
  void didUpdateWidget(covariant _MultiAdmissionCheckinPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_count > widget.maxSelectable) {
      _count = widget.maxSelectable.clamp(1, widget.maxSelectable);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm(_count);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int max = widget.maxSelectable <= 0 ? 1 : widget.maxSelectable;
    final int count = _count.clamp(1, max);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'FAMILY / MULTI-ENTRY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'How many are entering now?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _isSubmitting || count <= 1
                    ? null
                    : () => setState(() => _count = count - 1),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderPrimary),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSubmitting || count >= max
                    ? null
                    : () => setState(() => _count = count + 1),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Remaining available: $max',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          AppButton.primary(
            label: _isSubmitting ? 'Checking in…' : 'Check in $count person(s)',
            leadingIcon: _isSubmitting ? Icons.hourglass_top_rounded : Icons.groups_outlined,
            onPressed: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

/// Small colored chip for ticket category and source type.
class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RESULT 2 — ALREADY USED
// ============================================================================

class _AlreadyUsedContent extends StatelessWidget {
  const _AlreadyUsedContent({required this.result, required this.onDone});

  final AlreadyUsedResult result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final bool multiExhausted = result.admission.isMultiAdmission;
    final String title = multiExhausted
        ? 'ALL ADMISSIONS USED'
        : 'ALREADY CHECKED IN';
    final String defaultSubtitle = multiExhausted
        ? 'All admissions used'
        : 'Already checked in';
    final String subtitle = result.validationMessage.isNotEmpty
        ? result.validationMessage
        : defaultSubtitle;
    final String blockNotice = multiExhausted
        ? 'Do not admit. All admissions on this ticket have been used.'
        : 'Do not admit. Verify the holder\'s identity or contact event security.';

    final List<_InfoRowSpec> rowSpecs = [
      _InfoRowSpec(
        label: 'Ticket Ref',
        value: result.ticketReference,
        icon: Icons.qr_code_outlined,
        monospace: true,
      ),
      if (result.admission.admissionCounterLabel != null)
        _InfoRowSpec(
          label: 'Admissions',
          value: result.admission.admissionCounterLabel!,
          icon: Icons.groups_outlined,
          valueColor: AppColors.statusAlreadyUsed,
        ),
      if (result.checkedInAt != null)
        _InfoRowSpec(
          label: 'Checked In',
          value: result.checkedInAt!.formattedDateTime,
          icon: Icons.schedule_outlined,
          valueColor: AppColors.statusAlreadyUsed,
        ),
      if (result.checkedInByDevice != null)
        _InfoRowSpec(
          label: 'By Device',
          value: result.checkedInByDevice!,
          icon: Icons.smartphone_outlined,
        ),
      if (result.checkedInByUser != null)
        _InfoRowSpec(
          label: 'By User',
          value: result.checkedInByUser!,
          icon: Icons.person_outline,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultHeader(
          color: AppColors.statusAlreadyUsed,
          icon: Icons.warning_amber_rounded,
          title: title,
          subtitle: subtitle,
        ),
        _ContentPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (result.holderName != null && result.holderName!.isNotEmpty) ...[
                _HolderNameBanner(
                  name: result.holderName!,
                  color: AppColors.statusAlreadyUsed,
                ),
                const SizedBox(height: 12),
              ],
              _ResultInfoCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: _infoRowsFromSpecs(rowSpecs)),
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
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.statusAlreadyUsed, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        blockNotice,
                        style: const TextStyle(
                          color: AppColors.statusAlreadyUsed,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              AppButton.primary(
                label: 'Done',
                leadingIcon: Icons.close_rounded,
                onPressed: onDone,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// RESULT 3 — WRONG EVENT
// ============================================================================

class _WrongEventContent extends StatelessWidget {
  const _WrongEventContent({required this.result, required this.onDone});

  final WrongEventResult result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultHeader(
          color: AppColors.statusWrongEvent,
          icon: Icons.location_off_rounded,
          title: 'WRONG EVENT',
          subtitle: 'This ticket is for a different event',
        ),
        _ContentPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Message card.
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
                    Text(
                      result.message,
                      style: const TextStyle(
                        color: AppColors.statusWrongEvent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    if (result.actualEventName != null) ...[
                      const SizedBox(height: 10),
                      const Divider(
                          color: AppColors.statusWrongEventBorder, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.event_outlined,
                              color: AppColors.textTertiary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ticket is for: ${result.actualEventName}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (result.ticketReference.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.qr_code_outlined,
                              color: AppColors.textTertiary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            result.ticketReference,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Block notice.
              _BlockNotice(
                message: 'Entry blocked. Direct the holder to the '
                    'correct event entrance.',
                color: AppColors.statusWrongEvent,
              ),
              const SizedBox(height: 20),

              AppButton.primary(
                label: 'Done',
                leadingIcon: Icons.close_rounded,
                onPressed: onDone,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// RESULT 4 — REVOKED
// ============================================================================

class _RevokedContent extends StatelessWidget {
  const _RevokedContent({required this.result, required this.onDone});

  final RevokedResult result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return _DenyContent(
      color: AppColors.statusRevoked,
      icon: Icons.remove_circle_outline_rounded,
      title: 'TICKET REVOKED',
      subtitle: 'Entry denied by organizer',
      ticketReference: result.ticketReference,
      reason: result.reason,
      blockMessage: 'Entry blocked. This ticket has been revoked by the '
          'event organizer.',
      onDone: onDone,
    );
  }
}

// ============================================================================
// RESULT 5 — CANCELLED
// ============================================================================

class _CancelledContent extends StatelessWidget {
  const _CancelledContent({required this.result, required this.onDone});

  final CancelledResult result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return _DenyContent(
      color: AppColors.statusCancelled,
      icon: Icons.cancel_outlined,
      title: 'TICKET CANCELLED',
      subtitle: 'Order or ticket was cancelled',
      ticketReference: result.ticketReference,
      reason: result.reason,
      blockMessage: 'Entry blocked. This ticket has been cancelled.',
      onDone: onDone,
    );
  }
}

/// Shared layout for Revoked and Cancelled results.
class _DenyContent extends StatelessWidget {
  const _DenyContent({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ticketReference,
    required this.blockMessage,
    required this.onDone,
    this.reason,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String ticketReference;
  final String? reason;
  final String blockMessage;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultHeader(
          color: color,
          icon: icon,
          title: title,
          subtitle: subtitle,
        ),
        _ContentPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ResultInfoCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        InfoRowWidget(
                          label: 'Ticket Ref',
                          value: ticketReference,
                          icon: Icons.qr_code_outlined,
                          monospace: true,
                          isLast: reason == null,
                        ),
                        if (reason != null)
                          InfoRowWidget(
                            label: 'Reason',
                            value: reason!,
                            icon: Icons.info_outline_rounded,
                            isLast: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _BlockNotice(message: blockMessage, color: color),
              const SizedBox(height: 20),
              AppButton.primary(
                label: 'Done',
                leadingIcon: Icons.close_rounded,
                onPressed: onDone,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// RESULT 6 — INVALID
// ============================================================================

class _InvalidContent extends StatelessWidget {
  const _InvalidContent({required this.result, required this.onDone});

  final InvalidResult result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultHeader(
          color: AppColors.statusInvalid,
          icon: Icons.help_outline_rounded,
          title: 'INVALID TICKET',
          subtitle: 'This QR code was not recognized',
        ),
        _ContentPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.statusInvalidSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.statusInvalidBorder),
                ),
                child: Text(
                  result.message,
                  style: const TextStyle(
                    color: AppColors.statusInvalid,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BlockNotice(
                message: 'Entry denied. QR code not valid for this event.',
                color: AppColors.statusInvalid,
              ),
              const SizedBox(height: 20),
              AppButton.primary(
                label: 'Done',
                leadingIcon: Icons.close_rounded,
                onPressed: onDone,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// RESULT 7 — ERROR
// ============================================================================

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({
    required this.result,
    required this.onDone,
    required this.onRetry,
  });

  final ErrorResult result;
  final VoidCallback onDone;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultHeader(
          color: AppColors.error,
          icon: result.isNetworkError
              ? Icons.wifi_off_rounded
              : Icons.error_outline_rounded,
          title: 'SCAN ERROR',
          subtitle: result.isNetworkError
              ? 'Network connection issue'
              : 'Could not validate ticket',
        ),
        _ContentPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.errorBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.message,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    if (result.isNetworkError) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Check your internet connection and ensure the '
                        'scanner is connected to the correct network.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Retry button (primary for error state).
              AppButton.primary(
                label: 'Retry Scan',
                leadingIcon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
              const SizedBox(height: 10),
              AppButton.secondary(
                label: 'Cancel',
                onPressed: onDone,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SHARED — ADMISSION / HOLDER HELPERS
// ============================================================================

class _InfoRowSpec {
  const _InfoRowSpec({
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.monospace = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool monospace;
}

List<Widget> _infoRowsFromSpecs(List<_InfoRowSpec> specs) {
  return [
    for (var i = 0; i < specs.length; i++)
      InfoRowWidget(
        label: specs[i].label,
        value: specs[i].value,
        icon: specs[i].icon,
        valueColor: specs[i].valueColor,
        monospace: specs[i].monospace,
        isLast: i == specs.length - 1,
      ),
  ];
}

class _AdmissionProgressChip extends StatelessWidget {
  const _AdmissionProgressChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HolderNameBanner extends StatelessWidget {
  const _HolderNameBanner({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED — BLOCK NOTICE
// ============================================================================

/// Red/colored notice bar indicating entry is blocked.
///
/// Shown on all denial states to make it visually unmistakable.
class _BlockNotice extends StatelessWidget {
  const _BlockNotice({
    required this.message,
    required this.color,
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.block_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}