import 'user_profile.dart';

/// Authentication and the signed-in user's profile.
abstract interface class AuthRepository {
  /// Returns the profile for a stored session, or `null` when signed out.
  Future<UserProfile?> restoreSession();

  Future<UserProfile> login({required String username, required String password});

  Future<UserProfile> register({
    required String username,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> logout();

  Future<UserProfile> fetchProfile();

  Future<UserProfile> updateProfile({String? avatar, String? bio});

  /// Emits when the server rejects the stored session.
  Stream<void> get sessionExpired;
}
