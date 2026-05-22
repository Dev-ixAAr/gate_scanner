import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/datetime_extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/setup_qr_payload.dart';

/// Bottom sheet shown before connecting to an event (QR scan or manual entry).
class SetupConfirmationSheet extends StatelessWidget {
  const SetupConfirmationSheet({
    required this.payload,
    required this.isLoading,
    required this.onConfirm,
    required this.onCancel,
    this.cancelLabel = 'Scan Again',
    super.key,
  });

  final SetupQrPayload payload;
  final bool isLoading;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String cancelLabel;

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
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.borderPrimary,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.brandPrimaryBorder),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.brandPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payload.isManualEntry
                                ? 'Review Setup Details'
                                : 'Setup QR Detected',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Review the details below before connecting',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderPrimary),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Server',
                        value: payload.serverUrlDisplay,
                        icon: Icons.dns_outlined,
                        isLast: false,
                      ),
                      _DetailRow(
                        label: 'Event Ref',
                        value: payload.eventPublicRef,
                        icon: Icons.event_outlined,
                        isLast: payload.isManualEntry,
                      ),
                      if (!payload.isManualEntry)
                        _DetailRow(
                          label: 'Expires',
                          value: payload.isExpired
                              ? 'EXPIRED'
                              : payload.expiresAt.formattedDateTime,
                          icon: Icons.schedule_outlined,
                          isLast: true,
                          valueColor: payload.isExpired
                              ? AppColors.error
                              : (payload.minutesUntilExpiry < 10
                                  ? AppColors.warning
                                  : AppColors.textPrimary),
                        ),
                    ],
                  ),
                ),
                if (!payload.isManualEntry &&
                    !payload.isExpired &&
                    payload.minutesUntilExpiry < 10) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warningBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This QR code expires in ${payload.minutesUntilExpiry} '
                            '${payload.minutesUntilExpiry == 1 ? 'minute' : 'minutes'}. '
                            'Connect quickly.',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton.primary(
                  label: isLoading ? 'Connecting...' : 'Connect to Event',
                  leadingIcon: isLoading ? null : Icons.link_rounded,
                  isLoading: isLoading,
                  onPressed: payload.isExpired ? null : onConfirm,
                ),
                const SizedBox(height: 12),
                AppButton.secondary(
                  label: cancelLabel,
                  leadingIcon: payload.isManualEntry
                      ? Icons.edit_outlined
                      : Icons.qr_code_scanner_rounded,
                  onPressed: isLoading ? null : onCancel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.isLast,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isLast;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (isLast) return row;
    return Column(
      children: [
        row,
        const Divider(
          color: AppColors.borderSecondary,
          height: 1,
          thickness: 1,
        ),
      ],
    );
  }
}
