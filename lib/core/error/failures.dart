import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
///
/// Failures are the *expected*, recoverable error states surfaced to the
/// presentation layer. Unexpected programming errors should still throw.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.code});

  /// Human-readable, user-safe message.
  final String message;

  /// Optional machine-readable error code (e.g. API status, Firebase code).
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// Network connectivity / transport failure.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// Server returned a non-success response.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Authentication / authorization failure.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Verification-pipeline failure (QR, face match, PAN, criminal record…).
class VerificationFailure extends Failure {
  const VerificationFailure(super.message, {super.code});
}

/// Payment failure.
class PaymentFailure extends Failure {
  const PaymentFailure(super.message, {super.code});
}

/// Local cache / storage failure.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Input validation failure.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Permission denied by the OS (camera, storage…).
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}
