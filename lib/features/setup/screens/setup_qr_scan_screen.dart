// ============================================================================
// Setup QR Scan Screen — Updated for Phase 5
//
// PHASE 4 CHANGES (preserved):
// - Camera permission handling
// - QR detection and parsing via SetupQrScanNotifier
// - Confirmation bottom sheet display
//
// PHASE 5 CHANGES:
// - _onConfirmSetup now calls SetupExchangeNotifier.exchangeSetupToken()
// - Loading overlay shown during token exchange (SetupExchangeLoadingState)
// - Error handling from SetupExchangeErrorState
// - Success state navigated by router (no explicit navigation needed here)
// - Both SetupQrScanState and SetupExchangeState are watched
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
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/qr_scanner_overlay.dart';
import '../models/setup_qr_payload.dart';
import '../providers/setup_provider.dart';

/// Full-screen camera view for scanning the admin setup QR code.
///
/// Phase 5: Confirm button triggers token exchange via [SetupExchangeNotifier].
/// Navigation to /home is driven by the router after session is saved.
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

  MobileScannerController? _scannerController;
  PermissionStatus? _permissionStatus;
  bool _isCheckingPermission = true;
  bool _isTorchOn = false;
  bool _isBottomSheetVisible = false;

  // --------------------------------------------------------------------------
  // LIFECYCLE
  // --------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCameraPermission();
      // Reset both notifiers when entering this screen.
      // Clears any leftover state from a previous scan attempt.
      ref.read(setupQrScanProvider.notifier).reset();
      ref.read(setupExchangeProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkCameraPermission();
    }
    if (state == AppLifecycleState.paused) {
      _scannerController?.stop();
    }
  }

  // --------------------------------------------------------------------------
  // CAMERA PERMISSION
  // --------------------------------------------------------------------------

  Future<void> _checkCameraPermission() async {
    final PermissionStatus status = await Permission.camera.status;
    if (!mounted) return;
    setState(() {
      _permissionStatus = status;
      _isCheckingPermission = false;
    });
    if (status.isGranted) _initializeCamera();
  }

  Future<void> _requestCameraPermission() async {
    setState(() => _isCheckingPermission = true);
    final PermissionStatus status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permissionStatus = status;
      _isCheckingPermission = false;
    });
    if (status.isGranted) _initializeCamera();
  }

  Future<void> _openAppSettings() async => openAppSettings();

  // --------------------------------------------------------------------------
  // CAMERA MANAGEMENT
  // --------------------------------------------------------------------------

  void _initializeCamera() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.normal,
      formats: const [BarcodeFormat.qrCode],
      returnImage: false,
    );
    setState(() => _isTorchOn = false);
  }

  Future<void> _toggleTorch() async {
    if (_scannerController == null) return;
    await _scannerController!.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  void _pauseScanner() => _scannerController?.stop();

  Future<void> _resumeScanner() async => _scannerController?.start();

  // --------------------------------------------------------------------------
  // QR DETECTION
  // --------------------------------------------------------------------------

  void _onQrDetected(BarcodeCapture capture) {
    // Don't process new QR codes during token exchange.
    final exchangeState = ref.read(setupExchangeProvider);
    if (exchangeState is SetupExchangeLoadingState) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    _pauseScanner();
    ref.read(setupQrScanProvider.notifier).onQrDetected(rawValue);
  }

  // --------------------------------------------------------------------------
  // STATE HANDLING — QR SCAN STATE
  // --------------------------------------------------------------------------

  void _handleQrScanStateChange(
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
  // STATE HANDLING — EXCHANGE STATE
  // --------------------------------------------------------------------------

  void _handleExchangeStateChange(
    SetupExchangeState? previous,
    SetupExchangeState next,
  ) {
    if (next is SetupExchangeErrorState) {
      // Close any open bottom sheet.
      if (_isBottomSheetVisible) {
        Navigator.of(context, rootNavigator: true).popUntil(
          (route) => route.isFirst,
        );
        _isBottomSheetVisible = false;
      }
      // Show error and allow retry.
      _showExchangeErrorSnackbar(next);
      // Reset QR scan state to allow scanning again.
      ref.read(setupQrScanProvider.notifier).reset();
      _resumeScanner();
    }
    // SetupExchangeSuccessState: router handles navigation automatically.
    // No explicit navigation needed here.
  }

  // --------------------------------------------------------------------------
  // CONFIRMATION BOTTOM SHEET
  // --------------------------------------------------------------------------

  void _showConfirmationSheet(SetupQrPayload payload) {
    _isBottomSheetVisible = true;

    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        // Watch exchange state inside the bottom sheet for loading state.
        return Consumer(
          builder: (context, ref, _) {
            final exchangeState = ref.watch(setupExchangeProvider);
            final bool isExchanging =
                exchangeState is SetupExchangeLoadingState;

            return _SetupConfirmationSheet(
              payload: payload,
              isLoading: isExchanging,
              onConfirm: isExchanging
                  ? null
                  : () => _onConfirmSetup(payload),
              onCancel: isExchanging
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _isBottomSheetVisible = false;
                      ref.read(setupQrScanProvider.notifier).reset();
                      ref.read(setupExchangeProvider.notifier).reset();
                      _resumeScanner();
                    },
            );
          },
        );
      },
    ).then((_) {
      if (_isBottomSheetVisible) {
        _isBottomSheetVisible = false;
        // Only reset if exchange was not successful.
        final exchangeState = ref.read(setupExchangeProvider);
        if (exchangeState is! SetupExchangeSuccessState &&
            exchangeState is! SetupExchangeLoadingState) {
          ref.read(setupQrScanProvider.notifier).reset();
          ref.read(setupExchangeProvider.notifier).reset();
          _resumeScanner();
        }
      }
    });
  }

  // --------------------------------------------------------------------------
  // CONFIRM SETUP — Phase 5: Real token exchange
  // --------------------------------------------------------------------------

  /// Called when operator taps "Connect to Event" on the confirmation sheet.
  ///
  /// Phase 5: Calls [SetupExchangeNotifier.exchangeSetupToken].
  /// The notifier handles the full exchange flow:
  /// - API call → session save → router refresh → /home redirect
  Future<void> _onConfirmSetup(SetupQrPayload payload) async {
    await ref.read(setupExchangeProvider.notifier).exchangeSetupToken(payload);
  }

  // --------------------------------------------------------------------------
  // ERROR DISPLAY
  // --------------------------------------------------------------------------

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
        if (mounted) {
          ref.read(setupQrScanProvider.notifier).reset();
          _resumeScanner();
        }
      });
  }

  void _showExchangeErrorSnackbar(SetupExchangeErrorState errorState) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    errorState.isNetworkError
                        ? Icons.wifi_off_rounded
                        : Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Connection Failed',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  errorState.message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.backgroundTertiary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.errorBorder),
          ),
        ),
      );
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Listen to QR scan state changes.
    ref.listen<SetupQrScanState>(
      setupQrScanProvider,
      _handleQrScanStateChange,
    );

    // Listen to exchange state changes.
    ref.listen<SetupExchangeState>(
      setupExchangeProvider,
      _handleExchangeStateChange,
    );

    // Watch exchange state for loading overlay.
    final exchangeState = ref.watch(setupExchangeProvider);
    final bool isExchanging = exchangeState is SetupExchangeLoadingState;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Main camera body.
          _buildBody(),

          // Loading overlay during token exchange.
          // Shown over everything including the camera and bottom sheet.
          if (isExchanging)
            const Positioned.fill(
              child: LoadingOverlay(
                message: 'Connecting to event...',
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // APP BAR
  // --------------------------------------------------------------------------

  AppBar _buildAppBar() {
    final bool isExchanging =
        ref.read(setupExchangeProvider) is SetupExchangeLoadingState;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: isExchanging
            ? null
            : () {
                ref.read(setupQrScanProvider.notifier).reset();
                ref.read(setupExchangeProvider.notifier).reset();
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
        if (_permissionStatus?.isGranted == true)
          IconButton(
            icon: Icon(
              _isTorchOn
                  ? Icons.flashlight_off_rounded
                  : Icons.flashlight_on_rounded,
              color: _isTorchOn ? AppColors.brandPrimary : Colors.white,
            ),
            onPressed: isExchanging ? null : _toggleTorch,
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
    if (_isCheckingPermission) return const _CameraLoadingView();

    final status = _permissionStatus;
    if (status == null) return const _CameraLoadingView();
    if (status.isGranted) return _buildCameraView();
    if (status.isPermanentlyDenied) {
      return _PermissionDeniedView(
        isPermanent: true,
        onAction: _openAppSettings,
      );
    }
    return _PermissionDeniedView(
      isPermanent: false,
      onAction: _requestCameraPermission,
    );
  }

  Widget _buildCameraView() {
    if (_scannerController == null) return const _CameraLoadingView();

    return Stack(
      children: [
        Positioned.fill(
          child: MobileScanner(
            controller: _scannerController!,
            onDetect: _onQrDetected,
            errorBuilder: (context, error, child) {
              return _CameraErrorView(error: error.errorDetails?.message);
            },
          ),
        ),
        Positioned.fill(
          child: QrScannerOverlay(
            frameSizeFraction: 0.72,
            label: 'Point camera at the\nAdmin Setup QR Code',
            showScanLine: true,
            scanLineDurationMs: 1800,
          ),
        ),
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
// CONFIRMATION BOTTOM SHEET — Updated for Phase 5
// ============================================================================

class _SetupConfirmationSheet extends StatelessWidget {
  const _SetupConfirmationSheet({
    required this.payload,
    required this.isLoading,
    required this.onConfirm,
    required this.onCancel,
  });

  final SetupQrPayload payload;
  final bool isLoading;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setup QR Detected',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
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

                if (!payload.isExpired && payload.minutesUntilExpiry < 10) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warningBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 18),
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

                // Action buttons with loading state
                AppButton.primary(
                  label: isLoading ? 'Connecting...' : 'Connect to Event',
                  leadingIcon: isLoading ? null : Icons.link_rounded,
                  isLoading: isLoading,
                  onPressed: payload.isExpired ? null : onConfirm,
                ),
                const SizedBox(height: 12),
                AppButton.secondary(
                  label: 'Scan Again',
                  leadingIcon: Icons.qr_code_scanner_rounded,
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

// ============================================================================
// DETAIL ROW (reused from Phase 4)
// ============================================================================

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
// SUPPORT WIDGETS (reused from Phase 4 — unchanged)
// ============================================================================

class _CameraLoadingView extends StatelessWidget {
  const _CameraLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
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
              child: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.warning, size: 40),
            ),
            Text(
              isPermanent
                  ? 'Camera Access Blocked'
                  : 'Camera Permission Needed',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPermanent
                  ? 'Camera access has been permanently denied. Please open '
                    'your device Settings, find Gate Scanner, and enable '
                    'Camera permission.'
                  : 'Gate Scanner needs access to your camera to scan the '
                    'setup QR code. Please grant camera permission.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
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
            const Icon(Icons.videocam_off_outlined,
                color: AppColors.error, size: 56),
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
                    color: AppColors.textSecondary, fontSize: 14),
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