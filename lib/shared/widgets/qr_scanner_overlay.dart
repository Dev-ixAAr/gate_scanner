// ============================================================================
// QR Scanner Overlay — Camera viewfinder overlay
//
// Renders a professional QR scanning frame on top of the camera preview.
//
// VISUAL ELEMENTS:
// 1. Semi-transparent black mask covering the area OUTSIDE the scan frame
// 2. Transparent "hole" in the center (the actual scan area)
// 3. Four corner markers in brand green (L-shaped brackets)
// 4. Animated green scan line sweeping through the frame
// 5. Optional label text below the frame
//
// ARCHITECTURE:
// - QrScannerOverlay: StatefulWidget that owns the animation controller
// - _ScannerOverlayPainter: CustomPainter that draws the visual elements
// - The clear hole is achieved using BlendMode.clear on a Canvas layer
//
// USAGE:
// ```dart
// Stack(
//   children: [
//     MobileScanner(...),
//     QrScannerOverlay(
//       frameSize: Size(280, 280),
//       label: 'Point camera at the setup QR code',
//     ),
//   ],
// )
// ```
// ============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Animated QR scanner frame overlay rendered on top of the camera view.
///
/// Draws the scanning frame with corner markers and an animated scan line.
/// The area outside the frame is darkened to focus attention on the scan area.
class QrScannerOverlay extends StatefulWidget {
  const QrScannerOverlay({
    super.key,
    this.frameSize,
    this.frameSizeFraction = 0.72,
    this.label,
    this.labelStyle,
    this.cornerLength = 28.0,
    this.cornerStrokeWidth = 4.0,
    this.cornerRadius = 6.0,
    this.cornerColor = AppColors.scannerFrameCorner,
    this.overlayColor = AppColors.scannerOverlayMask,
    this.scanLineColor = AppColors.scannerScanLine,
    this.showScanLine = true,
    this.scanLineDurationMs = 1800,
  });

  /// Fixed size of the scan frame in logical pixels.
  ///
  /// If null, [frameSizeFraction] is used to compute the size
  /// relative to the screen's shortest side.
  final Size? frameSize;

  /// Fraction of the screen's shortest side to use as the frame size.
  ///
  /// Default 0.72 = 72% of the shortest screen dimension.
  /// Ignored if [frameSize] is provided.
  final double frameSizeFraction;

  /// Instruction text displayed below the scan frame.
  ///
  /// Example: "Point camera at the Admin Setup QR Code"
  final String? label;

  /// Text style for [label]. Defaults to white 14sp if null.
  final TextStyle? labelStyle;

  /// Length of each corner marker arm in logical pixels.
  final double cornerLength;

  /// Stroke width of the corner marker lines.
  final double cornerStrokeWidth;

  /// Border radius applied to the corner marker ends.
  final double cornerRadius;

  /// Color of the four corner markers.
  final Color cornerColor;

  /// Color of the semi-transparent overlay outside the frame.
  final Color overlayColor;

  /// Color of the animated scan line.
  final Color scanLineColor;

  /// Whether to show the animated scan line.
  final bool showScanLine;

  /// Duration of one complete scan line sweep in milliseconds.
  final int scanLineDurationMs;

  @override
  State<QrScannerOverlay> createState() => _QrScannerOverlayState();
}

