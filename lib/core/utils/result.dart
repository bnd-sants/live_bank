import 'package:live_bank/core/error/failure.dart';

sealed class Result<T> {
  const Result();

  factory Result.success(T value) = Success<T>;
  factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  T? get value => this is Success<T> ? (this as Success<T>).data : null;
  Failure? get failure => this is FailureResult<T> ? (this as FailureResult<T>).error : null;

  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Failure failure) onFailure,
  ) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    } else {
      return onFailure((this as FailureResult<T>).error);
    }
  }

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) => fold(success, failure);
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class FailureResult<T> extends Result<T> {
  final Failure error;
  const FailureResult(this.error);
}
