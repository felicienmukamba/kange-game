import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/utils/json.dart';
import '../domain/auth_repository.dart';
import '../domain/user_profile.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  @override
  Stream<void> get sessionExpired => _api.unauthorized;

  @override
  Future<UserProfile?> restoreSession() async {
    if (await _tokens.read() == null) return null;
    try {
      return await fetchProfile();
    } on UnauthorizedFailure {
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<UserProfile> login({required String username, required String password}) async {
    final json = await _api.postJson('/auth/authenticate', body: {'username': username.trim(), 'password': password});
    return _store(json);
  }

  @override
  Future<UserProfile> register({
    required String username,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final json = await _api.postJson('/auth/register', body: {
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
      'role': role.apiName,
    });
    return _store(json);
  }

  Future<UserProfile> _store(Json json) async {
    final token = json.strOrNull('token');
    if (token == null) throw const UnexpectedFailure('Réponse du serveur invalide.');
    await _tokens.write(token);
    return UserProfile.fromJson(json.obj('user'));
  }

  @override
  Future<void> logout() => _tokens.clear();

  @override
  Future<UserProfile> fetchProfile() async => UserProfile.fromJson(await _api.getJson('/profile/me'));

  @override
  Future<UserProfile> updateProfile({String? avatar, String? bio}) async {
    final json = asObj(await _api.put('/profile/update', body: {'avatar': ?avatar, 'bio': ?bio}));
    return UserProfile.fromJson(json);
  }
}
