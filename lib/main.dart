import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/utils/app_logger.dart';
import 'firebase_options.dart';

/// Application entry point.
///
/// Bootstraps, in order: environment variables, Firebase, Crashlytics error
/// forwarding, and the GetIt service locator — then runs the app inside a
/// Riverpod [ProviderScope].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load secrets from `.env` (see `.env.example`).
  await dotenv.load(fileName: '.env');

  // 2. Initialise Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Route uncaught Flutter & platform errors to Crashlytics (release only).
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // 4. Register dependencies.
  await setupServiceLocator();

  AppLogger.i('Trvsty bootstrap complete.');

  runApp(const ProviderScope(child: TrvstyApp()));
}
