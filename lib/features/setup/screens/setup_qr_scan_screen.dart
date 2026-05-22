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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/qr_scanner_overlay.dart';
import '../models/setup_qr_payload.dart';
import '../providers/setup_provider.dart';
import '../widgets/setup_confirmation_sheet.dart';

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
  bool _isStartingCamera = false;

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
    unawaited(_releaseCamera());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkCameraPermission();
      if (_permissionStatus?.isGranted == true) {
        _scheduleCameraStart();
      }
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
    if (status.isGranted) await _initializeCamera();
  }

  Future<void> _requestCameraPermission() async {
    setState(() => _isCheckingPermission = true);
    final PermissionStatus status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permissionStatus = status;
      _isCheckingPermission = false;
    });
    if (status.isGranted) await _initializeCamera();
  }

  Future<void> _openAppSettings() async => openAppSettings();

  // --------------------------------------------------------------------------
  // CAMERA MANAGEMENT
  // --------------------------------------------------------------------------

  Future<void> _initializeCamera() async {
    await _releaseCamera();
    _scannerController = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.normal,
      formats: const [BarcodeFormat.qrCode],
    );
    _scannerController!.addListener(_onScannerStateChanged);
    if (!mounted) return;
    setState(() {});
    _scheduleCameraStart();
  }

  void _scheduleCameraStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_ensureCameraStarted());
    });
  }

  Future<void> _ensureCameraStarted() async {
    final controller = _scannerController;
    if (controller == null || !mounted || _isStartingCamera) return;

    if (controller.value.isRunning) {
      if (mounted) {
        setState(() {
          _isTorchOn = controller.value.torchState == TorchState.on;
        });
      }
      return;
    }

    _isStartingCamera = true;
    try {
      await controller.start();
      if (!mounted) return;
      setState(() {
        _isTorchOn = controller.value.torchState == TorchState.on;
      });
    } on MobileScannerException catch (e) {
      if (e.errorCode == MobileScannerErrorCode.controllerAlreadyInitialized) {
        if (mounted) {
          setState(() {
            _isTorchOn = controller.value.torchState == TorchState.on;
          });
        }
        return;
      }
      if (kDebugMode) {
        debugPrint('[SetupQrScanScreen] camera start failed: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SetupQrScanScreen] camera start failed: $e');
      }
    } finally {
      _isStartingCamera = false;
    }
  }

  void _onScannerStateChanged() {
    if (!mounted || _scannerController == null) return;
    final bool torchOn =
        _scannerController!.value.torchState == TorchState.on;
    if (_isTorchOn != torchOn) {
      setState(() => _isTorchOn = torchOn);
    }
  }

  Future<void> _toggleTorch() async {
    if (_scannerController == null) return;
    if (!_scannerController!.value.isRunning) {
      await _ensureCameraStarted();
    }
    if (!_scannerController!.value.isRunning) return;
    if (_scannerController!.value.torchState == TorchState.unavailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Flashlight is not available on this device'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }
    await _scannerController!.toggleTorch();
  }

  void _pauseScanner() => _scannerController?.stop();

  Future<void> _resumeScanner() async => _ensureCameraStarted();

  /// Stops and disposes the camera so another screen can open it.
  Future<void> _releaseCamera() async {
    final controller = _scannerController;
    _scannerController = null;
    if (controller == null) return;
    controller.removeListener(_onScannerStateChanged);
    try {
      if (controller.value.isRunning) {
        await controller.stop();
      }
    } catch (_) {
      // Ignore stop errors during teardown.
    }
    try {
      await controller.dispose();
    } catch (_) {
      // Ignore dispose errors during teardown.
    }
    if (mounted) {
      setState(() => _isTorchOn = false);
    }
  }

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
    if (next is SetupExchangeSuccessState) {
      unawaited(_onExchangeSuccess());
    } else if (next is SetupExchangeErrorState) {
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
  }

  /// Releases the setup camera, closes UI chrome, then navigates to home.
  ///
  /// The router guard also redirects after session save, but we must release
  /// the camera here first — otherwise the ticket scanner opens while the
  /// setup camera is still held and shows a black preview with the QR overlay.
  Future<void> _onExchangeSuccess() async {
    if (_isBottomSheetVisible) {
      Navigator.of(context).pop();
      _isBottomSheetVisible = false;
    }
    await _releaseCamera();
    if (!mounted) return;
    context.go(RouteNames.home);
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

            return SetupConfirmationSheet(
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
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
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
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: MobileScanner(
            controller: _scannerController!,
            fit: BoxFit.cover,
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