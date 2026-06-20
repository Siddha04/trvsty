import '../error/failures.dart';

/// A lightweight functional [Result] type used across repositories.
///
/// Repositories return `Result<T>` instead of throwing, so the presentation
/// layer can exhaustively handle both the success and failure branches.
sealed class Result<T> {
  const Result();

  /// Returns `true` when this result represents a success.
  bool get isSuccess => this is Success<T>;

  /// Returns `true` when this result represents a failure.
  bool get isFailure => this is ResultFailure<T>;

  /// The success value, or `null` if this is a failure.
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        ResultFailure<T>() => null,
      };

  /// Folds both branches into a single value of type [R].
  R fold<R>(R Function(Failure failure) onFailure, R Function(T value) onSuccess) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      ResultFailure<T>(:final failure) => onFailure(failure),
    };
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);
  final Failure failure;
}
