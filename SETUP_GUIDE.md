# Trusty — Setup & Deployment Guide

This guide takes a fresh clone to a running, release-ready app.

> **Note on platform folders.** This repository ships the full Dart/Flutter
> source, Firebase config, security rules and Cloud Functions. The generated
> native scaffolding (`android/`, `ios/`, `web/`) is produced by Flutter itself.
> After cloning, run `flutter create .` once to (re)generate those folders, then
> apply the platform tweaks in §4. Your Dart code under `lib/` is never touched
> by this command.

---

## 1. Prerequisites

- Flutter SDK **3.22+** (`flutter --version`)
- Dart **3.4+**
- A Firebase project
- A SurePass account + API token
- A Razorpay account (test + live keys)
- Node.js **20** (for Cloud Functions)

## 2. Environment variables

```bash
cp .env.example .env
```

Fill in:

| Key | Where to get it |
|-----|-----------------|
| `SUREPASS_BASE_URL` | SurePass docs (default provided) |
| `SUREPASS_API_TOKEN` | SurePass dashboard → API token |
| `RAZORPAY_KEY_ID` | Razorpay dashboard → API keys (publishable) |
| `PAYMENT_VERIFY_ENDPOINT` | Your deployed Cloud Function URL |
| `APP_ENV` | `development` / `staging` / `production` |

The Razorpay **key secret** and SurePass credentials that move money/PII stay in
the backend — never in `.env` shipped to the client.

## 3. Firebase

1. Install the FlutterFire CLI and configure:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<your-project-id>
   ```
   This overwrites `lib/firebase_options.dart` and adds the native config files.

2. Enable **Phone Authentication** (Firebase Console → Authentication → Sign-in
   method). Add your debug SHA-1/SHA-256 (Android) for OTP auto-retrieval.

3. Create the Firestore database (production mode) and deploy the rules:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

   Collections used: `users`, `businesses`, `verification_history`, `payments`,
   `subscriptions`, `reports`, `analytics`, `logs`.

## 4. Platform configuration

### Android (`android/app/src/main/AndroidManifest.xml`)
Add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
```
- Set `minSdkVersion 23` (Razorpay + Firebase Auth) in `android/app/build.gradle`.
- Add the Razorpay ProGuard rules (`android/app/proguard-rules.pro`):
  ```
  -keep class com.razorpay.** { *; }
  -keepattributes *Annotation*
  -dontwarn com.razorpay.**
  ```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>Trusty uses the camera to scan Aadhaar QR codes and capture a selfie for face match.</string>
```
Set the iOS deployment target to **13.0+** in `ios/Podfile`.

## 5. Cloud Functions (payments)

```bash
cd functions
npm install
firebase functions:secrets:set RAZORPAY_KEY_ID
firebase functions:secrets:set RAZORPAY_KEY_SECRET
firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
npm run deploy
```

Then in the Razorpay dashboard, add a **webhook** pointing to the deployed
`razorpayWebhook` URL for the events `payment.captured`, `payment.failed`,
`refund.processed`. Put the `verifyPayment` / `createOrder` base URL into
`PAYMENT_VERIFY_ENDPOINT`.

## 6. Run & test

```bash
flutter pub get
flutter test
flutter run
```

## 7. Release build

### Android
```bash
flutter build appbundle --release
```
Configure signing via `android/key.properties` (kept out of VCS):
```
storePassword=…
keyPassword=…
keyAlias=…
storeFile=/absolute/path/to/keystore.jks
```

### iOS
```bash
flutter build ipa --release
```

## 8. Pre-launch checklist

- [ ] `flutterfire configure` run; real `firebase_options.dart` in place
- [ ] `.env` populated; `APP_ENV=production`
- [ ] Firestore rules + indexes deployed
- [ ] Cloud Functions deployed; Razorpay webhook verified
- [ ] Razorpay switched to **live** keys
- [ ] Camera permissions + usage strings set on both platforms
- [ ] `flutter test` green
- [ ] Crashlytics receiving events
