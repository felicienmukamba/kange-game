import 'package:equatable/equatable.dart';

/// An expected error surfaced to the UI with a user-facing (French) message.
///
/// Repositories throw a [Failure]; BLoCs catch it and expose [message].
sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [runtimeType, message];

  @override
  String toString() => '$runtimeType: $message';
}

/// No connection, timeout, DNS failure…
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Connexion impossible. Vérifie ton réseau.']);
}

/// The session expired or the credentials are wrong.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expirée, reconnecte-toi.']);
}

/// The server rejected the input; [fieldErrors] maps field names to messages.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// Any other non-2xx response.
final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Local problem: unreadable asset, unexpected payload…
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Une erreur inattendue est survenue.']);
}
