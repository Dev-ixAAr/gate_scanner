// ============================================================================
// Setup QR Scan Screen — Camera view for scanning the admin setup QR code
//
// FEATURES:
// - Full-screen camera using mobile_scanner
// - QR scanner overlay with corner markers and animated scan line
// - Runtime camera permission check via permission_handler
// - QR detection → JSON parse → validation → confirmation bottom sheet
// - Torch (flashlight) toggle
// - Back navigation to WelcomeSetupScreen
//
// STATE MACHINE (via SetupQrScanNotifier):
//   idle → camera scanning
//   processing → QR detected, parsing
//   parsed(payload) → show confirmation bottom sheet
//   error(message) → show snackbar, resume scanning
//
// PHASE 4 NOTE:
// The "Confirm" button in the bottom sheet calls a placeholder method.
// Phase 5 wires this to the actual token exchange API call.
//
// CAMERA PERMISSION HANDLING:
// - First check current permission status
// - If denied/undetermined: show permission request dialog
// - If permanentlyDenied: show settings redirect UI
// - If granted: start camera
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/datetime_extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/qr_scanner_overlay.dart';
import '../models/setup_qr_payload.dart';
import '../providers/setup_provider.dart';

/// Full-screen camera view for scanning the admin setup QR code.
///
/// Manages camera lifecycle (start/stop/dispose) and permission state.
/// Delegates QR parsing and state management to [SetupQrScanNotifier].
class SetupQrScanScreen extends ConsumerStatefulWidget {
  const SetupQrScanScreen({super.key});

  @override
  ConsumerState<SetupQrScanScreen> createState() => _SetupQrScanScreenState();
}

