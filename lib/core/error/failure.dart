abstract class Failure {
  final String message;
  final dynamic originalError;

  const Failure(this.message, {this.originalError});

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.originalError});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.originalError});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.originalError});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.originalError});
}

class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure(super.message, {super.originalError});
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.originalError});
}
