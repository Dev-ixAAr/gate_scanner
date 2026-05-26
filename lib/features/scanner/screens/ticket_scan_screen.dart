// ============================================================================
// Ticket Scan Screen — Full-screen camera for scanning attendee tickets
//
// FEATURES:
// - Full-screen camera via mobile_scanner
// - QR scanner overlay (corner markers + scan line)
// - Event name in top bar for operator context
// - Scan count badge in AppBar
// - Flash toggle button
// - Close button → back to home
// - Processing indicator when validating
// - ScanResultSheet as modal bottom sheet over camera
// - Manual Search shortcut button at bottom
// - AppLifecycleObserver for camera pause/resume
//
// CAMERA LIFECYCLE:
// - Camera starts when screen appears and permission is granted
// - Camera pauses on QR detection (during API call)
// - Camera pauses while result sheet is open
// - Camera resumes when result sheet is dismissed (resetScan)
// - Camera pauses on AppLifecycleState.paused
// - Camera resumes on AppLifecycleState.resumed
// ============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/providers/session_providers.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/qr_scanner_overlay.dart';
import '../models/scan_state.dart';
import '../models/ticket_validation_result.dart';
import '../providers/scanner_provider.dart';
import 'scan_result_screen.dart';

/// Full-screen ticket QR scanning screen.
class TicketScanScreen extends ConsumerStatefulWidget {
  const TicketScanScreen({super.key});

  @override
  ConsumerState<TicketScanScreen> createState() => _TicketScanScreenState();
}

