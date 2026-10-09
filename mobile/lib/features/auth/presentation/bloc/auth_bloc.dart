import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/auth_repository.dart';
import '../../domain/user_profile.dart';

// ---------------------------------------------------------------- events

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested(this.username, this.password);

  final String username;
  final String password;

  @override
  List<Object?> get props => [username];
}

final class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({required this.username, required this.email, required this.password, required this.role});

  final String username;
  final String email;
  final String password;
  final UserRole role;

  @override
  List<Object?> get props => [username, email, role];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Re-fetches the profile (after a game, a purchase, a quest…).
final class AuthProfileRefreshed extends AuthEvent {
  const AuthProfileRefreshed();
}

/// Applies a profile already returned by another endpoint, avoiding a round trip.
final class AuthProfileUpdated extends AuthEvent {
  const AuthProfileUpdated(this.user);

  final UserProfile user;

  @override
  List<Object?> get props => [user];
}

/// Locally adjusts the balance / XP after an action whose response only carries numbers.
final class AuthStatsPatched extends AuthEvent {
  const AuthStatsPatched({this.coins, this.xp, this.level});

  final int? coins;
  final int? xp;
  final int? level;

  @override
  List<Object?> get props => [coins, xp, level];
}

final class _AuthSessionExpired extends AuthEvent {
  const _AuthSessionExpired();
}

// ---------------------------------------------------------------- state

enum AuthStatus { unknown, authenticated, unauthenticated }

final class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.user, this.busy = false, this.error, this.fieldErrors = const {}});

  final AuthStatus status;
  final UserProfile? user;
  final bool busy;
  final String? error;
  final Map<String, String> fieldErrors;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    bool? busy,
    String? error,
    Map<String, String>? fieldErrors,
    bool clearUser = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: clearUser ? null : (user ?? this.user),
        busy: busy ?? this.busy,
        error: error,
        fieldErrors: fieldErrors ?? const {},
      );

  @override
  List<Object?> get props => [status, user, busy, error, fieldErrors];
}

// ---------------------------------------------------------------- bloc

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthProfileRefreshed>(_onRefresh);
    on<AuthProfileUpdated>((e, emit) => emit(state.copyWith(user: e.user)));
    on<AuthStatsPatched>(_onPatch);
    on<_AuthSessionExpired>(_onExpired);
    _expiredSub = _repository.sessionExpired.listen((_) => add(const _AuthSessionExpired()));
  }

  final AuthRepository _repository;
  late final StreamSubscription<void> _expiredSub;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await _repository.restoreSession();
      emit(user == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, user: user));
    } on Failure catch (f) {
      // Offline at launch with a stored token: stay signed out but explain why.
      emit(AuthState(status: AuthStatus.unauthenticated, error: f.message));
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(busy: true));
    try {
      final user = await _repository.login(username: event.username, password: event.password);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on Failure catch (f) {
      emit(state.copyWith(busy: false, error: f.message, fieldErrors: f is ValidationFailure ? f.fieldErrors : null));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(busy: true));
    try {
      final user = await _repository.register(
        username: event.username,
        email: event.email,
        password: event.password,
        role: event.role,
      );
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on Failure catch (f) {
      emit(state.copyWith(busy: false, error: f.message, fieldErrors: f is ValidationFailure ? f.fieldErrors : null));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onRefresh(AuthProfileRefreshed event, Emitter<AuthState> emit) async {
    if (state.status != AuthStatus.authenticated) return;
    try {
      emit(state.copyWith(user: await _repository.fetchProfile()));
    } on Failure {
      // Keep the cached profile; the next refresh will catch up.
    }
  }

  void _onPatch(AuthStatsPatched event, Emitter<AuthState> emit) {
    final user = state.user;
    if (user == null) return;
    emit(state.copyWith(user: user.copyWith(coins: event.coins, xp: event.xp, level: event.level)));
  }

  Future<void> _onExpired(_AuthSessionExpired event, Emitter<AuthState> emit) async {
    if (state.status != AuthStatus.authenticated) return;
    await _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated, error: 'Session expirée, reconnecte-toi.'));
  }

  @override
  Future<void> close() {
    _expiredSub.cancel();
    return super.close();
  }
}
