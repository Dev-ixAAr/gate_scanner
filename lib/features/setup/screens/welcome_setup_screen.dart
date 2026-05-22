// ============================================================================
// Welcome Setup Screen — First screen for unconfigured scanners
//
// Shown when the router guard detects no active session.
// Guides the operator to scan the admin setup QR code.
//
// DESIGN:
// - Dark background matching the scanner theme
// - Large scan icon to immediately communicate purpose
// - Clear single call-to-action button
// - Version shown at bottom for support purposes
//
// NAVIGATION:
// - "Scan Setup QR" button → /setup/scan (SetupQrScanScreen)
// - No back button (this is the root screen when no session exists)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/app_info_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';

/// Welcome/setup screen for unconfigured gate scanner devices.
///
/// This is the entry point of the app when no scanner session exists.
/// The operator must complete the setup QR scan flow before any other
/// feature is accessible.
class WelcomeSetupScreen extends ConsumerWidget {
  const WelcomeSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      // No AppBar — this is a full-screen welcome/onboarding screen.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingHorizontal,
            vertical: AppConstants.screenPaddingVertical,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top spacer — pushes content down from status bar.
              const SizedBox(height: 24),

              // ----------------------------------------------------------------
              // CENTER CONTENT — logo, title, subtitle
              // ----------------------------------------------------------------
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo / icon
                    _AppLogo(),
                    const SizedBox(height: 40),

                    // App name
                    const Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    const Text(
                      'Scan your admin setup QR code to get started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Setup instruction steps
                    _SetupSteps(),
                  ],
                ),
              ),

              // ----------------------------------------------------------------
              // BOTTOM CONTENT — scan button + version
              // ----------------------------------------------------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Primary CTA button
                  AppButton.primary(
                    label: 'Scan Setup QR Code',
                    leadingIcon: Icons.qr_code_scanner_rounded,
                    onPressed: () => context.go(RouteNames.setupScan),
                  ),
                  const SizedBox(height: 24),

                  // App version display
                  _VersionText(ref: ref),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PRIVATE WIDGETS
// ============================================================================

/// Animated app logo with scanner icon and glow effect.
class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandPrimarySurface,
          border: Border.all(
            color: AppColors.brandPrimaryBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPrimary.withAlpha(40),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: AppColors.brandPrimary,
          size: 60,
        ),
      ),
    );
  }
}

/// Three-step setup instruction list.
///
/// Shows the operator what to expect before tapping the scan button.
class _SetupSteps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW TO GET STARTED',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _StepRow(
            step: 1,
            text: 'Get the setup QR from your admin panel',
          ),
          const SizedBox(height: 14),
          _StepRow(
            step: 2,
            text: 'Tap the button below and scan the QR code',
          ),
          const SizedBox(height: 14),
          _StepRow(
            step: 3,
            text: 'Confirm the event details and start scanning tickets',
          ),
        ],
      ),
    );
  }
}

/// A single numbered step row in the setup instructions.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.text});

  final int step;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number badge
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brandPrimarySurface,
            border: Border.all(color: AppColors.brandPrimaryBorder),
          ),
          child: Text(
            '$step',
            style: const TextStyle(
              color: AppColors.brandPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Step text
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// App version text displayed at the bottom of the screen.
///
/// Reads version asynchronously from [AppInfoService].
/// Shows a placeholder while loading.
class _VersionText extends StatelessWidget {
  const _VersionText({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final appInfoService = ref.read(appInfoServiceProvider);

    return FutureBuilder<String>(
      future: appInfoService.getVersionDisplay(),
      builder: (context, snapshot) {
        final version = snapshot.data ?? AppConstants.fallbackVersion;
        return Text(
          '${AppConstants.appName} $version',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        );
      },
    );
  }
}