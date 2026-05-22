// ============================================================================
// Session Settings Screen — Device info, session info, and action buttons
//
// LAYOUT (top to bottom):
// ┌──────────────────────────────────────┐
// │  AppBar: "Scanner Settings"  ←       │
// ├──────────────────────────────────────┤
// │  [Device Info Section]               │
// │  Device Name, Brand/Model, OS, App   │
// ├──────────────────────────────────────┤
// │  [Session Info Section]              │
// │  Event Name, Ref, Server, Started At │
// ├──────────────────────────────────────┤
// │  [Actions Section]                   │
// │  [Switch Event] (outlined/info)      │
// │  [Logout Session] (outlined/warning) │
// │  [Reset Event Binding] (red/filled)  │
// └──────────────────────────────────────┘
//
// LOADING BEHAVIOR:
// - While an action is in progress: that button shows a spinner
// - Other buttons are disabled
// - A full loading overlay is shown for clarity
//
// ERROR BEHAVIOR:
// - Error SnackBar shown at bottom
// - State resets to idle on dismissal
// - User can retry the action
//
// NAVIGATION:
// - Back button → /home
// - After any action completes → router redirects to /setup automatically
//   (no explicit navigation needed — routerRefreshNotifier handles it)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/device_info_model.dart';
import '../../../core/models/session_data.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/app_info_service.dart';
import '../../../core/services/device_info_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/datetime_extensions.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_screen_background.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/info_row_widget.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/settings_provider.dart';

/// Scanner session settings and device information screen.
class SessionSettingsScreen extends ConsumerStatefulWidget {
  const SessionSettingsScreen({super.key});

  @override
  ConsumerState<SessionSettingsScreen> createState() =>
      _SessionSettingsScreenState();
}

class _SessionSettingsScreenState
    extends ConsumerState<SessionSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Reset settings state when entering screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).resetError();
    });
  }

  // --------------------------------------------------------------------------
  // ACTION HANDLERS
  // --------------------------------------------------------------------------

  Future<void> _onSwitchEvent() async {
    final bool? confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Switch Event',
      message:
          'This will disconnect this scanner from the current event. '
          'You will need to scan a new setup QR code to connect to a different event.',
      confirmLabel: 'Switch Event',
      cancelLabel: 'Cancel',
      isDestructive: false,
      icon: Icons.swap_horiz_rounded,
    );

    if (confirmed != true || !mounted) return;
    await ref.read(settingsProvider.notifier).switchEvent();
  }

  Future<void> _onLogoutSession() async {
    final bool? confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Logout Scanner Session',
      message:
          'This will end your current scanner session on the server and '
          'disconnect this device. You will need to scan a new setup QR '
          'code to scan tickets again.',
      confirmLabel: 'Logout',
      cancelLabel: 'Cancel',
      isDestructive: false,
      icon: Icons.logout_rounded,
      additionalContent: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warningBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: AppColors.warning, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This will notify the server to invalidate the session.',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(settingsProvider.notifier).logoutSession();
  }

  Future<void> _onResetEventBinding() async {
    final bool? confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Reset Event Binding',
      message:
          'This will permanently clear all local session data from this '
          'device. The server session will NOT be notified. '
          'You must scan a new setup QR code to use this scanner again.',
      confirmLabel: 'Reset Binding',
      cancelLabel: 'Cancel',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
      additionalContent: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.errorBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This action cannot be undone. Use only when the session '
                'is already invalid or the server is unreachable.',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(settingsProvider.notifier).resetEventBinding();
  }

  // --------------------------------------------------------------------------
  // ERROR HANDLING
  // --------------------------------------------------------------------------

  void _handleSettingsStateChange(
    SettingsState? previous,
    SettingsState next,
  ) {
    if (next is SettingsErrorState) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    next.message,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.backgroundTertiary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.errorBorder),
            ),
            duration: const Duration(seconds: 5),
          ),
        ).closed.then((_) {
          if (mounted) {
            ref.read(settingsProvider.notifier).resetError();
          }
        });
    }
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen<SettingsState>(settingsProvider, _handleSettingsStateChange);

    final settingsState = ref.watch(settingsProvider);
    final bool isLoading = settingsState is SettingsLoadingState;

    final sessionAsync = ref.watch(sessionDataProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Scanner Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: isLoading ? null : () => context.go(RouteNames.home),
          tooltip: 'Back',
        ),
      ),
      body: AppScreenBackground(
        child: Stack(
        children: [
          // ── Main content ─────────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Device Info Section ─────────────────────────────────────
                _DeviceInfoSection(),
                const SizedBox(height: 16),

                // ── Session Info Section ────────────────────────────────────
                sessionAsync.when(
                  loading: () => const _SessionInfoLoadingCard(),
                  error: (_, __) => const _SessionInfoErrorCard(),
                  data: (session) => session != null
                      ? _SessionInfoSection(session: session)
                      : const _SessionInfoErrorCard(),
                ),
                const SizedBox(height: 24),

                // ── Actions Section ─────────────────────────────────────────
                _ActionsSection(
                  settingsState: settingsState,
                  onSwitchEvent: isLoading ? null : _onSwitchEvent,
                  onLogout: isLoading ? null : _onLogoutSession,
                  onReset: isLoading ? null : _onResetEventBinding,
                ),
                const SizedBox(height: 32),

                // ── App info footer ─────────────────────────────────────────
                _AppFooter(),
              ],
            ),
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (isLoading)
            LoadingOverlay(
              message: _loadingMessage(settingsState as SettingsLoadingState),
            ),
        ],
        ),
      ),
    );
  }

  String _loadingMessage(SettingsLoadingState state) {
    switch (state.action) {
      case SettingsAction.logout:
        return 'Logging out session...';
      case SettingsAction.reset:
        return 'Resetting event binding...';
      case SettingsAction.switchEvent:
        return 'Disconnecting from event...';
    }
  }
}