class _QrScannerOverlayState extends State<QrScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.scanLineDurationMs),
    );
    // Scan line sweeps from top to bottom and repeats.
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    if (widget.showScanLine) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // Calculate the scan frame dimensions.
    final double frameEdge = widget.frameSize != null
        ? math.min(widget.frameSize!.width, widget.frameSize!.height)
        : math.min(screenSize.width, screenSize.height) *
            widget.frameSizeFraction;
    final Size resolvedFrameSize = widget.frameSize ?? Size(frameEdge, frameEdge);

    return Stack(
      children: [
        // ----------------------------------------------------------------
        // OVERLAY PAINTER — mask + corner markers + scan line
        // ----------------------------------------------------------------
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _scanLineAnimation,
            builder: (context, _) {
              return CustomPaint(
                painter: _ScannerOverlayPainter(
                  frameSize: resolvedFrameSize,
                  scanLineProgress: widget.showScanLine
                      ? _scanLineAnimation.value
                      : null,
                  cornerLength: widget.cornerLength,
                  cornerStrokeWidth: widget.cornerStrokeWidth,
                  cornerRadius: widget.cornerRadius,
                  cornerColor: widget.cornerColor,
                  overlayColor: widget.overlayColor,
                  scanLineColor: widget.scanLineColor,
                ),
              );
            },
          ),
        ),

        // ----------------------------------------------------------------
        // LABEL — instruction text below the scan frame
        // ----------------------------------------------------------------
        if (widget.label != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                // Push the label below the frame.
                padding: EdgeInsets.only(
                  top: resolvedFrameSize.height / 2 + 24,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(140),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    widget.label!,
                    textAlign: TextAlign.center,
                    style: widget.labelStyle ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
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
// CUSTOM PAINTER
// ============================================================================

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({
    required this.frameSize,
    required this.cornerLength,
    required this.cornerStrokeWidth,
    required this.cornerRadius,
    required this.cornerColor,
    required this.overlayColor,
    required this.scanLineColor,
    this.scanLineProgress,
  });

  final Size frameSize;
  final double cornerLength;
  final double cornerStrokeWidth;
  final double cornerRadius;
  final Color cornerColor;
  final Color overlayColor;
  final Color scanLineColor;

  /// Current position of the scan line (0.0 = top, 1.0 = bottom).
  /// Null means no scan line is shown.
  final double? scanLineProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // Center the frame in the canvas.
    final Rect frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameSize.width,
      height: frameSize.height,
    );

    // ----------------------------------------------------------------
    // 1. DRAW SEMI-TRANSPARENT OVERLAY (mask outside the frame)
    //
    // Technique: draw the full screen, then punch a transparent hole
    // where the scan frame is using BlendMode.clear on a saved layer.
    // ----------------------------------------------------------------
    canvas.saveLayer(Offset.zero & size, Paint());

    // Fill the entire canvas with the overlay color.
    final Paint overlayPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, overlayPaint);

    // Cut a rounded-rectangle hole for the scan area.
    final Paint clearPaint = Paint()..blendMode = BlendMode.clear;
    final RRect frameRRect = RRect.fromRectAndRadius(
      frameRect,
      const Radius.circular(12),
    );
    canvas.drawRRect(frameRRect, clearPaint);

    canvas.restore();

    // ----------------------------------------------------------------
    // 2. DRAW FRAME BORDER (subtle outline around the clear area)
    // ----------------------------------------------------------------
    final Paint frameBorderPaint = Paint()
      ..color = AppColors.scannerFrameBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(frameRRect, frameBorderPaint);

    // ----------------------------------------------------------------
    // 3. DRAW CORNER MARKERS
    //
    // Four L-shaped brackets at the corners of the scan frame.
    // Each bracket has two arms: one horizontal, one vertical.
    // ----------------------------------------------------------------
    final Paint cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawCornerMarkers(canvas, frameRect, cornerPaint);

    // ----------------------------------------------------------------
    // 4. DRAW ANIMATED SCAN LINE
    // ----------------------------------------------------------------
    if (scanLineProgress != null) {
      _drawScanLine(canvas, frameRect, scanLineProgress!);
    }
  }

  /// Draws L-shaped corner brackets at all four corners of [frameRect].
  void _drawCornerMarkers(Canvas canvas, Rect frameRect, Paint paint) {
    final double l = cornerLength;
    final double left = frameRect.left;
    final double top = frameRect.top;
    final double right = frameRect.right;
    final double bottom = frameRect.bottom;

    // ┌ TOP-LEFT corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + l)
        ..lineTo(left, top + cornerRadius)
        ..quadraticBezierTo(left, top, left + cornerRadius, top)
        ..lineTo(left + l, top),
      paint,
    );

    // ┐ TOP-RIGHT corner
    canvas.drawPath(
      Path()
        ..moveTo(right - l, top)
        ..lineTo(right - cornerRadius, top)
        ..quadraticBezierTo(right, top, right, top + cornerRadius)
        ..lineTo(right, top + l),
      paint,
    );

    // └ BOTTOM-LEFT corner
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - l)
        ..lineTo(left, bottom - cornerRadius)
        ..quadraticBezierTo(left, bottom, left + cornerRadius, bottom)
        ..lineTo(left + l, bottom),
      paint,
    );

    // ┘ BOTTOM-RIGHT corner
    canvas.drawPath(
      Path()
        ..moveTo(right - l, bottom)
        ..lineTo(right - cornerRadius, bottom)
        ..quadraticBezierTo(right, bottom, right, bottom - cornerRadius)
        ..lineTo(right, bottom - l),
      paint,
    );
  }

  /// Draws the animated scan line at [progress] position within [frameRect].
  ///
  /// [progress] is a value from 0.0 (top of frame) to 1.0 (bottom of frame).
  /// The line has a gradient fade on the left and right edges.
  void _drawScanLine(Canvas canvas, Rect frameRect, double progress) {
    final double y = frameRect.top + (frameRect.height * progress);

    // Clamp to frame bounds (with 2px padding for the line width).
    final double clampedY = y.clamp(
      frameRect.top + 2,
      frameRect.bottom - 2,
    );

    // Draw with a horizontal gradient that fades at the edges.
    final Paint linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          scanLineColor.withAlpha(0),
          scanLineColor.withAlpha(200),
          scanLineColor,
          scanLineColor.withAlpha(200),
          scanLineColor.withAlpha(0),
        ],
        stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
      ).createShader(
        Rect.fromLTRB(
          frameRect.left,
          clampedY - 1,
          frameRect.right,
          clampedY + 1,
        ),
      )
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(frameRect.left, clampedY),
      Offset(frameRect.right, clampedY),
      linePaint,
    );

    // Draw a soft glow below the scan line.
    final Paint glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scanLineColor.withAlpha(60),
          scanLineColor.withAlpha(0),
        ],
      ).createShader(
        Rect.fromLTRB(
          frameRect.left,
          clampedY,
          frameRect.right,
          clampedY + 16,
        ),
      );

    canvas.drawRect(
      Rect.fromLTRB(
        frameRect.left,
        clampedY,
        frameRect.right,
        (clampedY + 16).clamp(frameRect.top, frameRect.bottom),
      ),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter oldDelegate) {
    // Only repaint if the scan line position changed.
    return oldDelegate.scanLineProgress != scanLineProgress ||
        oldDelegate.frameSize != frameSize ||
        oldDelegate.cornerColor != cornerColor;
  }
}