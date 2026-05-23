import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart';

final screenSecurityServiceProvider = Provider<ScreenSecurityService>((ref) {
  return ScreenSecurityService._();
});

/// Prevents screenshots and screen recording on sensitive screens (release).
class ScreenSecurityService {
  ScreenSecurityService._();

  int _lockCount = 0;

  /// Enables FLAG_SECURE (Android) / screen capture blocking (iOS).
  Future<void> enableProtection() async {
    if (kDebugMode) return;
    _lockCount++;
    if (_lockCount == 1) {
      await ScreenProtector.preventScreenshotOn();
    }
  }

  /// Releases protection when leaving a sensitive screen.
  Future<void> disableProtection() async {
    if (kDebugMode) return;
    if (_lockCount <= 0) return;
    _lockCount--;
    if (_lockCount == 0) {
      await ScreenProtector.preventScreenshotOff();
    }
  }
}
