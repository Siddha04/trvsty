/// Centralised route path constants. Using constants avoids stringly-typed
/// navigation bugs and keeps the router and call-sites in sync.
class RoutePaths {
  const RoutePaths._();

  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String consent = '/consent';
  static const String home = '/home';

  // Verification pipeline
  static const String scanAadhaar = '/verify/scan';
  static const String faceCapture = '/verify/face';
  static const String panEntry = '/verify/pan';
  static const String criminalCheck = '/verify/criminal';
  static const String payment = '/verify/payment';
  static const String result = '/verify/result';
  static const String digilocker = '/verify/digilocker';

  // Other
  static const String report = '/report';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String subscriptions = '/subscriptions';
}
