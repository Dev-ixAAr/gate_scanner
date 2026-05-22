// ============================================================================
// Scanner Home Screen — Main dashboard for active scanner sessions
//
// Shown when a valid scanner session exists (router guard confirmed).
//
// LAYOUT (top to bottom):
// ┌─────────────────────────────────┐
// │  AppBar: "Gate Scanner" | ⚙     │
// ├─────────────────────────────────┤
// │  [Session Status Card]          │
// │  ● Session Active / ✗ Error     │
// ├─────────────────────────────────┤
// │  [Event Info Card]              │
// │  Connected Event: Summer Fest   │
// │  Event Ref: EVT-2024-001        │
// ├─────────────────────────────────┤
// │  [Connection Card]              │
// │  Server: tickets.company.com    │
// │  Device: Samsung SM-A536B       │
// ├─────────────────────────────────┤
// │  [Session Card]                 │
// │  Session Started: Jul 15, 8:30  │
// │  Last Verified: 2 minutes ago   │
// ├─────────────────────────────────┤
// │  [Start Scanning] (green)       │
// │  [Manual Search]  (outlined)    │
// └─────────────────────────────────┘
//
// SESSION REFRESH:
// - On first build: refreshSessionStatus() called after frame
// - On AppLifecycleState.resumed: refreshSessionStatus() called
// - 401 from refresh: SessionRevokeInterceptor handles redirect
//
// PULL TO REFRESH:
// - RefreshIndicator wraps the scroll content
// - Calls refreshSessionStatus() manually
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/session_data.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/datetime_extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/info_row_widget.dart';
import '../providers/home_provider.dart';

/// Main dashboard screen for the gate scanner.
///
/// Shown when a scanner session is active.
/// Provides access to ticket scanning, manual search, and settings.
class ScannerHomeScreen extends ConsumerStatefulWidget {
  const ScannerHomeScreen({super.key});

  @override
  ConsumerState<ScannerHomeScreen> createState() => _ScannerHomeScreenState();
}

class _ScannerHomeScreenState extends ConsumerState<ScannerHomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Trigger session status check after the first frame renders.
    // This ensures the UI is visible before the network request starts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Handles app lifecycle changes.
  ///
  /// On resume: check if the session is still valid.
  /// The scanner may have been used in the background, or the admin
  /// may have revoked the session while the app was backgrounded.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshSession();
    }
  }

  /// Calls [HomeNotifier.refreshSessionStatus] and handles navigation.
  Future<void> _refreshSession() async {
    // Read (not watch) — we're calling a method, not rebuilding on state.
    await ref.read(homeProvider.notifier).refreshSessionStatus();
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: _buildAppBar(context),
      body: homeAsync.when(
        loading: () => const _HomeLoadingView(),
        error: (error, stack) => _HomeErrorView(
          error: error,
          onRetry: () => ref.refresh(homeProvider),
        ),
        data: (homeState) => _HomeContent(
          homeState: homeState,
          onRefresh: _refreshSession,
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Gate Scanner'),
      automaticallyImplyLeading: false,
      actions: [
        // Session refresh indicator — shown when checking status.
        Consumer(
          builder: (context, ref, _) {
            final homeAsync = ref.watch(homeProvider);
            final isRefreshing = homeAsync.whenOrNull(
                  data: (state) => state.isRefreshing,
                ) ??
                false;

            if (isRefreshing) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.brandPrimary,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Settings navigation button.
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.go(RouteNames.settings),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ============================================================================
// HOME CONTENT — The main scrollable body
// ============================================================================

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.homeState,
    required this.onRefresh,
  });

  final HomeState homeState;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.brandPrimary,
      backgroundColor: AppColors.backgroundSecondary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Session Status Card ──────────────────────────────────
                _SessionStatusCard(homeState: homeState),
                const SizedBox(height: 16),

                // ── Event Info Card ──────────────────────────────────────
                _EventInfoCard(session: homeState.session),
                const SizedBox(height: 16),

                // ── Connection Card ──────────────────────────────────────
                _ConnectionCard(session: homeState.session),
                const SizedBox(height: 16),

                // ── Session Time Card ────────────────────────────────────
                _SessionTimeCard(homeState: homeState),
                const SizedBox(height: 32),

                // ── Action Buttons ───────────────────────────────────────
                _ActionButtons(),
                const SizedBox(height: 24),

                // ── Pull to refresh hint ─────────────────────────────────
                const Center(
                  child: Text(
                    'Pull down to refresh session status',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SESSION STATUS CARD
// ============================================================================

class _SessionStatusCard extends StatelessWidget {
  const _SessionStatusCard({required this.homeState});

  final HomeState homeState;

  @override
  Widget build(BuildContext context) {
    final SessionHealthStatus status = homeState.sessionStatus;
    final bool isActive = homeState.isSessionActive;
    final bool isChecking = homeState.isRefreshing;
    final bool hasError = homeState.hasRefreshError;

    // Determine visual configuration from status.
    final Color dotColor;
    final Color cardBorderColor;
    final Color cardBackgroundColor;
    final String statusLabel;
    final String statusDetail;
    final IconData statusIcon;

    if (isChecking) {
      dotColor = AppColors.info;
      cardBorderColor = AppColors.infoBorder;
      cardBackgroundColor = AppColors.infoSurface;
      statusLabel = 'Checking...';
      statusDetail = 'Verifying session with server';
      statusIcon = Icons.sync_rounded;
    } else if (isActive) {
      dotColor = AppColors.statusValid;
      cardBorderColor = AppColors.statusValidBorder;
      cardBackgroundColor = AppColors.statusValidSurface;
      statusLabel = 'Session Active';
      statusDetail = homeState.lastRefreshedAt != null
          ? 'Verified ${homeState.lastRefreshedAt!.relativeTime}'
          : 'Connected and ready to scan';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (hasError || status == SessionHealthStatus.error) {
      dotColor = AppColors.warning;
      cardBorderColor = AppColors.warningBorder;
      cardBackgroundColor = AppColors.warningSurface;
      statusLabel = 'Connection Warning';
      statusDetail = homeState.refreshError ??
          'Cannot verify session. Check your network.';
      statusIcon = Icons.warning_amber_rounded;
    } else if (status == SessionHealthStatus.revoked) {
      dotColor = AppColors.error;
      cardBorderColor = AppColors.errorBorder;
      cardBackgroundColor = AppColors.errorSurface;
      statusLabel = 'Session Revoked';
      statusDetail = 'Redirecting to setup...';
      statusIcon = Icons.cancel_outlined;
    } else {
      // Unknown — initial state before first check.
      dotColor = AppColors.textTertiary;
      cardBorderColor = AppColors.borderPrimary;
      cardBackgroundColor = AppColors.backgroundSecondary;
      statusLabel = 'Status Unknown';
      statusDetail = 'Checking session status...';
      statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorderColor, width: 1.5),
      ),
      child: Row(
        children: [
          // Status icon with animated checking indicator.
          if (isChecking)
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(dotColor),
              ),
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor.withAlpha(30),
              ),
              child: Icon(statusIcon, color: dotColor, size: 20),
            ),
          const SizedBox(width: 14),

          // Status text.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: dotColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusDetail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Pulsing dot indicator.
          _PulsingDot(color: dotColor, isActive: isActive || isChecking),
        ],
      ),
    );
  }
}

/// An animated pulsing dot indicator.
///
/// Pulses when active (session confirmed) to indicate "live" status.
/// Static when inactive, checking, or errored.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({
    required this.color,
    required this.isActive,
  });

  final Color color;
  final bool isActive;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withAlpha(
              (255 * _animation.value).round(),
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: widget.color.withAlpha(80),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}