class _SetupQrScanScreenState extends ConsumerState<SetupQrScanScreen>
    with WidgetsBindingObserver {
  // --------------------------------------------------------------------------
  // STATE
  // --------------------------------------------------------------------------

  /// MobileScanner controller — manages camera start/stop/torch.
  MobileScannerController? _scannerController;

  /// Current permission status. Null until the first check.
  PermissionStatus? _permissionStatus;

  /// Whether the permission check is in progress.
  bool _isCheckingPermission = true;

  /// Whether the torch is currently on.
  bool _isTorchOn = false;

  /// Whether a bottom sheet is currently shown (prevents duplicate sheets).
  bool _isBottomSheetVisible = false;

  // --------------------------------------------------------------------------
  // LIFECYCLE
  // --------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check camera permission when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCameraPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController?.dispose();
    super.dispose();
  }

  /// Handles app lifecycle changes (foreground/background).
  ///
  /// When the user returns from the system settings app (after granting
  /// camera permission there), re-check permission and start the camera.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Re-check permission — user may have granted it in settings.
      _checkCameraPermission();
    }
    if (state == AppLifecycleState.paused) {
      // Stop camera when app goes to background to save resources.
      _scannerController?.stop();
    }
  }

  // --------------------------------------------------------------------------
  // CAMERA PERMISSION
  // --------------------------------------------------------------------------

  /// Checks the current camera permission status and initializes the camera
  /// if permission is granted.
  Future<void> _checkCameraPermission() async {
    final PermissionStatus status = await Permission.camera.status;

    if (!mounted) return;

    setState(() {
      _permissionStatus = status;
      _isCheckingPermission = false;
    });

    if (status.isGranted) {
      _initializeCamera();
    }
  }

  /// Requests camera permission from the user.
  ///
  /// Called when the permission status is [denied] (not permanently denied).
  Future<void> _requestCameraPermission() async {
    setState(() => _isCheckingPermission = true);

    final PermissionStatus status = await Permission.camera.request();

    if (!mounted) return;

    setState(() {
      _permissionStatus = status;
      _isCheckingPermission = false;
    });

    if (status.isGranted) {
      _initializeCamera();
    }
  }

  /// Opens the device app settings page so the user can grant permission there.
  ///
  /// Used when permission is permanently denied (user tapped "Don't ask again").
  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  // --------------------------------------------------------------------------
  // CAMERA MANAGEMENT
  // --------------------------------------------------------------------------

  /// Creates and starts the MobileScanner controller.
  ///
  /// Called once after camera permission is confirmed.
  /// The controller is created fresh each time (not reused across
  /// screen reconstructions) to prevent stale camera state.
  void _initializeCamera() {
    // Dispose any existing controller before creating a new one.
    _scannerController?.dispose();

    _scannerController = MobileScannerController(
      // Facing: back camera for scanning.
      facing: CameraFacing.back,
      // Torch mode: off by default, user can toggle.
      torchEnabled: false,
      // Detection speed: normal gives best balance of speed and accuracy.
      detectionSpeed: DetectionSpeed.normal,
      // Only detect QR codes — not other barcode formats.
      formats: const [BarcodeFormat.qrCode],
      // Return the barcode image for better detection accuracy.
      returnImage: false,
    );

    setState(() {
      _isTorchOn = false;
    });
  }

  /// Toggles the camera torch on and off.
  Future<void> _toggleTorch() async {
    if (_scannerController == null) return;
    await _scannerController!.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  /// Stops the camera scanner.
  ///
  /// Called when a QR is detected (camera pauses while processing/confirming).
  void _pauseScanner() {
    _scannerController?.stop();
  }

  /// Resumes the camera scanner.
  ///
  /// Called when the user cancels the confirmation sheet or
  /// after an error is shown.
  Future<void> _resumeScanner() async {
    await _scannerController?.start();
  }

  // --------------------------------------------------------------------------
  // QR DETECTION
  // --------------------------------------------------------------------------

  /// Called by MobileScanner when a barcode is detected.
  ///
  /// Passes the raw string value to the notifier for parsing.
  /// Guards against null/empty values and duplicate processing.
  void _onQrDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    // Pause scanner before passing to notifier.
    _pauseScanner();

    // Pass to notifier for parsing. The notifier's state change
    // triggers the listener in _buildStateListener.
    ref.read(setupQrScanProvider.notifier).onQrDetected(rawValue);
  }

  // --------------------------------------------------------------------------
  // STATE HANDLING
  // --------------------------------------------------------------------------

  /// Handles state transitions from [SetupQrScanNotifier].
  ///
  /// - [SetupQrScanParsedState]: show confirmation bottom sheet
  /// - [SetupQrScanErrorState]: show error snackbar, resume scanning
  /// - [SetupQrScanIdleState]: no action needed
  void _handleStateChange(
    SetupQrScanState? previous,
    SetupQrScanState next,
  ) {
    if (next is SetupQrScanParsedState && !_isBottomSheetVisible) {
      _showConfirmationSheet(next.payload);
    } else if (next is SetupQrScanErrorState) {
      _showErrorSnackbar(next.message);
    }
  }

  // --------------------------------------------------------------------------
  // CONFIRMATION BOTTOM SHEET
  // --------------------------------------------------------------------------

  /// Shows a confirmation sheet with the parsed QR payload details.
  ///
  /// Operator reviews the event info before confirming.
  /// Confirm → Phase 5 token exchange (placeholder in Phase 4)
  /// Cancel → resume scanning
  void _showConfirmationSheet(SetupQrPayload payload) {
    _isBottomSheetVisible = true;

    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SetupConfirmationSheet(
        payload: payload,
        onConfirm: () {
          Navigator.of(context).pop();
          _isBottomSheetVisible = false;
          _onConfirmSetup(payload);
        },
        onCancel: () {
          Navigator.of(context).pop();
          _isBottomSheetVisible = false;
          // Reset notifier → idle state → camera resumes.
          ref.read(setupQrScanProvider.notifier).reset();
          _resumeScanner();
        },
      ),
    ).then((_) {
      // Handle sheet dismissed by swipe.
      if (_isBottomSheetVisible) {
        _isBottomSheetVisible = false;
        ref.read(setupQrScanProvider.notifier).reset();
        _resumeScanner();
      }
    });
  }

  /// Called when operator taps "Confirm" on the confirmation sheet.
  ///
  /// PHASE 4: Navigates to home as a placeholder.
  /// PHASE 5: This is replaced with the token exchange API call.
  void _onConfirmSetup(SetupQrPayload payload) {
    // TODO (Phase 5): Replace this with:
    // ref.read(setupExchangeProvider.notifier).exchangeSetupToken(payload);
    // The Phase 5 provider will handle the API call, session storage,
    // and navigation to /home on success.

    // Phase 4 placeholder: show what would happen.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Phase 4 complete. Token exchange will happen in Phase 5.\n'
          'Server: ${payload.serverUrlDisplay}\n'
          'Event: ${payload.eventPublicRef}',
        ),
        backgroundColor: AppColors.backgroundTertiary,
        duration: const Duration(seconds: 4),
      ),
    );

    // For Phase 4 testing: navigate to home.
    // In Phase 5, navigation will be driven by provider success state.
    context.go(RouteNames.home);
  }

  // --------------------------------------------------------------------------
  // ERROR HANDLING
  // --------------------------------------------------------------------------

  /// Shows an error Snackbar and resumes scanning after it dismisses.
  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
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
          duration: const Duration(seconds: 3),
        ),
      ).closed.then((_) {
        // Reset notifier and resume scanning after snackbar closes.
        if (mounted) {
          ref.read(setupQrScanProvider.notifier).reset();
          _resumeScanner();
        }
      });
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Listen to notifier state changes for side effects.
    ref.listen<SetupQrScanState>(
      setupQrScanProvider,
      _handleStateChange,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // --------------------------------------------------------------------------
  // APP BAR
  // --------------------------------------------------------------------------

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () {
          ref.read(setupQrScanProvider.notifier).reset();
          context.go(RouteNames.setup);
        },
        tooltip: 'Back',
      ),
      title: const Text(
        'Scan Setup QR',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        // Torch toggle — only shown when camera is active.
        if (_permissionStatus?.isGranted == true)
          IconButton(
            icon: Icon(
              _isTorchOn
                  ? Icons.flashlight_off_rounded
                  : Icons.flashlight_on_rounded,
              color: _isTorchOn ? AppColors.brandPrimary : Colors.white,
            ),
            onPressed: _toggleTorch,
            tooltip: _isTorchOn ? 'Turn off torch' : 'Turn on torch',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // BODY
  // --------------------------------------------------------------------------

  Widget _buildBody() {
    // Checking permission status — show loading.
    if (_isCheckingPermission) {
      return const _CameraLoadingView();
    }

    final status = _permissionStatus;
    if (status == null) {
      return const _CameraLoadingView();
    }

    // Permission granted — show camera.
    if (status.isGranted) {
      return _buildCameraView();
    }

    // Permission permanently denied — show settings redirect.
    if (status.isPermanentlyDenied) {
      return _PermissionDeniedView(
        isPermanent: true,
        onAction: _openAppSettings,
      );
    }

    // Permission denied (not permanently) — show request prompt.
    return _PermissionDeniedView(
      isPermanent: false,
      onAction: _requestCameraPermission,
    );
  }

  Widget _buildCameraView() {
    // Guard: controller must be initialized.
    if (_scannerController == null) {
      return const _CameraLoadingView();
    }

    return Stack(
      children: [
        // ----------------------------------------------------------------
        // CAMERA PREVIEW — fills entire screen
        // ----------------------------------------------------------------
        Positioned.fill(
          child: MobileScanner(
            controller: _scannerController!,
            onDetect: _onQrDetected,
            errorBuilder: (context, error, child) {
              return _CameraErrorView(error: error.errorDetails?.message);
            },
          ),
        ),

        // ----------------------------------------------------------------
        // QR SCANNER OVERLAY — mask + frame + scan line
        // ----------------------------------------------------------------
        Positioned.fill(
          child: QrScannerOverlay(
            frameSizeFraction: 0.72,
            label: 'Point camera at the\nAdmin Setup QR Code',
            showScanLine: true,
            scanLineDurationMs: 1800,
          ),
        ),

        // ----------------------------------------------------------------
        // PROCESSING INDICATOR — shown while parsing the QR
        // ----------------------------------------------------------------
        Consumer(
          builder: (context, ref, _) {
            final scanState = ref.watch(setupQrScanProvider);
            if (scanState is SetupQrScanProcessingState) {
              return Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(120),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.brandPrimary,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Reading QR code...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

// ============================================================================
// CONFIRMATION BOTTOM SHEET
// ============================================================================

/// Bottom sheet showing parsed QR payload details for operator confirmation.
///
/// Shown after a valid setup QR is scanned.
/// Operator reviews the server and event details before proceeding.
class _SetupConfirmationSheet extends StatelessWidget {
  const _SetupConfirmationSheet({
    required this.payload,
    required this.onConfirm,
    required this.onCancel,
  });

  final SetupQrPayload payload;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

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
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.borderPrimary,
              borderRadius: BorderRadius.circular(100),
            ),
          ),

          // Content
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
                // Header
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
                          const Text(
                            'Setup QR Detected',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
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

                // Details card
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
                        isLast: false,
                      ),
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

                // Expiry warning if close to expiring
                if (!payload.isExpired && payload.minutesUntilExpiry < 10) ...[
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

                // Action buttons
                AppButton.primary(
                  label: 'Connect to Event',
                  leadingIcon: Icons.link_rounded,
                  onPressed: payload.isExpired ? null : onConfirm,
                ),
                const SizedBox(height: 12),
                AppButton.secondary(
                  label: 'Scan Again',
                  leadingIcon: Icons.qr_code_scanner_rounded,
                  onPressed: onCancel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A detail row inside the confirmation sheet.
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

// ============================================================================
// PERMISSION VIEWS
// ============================================================================

/// Shown while camera permission status is being checked.
class _CameraLoadingView extends StatelessWidget {
  const _CameraLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
          ),
          SizedBox(height: 20),
          Text(
            'Preparing camera...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Shown when camera permission is denied.
///
/// [isPermanent]: true if permanently denied (show settings button)
/// false if just denied (show request button)
class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({
    required this.isPermanent,
    required this.onAction,
  });

  final bool isPermanent;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.warning,
                size: 40,
              ),
            ),

            // Title
            Text(
              isPermanent ? 'Camera Access Blocked' : 'Camera Permission Needed',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              isPermanent
                  ? 'Camera access has been permanently denied. '
                    'Please open your device Settings, find Gate Scanner, '
                    'and enable Camera permission.'
                  : 'Gate Scanner needs access to your camera to scan '
                    'the setup QR code. Please grant camera permission.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // Action button
            AppButton.primary(
              label: isPermanent ? 'Open Settings' : 'Grant Camera Access',
              leadingIcon: isPermanent
                  ? Icons.settings_outlined
                  : Icons.camera_alt_outlined,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when MobileScanner encounters a camera hardware error.
class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              color: AppColors.error,
              size: 56,
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Error',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Please ensure no other app is using the camera,\n'
              'then restart Gate Scanner.',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}