// ============================================================================
// DEVICE INFO SECTION
// ============================================================================

class _DeviceInfoSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceInfoService deviceInfoService =
        ref.read(deviceInfoServiceProvider);
    final AppInfoService appInfoService = ref.read(appInfoServiceProvider);

    return FutureBuilder<DeviceInfoModel>(
      future: deviceInfoService.getDeviceInfo(),
      builder: (context, deviceSnapshot) {
        return FutureBuilder<String>(
          future: appInfoService.getVersionDisplay(),
          builder: (context, versionSnapshot) {
            final deviceInfo = deviceSnapshot.data;
            final versionDisplay =
                versionSnapshot.data ?? 'Loading...';

            return AppSectionCard(
              title: 'Device Information',
              children: [
                CompactInfoRow(
                  label: 'Device Name',
                  value: deviceInfo?.deviceName ?? '—',
                  icon: Icons.smartphone_outlined,
                  isLast: false,
                ),
                CompactInfoRow(
                  label: 'Brand / Model',
                  value: deviceInfo != null
                      ? '${deviceInfo.deviceBrand} ${deviceInfo.deviceModel}'
                      : '—',
                  icon: Icons.devices_outlined,
                  isLast: false,
                ),
                CompactInfoRow(
                  label: 'OS',
                  value: deviceInfo != null
                      ? '${deviceInfo.operatingSystem} ${deviceInfo.osVersion}'
                      : '—',
                  icon: Icons.android_rounded,
                  isLast: false,
                ),
                CompactInfoRow(
                  label: 'App Version',
                  value: versionDisplay,
                  icon: Icons.info_outline_rounded,
                  isLast: true,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// SESSION INFO SECTION
// ============================================================================

class _SessionInfoSection extends StatelessWidget {
  const _SessionInfoSection({required this.session});

  final SessionData session;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Active Session',
      children: [
        CompactInfoRow(
          label: 'Event Name',
          value: session.eventName,
          icon: Icons.event_outlined,
          isLast: false,
        ),
        CompactInfoRow(
          label: 'Event Ref',
          value: session.eventPublicRef,
          icon: Icons.tag_outlined,
          isLast: false,
          monospace: true,
        ),
        CompactInfoRow(
          label: 'Server',
          value: session.serverUrlDisplay,
          icon: Icons.dns_outlined,
          isLast: false,
        ),
        CompactInfoRow(
          label: 'Device Name',
          value: session.deviceName,
          icon: Icons.badge_outlined,
          isLast: false,
        ),
        CompactInfoRow(
          label: 'Session Started',
          value: session.sessionStartedAt.formattedDateTime,
          icon: Icons.schedule_outlined,
          isLast: true,
        ),
      ],
    );
  }
}

class _SessionInfoLoadingCard extends StatelessWidget {
  const _SessionInfoLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
          ),
        ),
      ),
    );
  }
}

