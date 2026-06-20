# Changelog

All notable changes to Trusty are documented here. This project adheres to
[Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-06-20

Initial production release.

### Added
- **Authentication**: Firebase Phone OTP login with resend cool-down and
  auto-retrieval handling.
- **DPDP consent gate**: explicit, recorded consent before any verification.
- **Verification pipeline**: Aadhaar Secure QR scan → XML/Secure-QR parse →
  Face Match → PAN verification → Criminal Record check → Payment → Trust Score
  → Verification badge → PDF report → History.
- **SurePass integration layer** (`SurepassService`) for Face Match, PAN,
  Criminal Record and DigiLocker, with response unwrapping and validation.
- **Trust Score calculator** (domain): weighted aggregate (Aadhaar 25, Face 30,
  PAN 25, Criminal 20) with proportional face-match credit.
- **PDF reports** with QR code, masked Aadhaar, scores; view / print / share.
- **Razorpay** one-time payments and business subscriptions, with server-side
  order creation, **signature verification** and **webhooks** via Cloud
  Functions.
- **Firestore** data layer with soft deletes, timestamps, audit logs and
  hardened security rules + composite indexes.
- **State / DI / routing**: Riverpod, GetIt service locator, GoRouter with auth
  redirect guards.
- **Material 3** dark brand theme, animated splash, reusable widgets, trust
  badge.
- Unit tests for Trust Score, validators, masking and the Aadhaar QR parser.
- README, Setup Guide, environment configuration and release build docs.

### Security
- Aadhaar masking everywhere; full number never reconstructed.
- Face images processed in-memory only; never persisted (enforced in
  `storage.rules`).
- AES-256 local encryption with keys in the platform secure enclave.
- Razorpay key secret kept server-side; client never sees it.
- Crashlytics wired for release builds.

### Engineering decisions & assumptions
- **Models without code-gen**: data models are hand-written immutable classes
  with explicit `fromJson`/`toFirestore`/`copyWith` rather than `freezed`/
  `json_serializable`, so the project compiles without a `build_runner` step.
  (The codegen packages remain available for teams that prefer them.)
- **Firebase config**: `lib/firebase_options.dart` ships with clearly-marked
  placeholders and fails fast at runtime until `flutterfire configure` is run,
  since these values are project-specific.
- **Face-match reference image**: the Aadhaar Secure QR embeds a JPEG photo. To
  keep biometric data off the device, the reference image is resolved
  server-side from the scanned reference id; the client only transmits the live
  selfie for comparison.
- **Pricing**: individual verification is priced at ₹99; subscription tiers
  (Starter ₹999 / Professional ₹2,999 / Enterprise ₹9,999 per month) are defined
  in `SubscriptionPlan.catalogue` and can be tuned without code changes
  elsewhere.
- **Business id**: for single-owner business accounts the business document id
  mirrors the owner uid; multi-seat orgs can extend this mapping.
- **Native scaffolding** (`android/`, `ios/`, `web/`) is generated via
  `flutter create .` to avoid committing machine-specific build files; required
  manifest/permission edits are documented in `SETUP_GUIDE.md`.
