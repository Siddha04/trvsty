/// Low-level exceptions thrown by the data layer.
///
/// These are caught by repositories and mapped to [Failure]s before reaching
/// the presentation layer.
library;

class ServerException implements Exception {
  ServerException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  NetworkException([this.message = 'No internet connection.']);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  AuthException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'AuthException($code): $message';
}

class CacheException implements Exception {
  CacheException(this.message);
  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class VerificationException implements Exception {
  VerificationException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'VerificationException($code): $message';
}