class _SessionInfoErrorCard extends StatelessWidget {
  const _SessionInfoErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.textTertiary, size: 20),
          SizedBox(width: 10),
          Text(
            'Session data unavailable',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACTIONS SECTION
// ============================================================================

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.settingsState,
    required this.onSwitchEvent,
    required this.onLogout,
    required this.onReset,
  });

  final SettingsState settingsState;
  final VoidCallback? onSwitchEvent;
  final VoidCallback? onLogout;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final bool isSwitchLoading = settingsState is SettingsLoadingState &&
        (settingsState as SettingsLoadingState).action ==
            SettingsAction.switchEvent;
    final bool isLogoutLoading = settingsState is SettingsLoadingState &&
        (settingsState as SettingsLoadingState).action ==
            SettingsAction.logout;
    final bool isResetLoading = settingsState is SettingsLoadingState &&
        (settingsState as SettingsLoadingState).action ==
            SettingsAction.reset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'ACTIONS',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
        ),

        // ── Switch Event ────────────────────────────────────────────────────
        _ActionButton(
          label: 'Switch Event',
          description: 'Connect to a different event by scanning a new setup QR',
          icon: Icons.swap_horiz_rounded,
          color: AppColors.info,
          isLoading: isSwitchLoading,
          onPressed: onSwitchEvent,
          style: _ActionButtonStyle.outlined,
        ),
        const SizedBox(height: 12),

        // ── Logout Session ──────────────────────────────────────────────────
        _ActionButton(
          label: 'Logout Scanner Session',
          description: 'End the session on the server and disconnect this device',
          icon: Icons.logout_rounded,
          color: AppColors.warning,
          isLoading: isLogoutLoading,
          onPressed: onLogout,
          style: _ActionButtonStyle.outlined,
        ),
        const SizedBox(height: 12),

        // ── Reset Event Binding ─────────────────────────────────────────────
        _ActionButton(
          label: 'Reset Event Binding',
          description: 'Clear all local session data (use when server is unreachable)',
          icon: Icons.delete_forever_rounded,
          color: AppColors.error,
          isLoading: isResetLoading,
          onPressed: onReset,
          style: _ActionButtonStyle.filled,
        ),
      ],
    );
  }
}

// ============================================================================
// ACTION BUTTON — Unified styled button for settings actions
// ============================================================================

enum _ActionButtonStyle { outlined, filled }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
    required this.style,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;
  final _ActionButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    final Color effectiveColor =
        isDisabled ? AppColors.textDisabled : color;

    final Widget content = Row(
      children: [
        // Leading icon or loading spinner.
        SizedBox(
          width: 24,
          height: 24,
          child: isLoading
              ? CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    style == _ActionButtonStyle.filled
                        ? Colors.white
                        : effectiveColor,
                  ),
                )
              : Icon(
                  icon,
                  size: 22,
                  color: style == _ActionButtonStyle.filled && !isDisabled
                      ? Colors.white
                      : effectiveColor,
                ),
        ),
        const SizedBox(width: 14),

        // Label and description.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: style == _ActionButtonStyle.filled && !isDisabled
                      ? Colors.white
                      : effectiveColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: isDisabled
                      ? AppColors.textDisabled
                      : (style == _ActionButtonStyle.filled
                          ? Colors.white70
                          : AppColors.textTertiary),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        // Trailing arrow.
        if (!isLoading)
          Icon(
            Icons.chevron_right_rounded,
            color: isDisabled ? AppColors.textDisabled : effectiveColor,
            size: 20,
          ),
      ],
    );

    if (style == _ActionButtonStyle.filled) {
      return Material(
        color: isDisabled ? AppColors.backgroundTertiary : color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isDisabled || isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: content,
          ),
        ),
      );
    }

    // Outlined style.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isDisabled || isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled ? AppColors.borderPrimary : effectiveColor,
              width: 1.5,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

// ============================================================================
// APP FOOTER — version and legal info
// ============================================================================

class _AppFooter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfoService = ref.read(appInfoServiceProvider);

    return FutureBuilder<String>(
      future: appInfoService.getVersionDisplay(),
      builder: (context, snapshot) {
        final version = snapshot.data ?? '';
        return Column(
          children: [
            const Divider(color: AppColors.borderSecondary),
            const SizedBox(height: 12),
            Text(
              'Gate Scanner $version',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'All validation is server-verified.\n'
              'This device stores session data encrypted.',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}