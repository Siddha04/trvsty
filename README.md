# Trvsty — *Verify with Confidence*

Trvsty is a universal background-verification platform for India. It lets
individuals and organisations verify identity and trustworthiness using
**Aadhaar Secure QR**, **Face Match**, **PAN Verification**, **Criminal Record
Check**, and **DigiLocker**, then produces a tamper-evident **Trust Score** and
a shareable **PDF report**.

Built with Flutter + Firebase, designed for production and the Play Store.

---

## ✨ Features

| Area | Capability |
|------|------------|
| Auth | Firebase Phone **OTP** login, DPDP consent gate |
| Verification | Aadhaar Secure QR scan & XML parse, Face Match, PAN, Criminal Record, DigiLocker |
| Scoring | Weighted **Trust Score** (0–100) + visual verification **badge** |
| Reports | Professional **PDF** with QR, masked Aadhaar, score — view / print / **share** |
| Payments | **Razorpay** one-time payments + **business subscriptions**, server-verified |
| Data | Firestore with timestamps, **soft deletes**, audit logs, hardened security rules |
| Privacy | Aadhaar masking, **no face-image retention**, AES-256 local encryption, secure storage |

## 🏗 Architecture

Clean Architecture, feature-first, with a clear **Presentation → Domain → Data**
split.

```
lib/
 ├── config/         # Env configuration (dotenv)
 ├── constants/      # App + Firestore + storage-key constants
 ├── theme/          # Material 3 brand theme & colours
 ├── core/
 │    ├── di/        # GetIt service locator
 │    ├── domain/    # Pure business logic (Trust Score calculator)
 │    ├── error/     # Failures & exceptions
 │    ├── network/   # Dio client, connectivity
 │    ├── providers/ # Riverpod bridge providers
 │    └── utils/     # Result type, logger
 ├── models/         # Immutable data models (+ Firestore mappers)
 ├── services/       # Auth, Firestore, SurePass, Razorpay, PDF, crypto, QR parser
 ├── repositories/   # Repository pattern over services + Firestore
 ├── widgets/        # Reusable UI (trust badge, cards, overlays)
 ├── features/       # Feature modules (auth, splash, home, verification, …)
 ├── routes/         # GoRouter config + paths
 ├── firebase_options.dart
 ├── app.dart
 └── main.dart
functions/           # Cloud Functions: Razorpay order/verify/webhook (TypeScript)
firestore.rules      # Security rules
storage.rules
```

### Tech stack
Flutter • Firebase (Auth, Firestore, Storage, Crashlytics, Analytics) •
Riverpod • GoRouter • GetIt • Dio • SurePass • Razorpay • flutter_secure_storage
• mobile_scanner • xml • pdf/printing • share_plus • permission_handler •
connectivity_plus • logger.

## 🔐 Security & compliance (DPDP Act, 2023)

- **Explicit consent** is captured before any verification and recorded with an
  audit trail.
- Aadhaar numbers are **masked** (`XXXX XXXX 9012`); the full number is never
  reconstructed (the Secure QR only exposes the last 4 digits).
- Face images are **processed in-memory and never stored** (enforced in code and
  in `storage.rules`).
- Sensitive local data is encrypted with **AES-256**; keys live in the platform
  secure enclave via `flutter_secure_storage`.
- Razorpay signatures are verified **server-side**; the key secret never touches
  the client.
- Firestore rules **default-deny** and scope every read/write to its owner.
- Users can **erase** their data (soft delete) from Settings.

## 🚀 Getting started

See [`SETUP_GUIDE.md`](SETUP_GUIDE.md) for full, step-by-step instructions
(Firebase, SurePass, Razorpay, platform config, release signing).

Quick start:

```bash
cp .env.example .env          # fill in SurePass + Razorpay values
flutterfire configure         # generates lib/firebase_options.dart
flutter pub get
flutter run       #flutter run -d chrome --no-dds
```

## 🧪 Tests

```bash
flutter test
```

Unit tests cover the Trust Score calculator, validators, Aadhaar masking and the
Aadhaar QR/XML parser — the pure-logic core of the verification pipeline.

## 📦 Build

```bash
flutter build appbundle --release   # Play Store
flutter build ipa --release         # App Store
```

## 📄 License

Proprietary © Trvsty. All rights reserved.
