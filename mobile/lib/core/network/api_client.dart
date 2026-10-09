import 'dart:async';

import 'package:dio/dio.dart';

import '../error/failure.dart';
import '../utils/json.dart';
import 'token_storage.dart';

/// Thin HTTP client for the REWIFY API.
///
/// * attaches the JWT to every request,
/// * converts every error into a [Failure] with a French message,
/// * emits on [unauthorized] when the server answers 401 so the app can sign out.
class ApiClient {
  ApiClient({required String baseUrl, required TokenStorage tokens, Dio? dio})
      : _tokens = tokens,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.read();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ));
  }

  final Dio _dio;
  final TokenStorage _tokens;
  final _unauthorized = StreamController<void>.broadcast();

  /// Fires when an authenticated call is rejected with 401.
  Stream<void> get unauthorized => _unauthorized.stream;

  Future<Object?> get(String path, {Map<String, Object?>? query}) =>
      _send(() => _dio.get<Object?>(path, queryParameters: query));

  Future<Object?> post(String path, {Object? body, Map<String, Object?>? query}) =>
      _send(() => _dio.post<Object?>(path, data: body, queryParameters: query));

  Future<Object?> put(String path, {Object? body}) => _send(() => _dio.put<Object?>(path, data: body));

  Future<Object?> delete(String path) => _send(() => _dio.delete<Object?>(path));

  Future<Json> getJson(String path, {Map<String, Object?>? query}) async => asObj(await get(path, query: query));

  Future<List<Json>> getList(String path, {Map<String, Object?>? query}) async =>
      asObjList(await get(path, query: query));

  Future<Json> postJson(String path, {Object? body}) async => asObj(await post(path, body: body));

  Future<Object?> _send(Future<Response<Object?>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  Failure _toFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.cancel:
        return const NetworkFailure('Requête annulée.');
      case DioExceptionType.badCertificate:
        return const NetworkFailure('Connexion non sécurisée refusée.');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }
    final status = e.response?.statusCode;
    if (status == null) return const NetworkFailure();

    final body = asObj(e.response?.data);
    final message = body.strOrNull('message');
    if (status == 401) {
      final isLogin = e.requestOptions.path.contains('/auth/');
      if (!isLogin) _unauthorized.add(null);
      return UnauthorizedFailure(isLogin ? 'Identifiant ou mot de passe incorrect.' : 'Session expirée, reconnecte-toi.');
    }
    if (status == 400) {
      final fields = body.obj('errors').map((k, v) => MapEntry(k, v.toString()));
      return ValidationFailure(message ?? 'Données invalides.', fieldErrors: fields);
    }
    return ServerFailure(_frenchMessage(status, message), statusCode: status);
  }

  static String _frenchMessage(int status, String? serverMessage) => switch (status) {
        402 => 'Solde insuffisant.',
        403 => serverMessage ?? 'Action non autorisée.',
        404 => serverMessage ?? 'Introuvable.',
        409 => serverMessage ?? 'Conflit : déjà fait.',
        503 => serverMessage ?? 'Service indisponible pour le moment.',
        >= 500 => 'Le serveur a rencontré un problème. Réessaie plus tard.',
        _ => serverMessage ?? 'Erreur $status.',
      };

  void dispose() => _unauthorized.close();
}
