// ============================================================================
// Service Providers — Centralized Riverpod providers for all services
//
// This file provides a single import point for all service providers
// used across the app. Features import from here instead of importing
// each service file individually.
//
// SERVICES COVERED:
// - SecureStorageService → encrypted key-value storage
// - SessionService       → session lifecycle management
// - DeviceInfoService    → hardware/OS info collection
// - AppInfoService       → app version/package info
//
// PROVIDER TYPES USED:
// - Provider<T>         → synchronous service with no state changes
//                         Never re-creates unless container is disposed.
//                         Access with ref.read() in callbacks.
//
// PATTERN: All service providers use Provider<T> (not StateNotifier, etc.)
// because services are stateless infrastructure objects. Their state lives
// in storage (SecureStorage, SharedPreferences), not in memory.
// ============================================================================

// Re-export all service providers from their source files.
// Feature code only needs to import this one file.

// Secure Storage
export '../secure_storage/secure_storage_service.dart'
    show secureStorageServiceProvider, SecureStorageService;

// Session Service
export '../services/session_service.dart'
    show sessionServiceProvider, SessionService;

// Device Info Service
export '../services/device_info_service.dart'
    show deviceInfoServiceProvider, DeviceInfoService;

// App Info Service
export '../services/app_info_service.dart'
    show appInfoServiceProvider, AppInfoService;

// Session Providers (reactive session state)
export 'session_providers.dart';