class _TicketScanScreenState extends ConsumerState<TicketScanScreen>
    with WidgetsBindingObserver {
  // --------------------------------------------------------------------------
  // STATE
  // --------------------------------------------------------------------------

  MobileScannerController? _controller;
  PermissionStatus? _permissionStatus;
  bool _isCheckingPermission = true;
  bool _isResultSheetOpen = false;
  bool _cameraStartFailed = false;
  bool _isStartingCamera = false;

  // --------------------------------------------------------------------------
  // LIFECYCLE
  // --------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermission();
      // Reset scanner state when entering screen.
      ref.read(scannerProvider.notifier).resetScan();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_releaseCamera());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    super.didChangeAppLifecycleState(lifecycleState);
    if (lifecycleState == AppLifecycleState.paused) {
      _controller?.stop();
    } else if (lifecycleState == AppLifecycleState.resumed) {
      if (!_isResultSheetOpen && _permissionStatus?.isGranted == true) {
        _scheduleCameraStart();
      }
    }
  }

  // --------------------------------------------------------------------------
  // PERMISSION
  // --------------------------------------------------------------------------

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (!mounted) return;
    setState(() {
      _permissionStatus = status;
      _isCheckingPermission = false;
    });
    if (status.isGranted) {
      // Brief delay so a camera just released by the setup screen can reopen.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) await _initCamera();
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isCheckingPermission = true);
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permissionStatus = status;
      _isCheckingPermission = false;
    });
    if (status.isGranted) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) await _initCamera();
    }
  }

  // --------------------------------------------------------------------------
  // CAMERA
  // --------------------------------------------------------------------------

  Future<void> _releaseCamera() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.removeListener(_onScannerStateChanged);
    try {
      if (controller.value.isRunning) {
        await controller.stop();
      }
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    setState(() => _cameraStartFailed = false);
    await _releaseCamera();
    _controller = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.normal,
      formats: const [BarcodeFormat.qrCode],
    );
    _controller!.addListener(_onScannerStateChanged);
    if (!mounted) return;
    setState(() {});
    _scheduleCameraStart();
  }

  /// Schedules a single start() after [MobileScanner] is in the widget tree.
  void _scheduleCameraStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_ensureCameraStarted());
    });
  }

  /// Starts the camera once. Safe if [MobileScanner] already auto-started it.
  Future<void> _ensureCameraStarted() async {
    final controller = _controller;
    if (controller == null || !mounted || _isStartingCamera) return;

    if (controller.value.isRunning) {
      if (mounted) setState(() => _cameraStartFailed = false);
      return;
    }

    _isStartingCamera = true;
    try {
      await controller.start();
      if (!mounted) return;
      setState(() => _cameraStartFailed = false);
      final isFlashOn = ref.read(scannerProvider).isFlashOn;
      if (isFlashOn &&
          controller.value.torchState != TorchState.on &&
          controller.value.torchState != TorchState.unavailable) {
        await controller.toggleTorch();
      }
    } on MobileScannerException catch (e) {
      if (e.errorCode == MobileScannerErrorCode.controllerAlreadyInitialized) {
        if (mounted) setState(() => _cameraStartFailed = false);
        return;
      }
      if (kDebugMode) {
        debugPrint('[TicketScanScreen] camera start failed: $e');
      }
      if (mounted) setState(() => _cameraStartFailed = true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TicketScanScreen] camera start failed: $e');
      }
      if (mounted) setState(() => _cameraStartFailed = true);
    } finally {
      _isStartingCamera = false;
    }
  }

  Future<void> _retryCamera() async {
    if (_permissionStatus?.isGranted != true) {
      await _checkPermission();
      return;
    }
    await _initCamera();
  }

  void _onScannerStateChanged() {
    if (!mounted || _controller == null) return;
    final bool torchOn = _controller!.value.torchState == TorchState.on;
    final scannerState = ref.read(scannerProvider);
    if (scannerState.isFlashOn != torchOn) {
      ref.read(scannerProvider.notifier).setFlashOn(torchOn);
    }
  }

  Future<void> _toggleTorch() async {
    if (_controller == null) return;
    if (!_controller!.value.isRunning) {
      await _ensureCameraStarted();
    }
    if (!_controller!.value.isRunning) return;
    if (_controller!.value.torchState == TorchState.unavailable) return;
    await _controller!.toggleTorch();
    ref.read(scannerProvider.notifier).setFlashOn(
          _controller!.value.torchState == TorchState.on,
        );
  }

  // --------------------------------------------------------------------------
  // QR DETECTION
  // --------------------------------------------------------------------------

  void _onQrDetected(BarcodeCapture capture) {
    // Ignore detections when result sheet is open or already processing.
    if (_isResultSheetOpen) return;
    final scannerState = ref.read(scannerProvider);
    if (scannerState.status == ScanStatus.processing ||
        scannerState.status == ScanStatus.result) return;

    final String? rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    _controller?.stop();
    ref.read(scannerProvider.notifier).onQrDetected(rawValue);
  }

  // --------------------------------------------------------------------------
  // STATE HANDLING
  // --------------------------------------------------------------------------

  void _handleScannerStateChange(ScannerState? previous, ScannerState next) {
    if (next.status == ScanStatus.result && !_isResultSheetOpen) {
      if (next.lastResult is ValidResult) {
        SystemSound.play(SystemSoundType.alert);
      }
      _showResultSheet(next.lastResult!);
    }
  }

  void _showResultSheet(TicketValidationResult result) {
    _isResultSheetOpen = true;

    showModalBottomSheet<void>(
      context: context,
      isDismissible: false, // Force user to tap Done/Retry
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScanResultSheet(
        result: result,
        onDone: () {
          Navigator.of(context).pop();
          _onResultDismissed();
        },
        onConfirmCheckin: (admissionsToUse) async {
          await ref
              .read(scannerProvider.notifier)
              .confirmCheckin(admissionsToUse: admissionsToUse);
        },
        onRetry: () {
          Navigator.of(context).pop();
          _onResultDismissed();
        },
      ),
    ).then((_) {
      if (_isResultSheetOpen) {
        _isResultSheetOpen = false;
        _onResultDismissed();
      }
    });
  }

  void _onResultDismissed() {
    _isResultSheetOpen = false;
    ref.read(scannerProvider.notifier).resetScan();
    _scheduleCameraStart();
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen<ScannerState>(scannerProvider, _handleScannerStateChange);

    final scannerState = ref.watch(scannerProvider);
    final eventNameAsync = ref.watch(currentEventNameProvider);
    final eventName = eventNameAsync.valueOrNull ?? 'Gate Scanner';

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(
        context: context,
        eventName: eventName,
        scannerState: scannerState,
      ),
      body: SizedBox.expand(
        child: _buildBody(scannerState),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // APP BAR
  // --------------------------------------------------------------------------

  AppBar _buildAppBar({
    required BuildContext context,
    required String eventName,
    required ScannerState scannerState,
  }) {
    return AppBar(
      backgroundColor: Colors.black.withAlpha(160),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        onPressed: () => context.go(RouteNames.home),
        tooltip: 'Close scanner',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ticket Scanner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            eventName,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        // Scan count badge.
        if (scannerState.scannedCount > 0)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandPrimarySurface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.brandPrimaryBorder),
            ),
            child: Text(
              '${scannerState.scannedCount}',
              style: const TextStyle(
                color: AppColors.brandPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

        // Torch toggle.
        if (_permissionStatus?.isGranted == true)
          IconButton(
            icon: Icon(
              scannerState.isFlashOn
                  ? Icons.flashlight_off_rounded
                  : Icons.flashlight_on_rounded,
              color:
                  scannerState.isFlashOn ? AppColors.brandPrimary : Colors.white,
            ),
            onPressed: _toggleTorch,
            tooltip: 'Toggle torch',
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // BODY
  // --------------------------------------------------------------------------

  Widget _buildBody(ScannerState scannerState) {
    if (_isCheckingPermission) {
      return const _ScannerLoadingView(message: 'Preparing camera...');
    }

    final status = _permissionStatus;
    if (status == null || !status.isGranted) {
      return _PermissionView(
        isPermanent: status?.isPermanentlyDenied ?? false,
        onRequest: status?.isPermanentlyDenied ?? false
            ? () async => openAppSettings()
            : _requestPermission,
      );
    }

    if (_controller == null) {
      return const _ScannerLoadingView(message: 'Starting camera...');
    }

    if (_cameraStartFailed) {
      return _CameraErrorView(
        message: 'Could not open the camera. Another screen may have '
            'just released it — tap Retry.',
        onRetry: _retryCamera,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Camera preview ──────────────────────────────────────────────────
        Positioned.fill(
          child: MobileScanner(
            controller: _controller!,
            fit: BoxFit.cover,
            onDetect: _onQrDetected,
            errorBuilder: (context, error, child) => _CameraErrorView(
              message: error.errorDetails?.message,
              onRetry: _retryCamera,
            ),
          ),
        ),

        // ── QR Overlay ──────────────────────────────────────────────────────
        const Positioned.fill(
          child: QrScannerOverlay(
            frameSizeFraction: 0.72,
            label: 'Point camera at ticket QR code',
            showScanLine: true,
          ),
        ),

        // ── Processing indicator ────────────────────────────────────────────
        if (scannerState.isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(140),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.brandPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Validating ticket...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Manual Search link (bottom) ──────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).padding.bottom + 24,
          child: Center(
            child: GestureDetector(
              onTap: () => context.go(RouteNames.manualSearch),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Manual Search',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SUPPORT WIDGETS
// ============================================================================

class _ScannerLoadingView extends StatelessWidget {
  const _ScannerLoadingView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView({
    required this.isPermanent,
    required this.onRequest,
  });

  final bool isPermanent;
  final VoidCallback onRequest;

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
              isPermanent ? 'Camera Access Blocked' : 'Camera Permission Required',
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
                  ? 'Open Settings and enable Camera for Gate Scanner.'
                  : 'Gate Scanner needs camera access to scan tickets.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: onRequest,
              icon: Icon(
                isPermanent ? Icons.settings_outlined : Icons.camera_alt_outlined,
              ),
              label: Text(isPermanent ? 'Open Settings' : 'Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({this.message, this.onRetry});
  final String? message;
  final VoidCallback? onRetry;

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
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}