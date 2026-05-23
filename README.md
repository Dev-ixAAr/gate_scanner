# 🎫 Gate Scanner

**Reusable mobile gate scanner app for event ticket validation at the entrance.**

Flutter (Android) app that connects to your ticketing backend, scans attendee QR codes in real time, and shows clear admit/deny results for gate operators — optimized for low-light venues and fast-paced check-in.

---

## ✨ Features

### 🔧 Scanner setup
- **📷 Setup QR scan** — Scan the admin setup QR from your dashboard to register the device and bind it to an event
- **✍️ Manual setup** — Enter server URL, event reference, and token manually when QR is not available
- **✅ Setup confirmation** — Review event name, server, and device details before starting

### 🏠 Dashboard (Home)
- **🟢 Live session status** — Active, checking, warning, or revoked with pulsing indicator
- **📅 Event info** — Connected event name and public reference at a glance
- **🌐 Connection details** — Server URL (copyable) and registered device name
- **⏱️ Session timeline** — Start time, duration, and last server verification
- **🔄 Pull to refresh** — Manually refresh session health from the server
- **📱 Auto-refresh on resume** — Re-checks session when the app returns from background

### 📸 Ticket scanning
- **🎥 Full-screen QR scanner** — Camera view with animated scan frame and corner markers
- **💡 Flash / torch toggle** — For dark entrances
- **🔢 Scan counter** — Tracks tickets processed in the current session
- **⚡ Debounced scans** — Prevents duplicate reads of the same QR
- **🔊 Valid scan feedback** — System alert sound on successful admission
- **📋 Result bottom sheet** — Stays over the camera; tap Done to scan the next ticket

### 🎨 Validation results (color-coded)
| Status | Color | Meaning |
|--------|-------|---------|
| ✅ **Valid** | Green | Admit — holder name, category, order/ticket refs |
| ⚠️ **Already used** | Amber | Do not admit — prior check-in audit trail |
| 🟠 **Wrong event** | Orange | Valid ticket, wrong gate — redirect holder |
| 🚫 **Revoked** | Red | Organizer revoked this ticket |
| 🚫 **Cancelled** | Red | Order or ticket cancelled |
| ❌ **Invalid** | Red | QR not recognized for this event |
| 📡 **Error** | Red | Network or server issue — retry available |

### 🔍 Manual ticket search
- Search by **ticket reference**, **order number**, or **holder name**
- View full ticket status without the camera
- **Check-in** valid tickets with confirmation dialog
- Handles the same validation states as QR scanning

### ⚙️ Settings & session management
- **Device info** — Brand, model, OS, app version (sent to API)
- **Session info** — Event, server, session start time
- **🔀 Switch event** — Disconnect and scan a new setup QR for another event
- **🚪 Logout session** — End server session and return to setup
- **🗑️ Reset event binding** — Clear local data only (emergency / offline recovery)

### 🔐 Security & reliability
- **🔒 Secure token storage** — Android Keystore via `flutter_secure_storage`
- **🛡️ Auth interceptors** — Bearer token on every API request
- **⛔ Session revoke handling** — Global 401/403 redirects to setup
- **📶 Connectivity awareness** — Clear offline / network error messages
- **🌙 Dark-first UI** — High contrast for gate operators; OLED-friendly blacks

---

## 🏗️ Tech stack

| Area | Package |
|------|---------|
| Framework | Flutter 3.3+ |
| QR camera | `mobile_scanner` |
| HTTP | `dio` + interceptors |
| State | `flutter_riverpod` |
| Navigation | `go_router` (session guards) |
| Secure storage | `flutter_secure_storage` |
| Device info | `device_info_plus`, `package_info_plus` |

---

## 📁 Project structure

```
lib/
├── core/           # API client, theme, router, session, secure storage
├── features/
│   ├── setup/      # Welcome, QR setup, manual setup
│   ├── home/       # Dashboard
│   ├── scanner/    # Ticket scan + result sheet
│   ├── manual_search/
│   └── settings/
└── shared/         # Reusable widgets (buttons, cards, overlay)
```

---

## 🚀 Getting started

### Prerequisites
- Flutter SDK **≥ 3.3.0**
- Android SDK (min/target per `android/app/build.gradle.kts`)
- A ticketing backend that exposes the Gate Scanner API

### Install & run

```bash
# Clone and enter the project
cd gate_scanner

# Install dependencies
flutter pub get

# Run code generation (if models/providers changed)
dart run build_runner build --delete-conflicting-outputs

# Run on a connected device or emulator
flutter run
```

### Android release build

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

Copy `android/key.properties.example` → `android/key.properties` and configure signing for production releases (required — release builds fail without it).

### Security configuration (before production)

Edit `lib/core/constants/app_constants.dart` → `AppSecurityConfig`:

1. **`allowedServerHostSuffixes`** — list your API domains (e.g. `yourcompany.com`)
2. **`certificatePinSha256`** — optional TLS pins per hostname (base64 SHA-256)
3. Ensure your backend returns `error_code: SESSION_REVOKED` on 403 when revoking scanners (not on every 403)

Debug builds allow cleartext only to `localhost` / emulator hosts via `network_security_config_debug.xml`.

---

## 📱 How to use (operator flow)

1. **🆕 First launch** — Open app → tap **Scan Setup QR Code** (or enter details manually)
2. **✅ Confirm** — Verify event name and server → confirm setup
3. **🏠 Home** — Check session is **Active** (green)
4. **📸 Scan** — Tap **Start Scanning** → point at attendee ticket QR
5. **👤 Result** — Green = admit; amber/red/orange = follow on-screen instructions
6. **🔍 Backup** — Use **Manual Search** if QR is damaged or unreadable

---

## 🧪 Tests

```bash
flutter test
```

---

## 📄 License

Private / internal use — see your organization for distribution terms.

---

## 🤝 Support

For API contract, setup QR generation, and server configuration, contact your **ticketing platform admin** or backend team.

**Version:** `1.0.0+1` · **Package:** `gate_scanner`