// ============================================================================
// EVENT INFO CARD
// ============================================================================

class _EventInfoCard extends StatelessWidget {
  const _EventInfoCard({required this.session});

  final SessionData session;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Connected Event',
      children: [
        // Event name — large and prominent.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            session.eventName,
            style: const TextStyle(
              color: AppColors.brandPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
        const Divider(color: AppColors.borderSecondary, height: 1),
        const SizedBox(height: 4),
        InfoRowWidget(
          label: 'Event Reference',
          value: session.eventPublicRef,
          isLast: true,
          monospace: true,
        ),
      ],
    );
  }
}

// ============================================================================
// CONNECTION CARD
// ============================================================================

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.session});

  final SessionData session;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Connection',
      children: [
        InfoRowWidget(
          label: 'Server',
          value: session.serverUrlDisplay,
          icon: Icons.dns_outlined,
          valueCopyable: true,
          isLast: false,
        ),
        InfoRowWidget(
          label: 'Device',
          value: session.deviceName,
          icon: Icons.smartphone_outlined,
          isLast: true,
        ),
      ],
    );
  }
}

// ============================================================================
// SESSION TIME CARD
// ============================================================================

class _SessionTimeCard extends StatelessWidget {
  const _SessionTimeCard({required this.homeState});

  final HomeState homeState;

  @override
  Widget build(BuildContext context) {
    final DateTime started = homeState.session.sessionStartedAt;
    final DateTime? lastVerified = homeState.lastRefreshedAt;

    // Calculate session duration.
    final Duration sessionDuration = DateTime.now().difference(started);
    final String durationText = _formatDuration(sessionDuration);

    return AppSectionCard(
      title: 'Session Info',
      children: [
        InfoRowWidget(
          label: 'Started',
          value: started.formattedDateTime,
          icon: Icons.schedule_outlined,
          isLast: false,
        ),
        InfoRowWidget(
          label: 'Duration',
          value: durationText,
          icon: Icons.timer_outlined,
          isLast: lastVerified == null,
        ),
        if (lastVerified != null)
          InfoRowWidget(
            label: 'Last Verified',
            value: lastVerified.relativeTime,
            icon: Icons.verified_outlined,
            valueColor: AppColors.brandPrimary,
            isLast: true,
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) return 'Just started';
    if (duration.inHours < 1) {
      final mins = duration.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'}';
    }
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);
    if (mins == 0) return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    return '$hours ${hours == 1 ? 'hour' : 'hours'} $mins min';
  }
}

// ============================================================================
// ACTION BUTTONS
// ============================================================================

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary — Start Scanning
        SizedBox(
          height: 58,
          child: ElevatedButton.icon(
            onPressed: () => context.go(RouteNames.scan),
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 22,
              color: AppColors.textInverse,
            ),
            label: const Text(
              'Start Scanning',
              style: TextStyle(
                color: AppColors.textInverse,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary — Manual Search
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => context.go(RouteNames.manualSearch),
            icon: const Icon(Icons.search_rounded, size: 20),
            label: const Text(
              'Manual Search',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// LOADING VIEW — Shown while HomeNotifier.build() is in progress
// ============================================================================

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

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
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading session...',
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
// ERROR VIEW — Shown when HomeNotifier.build() throws (session not found)
// ============================================================================

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final String message = error is SessionNotFoundError
        ? 'No active session found. Please complete the setup process.'
        : 'Failed to load session data. Please try again.';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 56,
          ),
          const SizedBox(height: 20),
          const Text(
            'Session Error',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AppButton.primary(
            label: 'Retry',
            leadingIcon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
          const SizedBox(height: 12),
          AppButton.secondary(
            label: 'Go to Setup',
            leadingIcon: Icons.qr_code_scanner_rounded,
            onPressed: () => context.go(RouteNames.setup),
          ),
        ],
      ),
    );
  }
}