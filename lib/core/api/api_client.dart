import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'api_exception.dart';
import 'auth_session.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://45.5.44.235:3000',
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _deviceIdStorageKey = 'app_installation_device_id';

  final Uuid _uuid = const Uuid();

  Map<String, String>? _cachedAuditHeaders;


  Future<String> _getOrCreateDeviceId() async {
    final savedDeviceId = await _storage.read(
      key: _deviceIdStorageKey,
    );

    if (savedDeviceId != null && savedDeviceId.trim().isNotEmpty) {
      return savedDeviceId.trim();
    }

    final newDeviceId = _uuid.v4();

    await _storage.write(
      key: _deviceIdStorageKey,
      value: newDeviceId,
    );

    return newDeviceId;
  }

  String _getPlatformName() {
    if (Platform.isAndroid) {
      return 'android';
    }

    if (Platform.isIOS) {
      return 'ios';
    }

    return Platform.operatingSystem;
  }

  Future<Map<String, String>> _getAuditHeaders() async {
    final cachedHeaders = _cachedAuditHeaders;

    if (cachedHeaders != null) {
      return cachedHeaders;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final deviceId = await _getOrCreateDeviceId();

    final version = packageInfo.version.trim();
    final buildNumber = packageInfo.buildNumber.trim();

    final appVersion = buildNumber.isEmpty
        ? version
        : '$version+$buildNumber';

    final headers = <String, String>{
      'X-Device-Id': deviceId,
      'X-App-Version': appVersion,
      'X-Platform': _getPlatformName(),
    };

    _cachedAuditHeaders = headers;

    return headers;
  }

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await getToken();

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }

            final auditHeaders = await _getAuditHeaders();

            options.headers.addAll(auditHeaders);

            handler.next(options);
          } catch (error, stackTrace) {
            print(
              'Erro ao preparar headers da requisição: '
              '$error\n$stackTrace',
            );

            
            // Os dados de auditoria não devem impedir a requisição.
            handler.next(options);
          }
        },
      ),
    );

  Future<String?> getToken() {
    return _storage.read(key: 'auth_token');
  }

  String resolveFileUrl(String? path) {
  if (path == null || path.trim().isEmpty) {
    return '';
  }

  final value = path.trim();

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  if (value.startsWith('/')) {
    return '$baseUrl$value';
  }

  return '$baseUrl/$value';
}

  Future<AuthSession?> getSavedSession() async {
    final raw = await _storage.read(key: 'auth_session');

    if (raw == null || raw.isEmpty) {
      return null;
    }

    return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: 'auth_token', value: session.token);
    await _storage.write(
      key: 'auth_session',
      value: jsonEncode(session.toJson()),
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'auth_session');
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final session = AuthSession.fromJson(response.data as Map<String, dynamic>);

      if (session.token.isEmpty) {
        throw const ApiException('Servidor não retornou token de acesso.');
      }

      await saveSession(session);
      return session;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AuthSession> registerUser({
    required String name,
    required String cpf,
    required String phone,
    required String birthDate,
    required String email,
    required String password,
    required String zipCode,
    required String street,
    required String number,
    String? complement,
    required String neighborhood,
    required String city,
    required String state,
  }) async {
    try {
      final response = await _dio.post(
        '/users',
        data: {
          'name': name.trim(),
          'cpf': _onlyDigits(cpf),
          'phone': _onlyDigits(phone),
          'birth_date': birthDate.trim(),
          'email': email.trim(),
          'password': password,
          'zip_code': _onlyDigits(zipCode),
          'street': street.trim(),
          'number': number.trim(),
          'complement': complement?.trim(),
          'neighborhood': neighborhood.trim(),
          'city': city.trim(),
          'state': state.trim().toUpperCase(),
        },
      );

      final session = AuthSession.fromJson(response.data as Map<String, dynamic>);

      if (session.token.isNotEmpty) {
        await saveSession(session);
      }

      return session;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AuthSession> updateUser({
    required int userId,
    required String name,
    required String cpf,
    required String phone,
    required String email,
  }) async {
    try {
      final response = await _dio.put(
        '/users/$userId',
        data: {
          'name': name.trim(),
          'cpf': _onlyDigits(cpf),
          'phone': _onlyDigits(phone),
          'email': email.trim(),
        },
      );

      final saved = await getSavedSession();

      final updated = AuthSession.fromJson({
        'token': saved?.token ?? await getToken() ?? '',
        'user': response.data,
      });

      await saveSession(updated);

      return updated;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> openDoor() async {
    try {
      final response = await _dio.post('/access/open-door');

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw ApiException('Resposta inválida ao liberar porta.');
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        throw ApiException(data['message'].toString());
      }

      throw ApiException('Erro ao liberar porta.');
    } catch (error) {
      if (error is ApiException) {
        rethrow;
      }

      throw ApiException('Erro inesperado ao liberar porta.');
    }
  }

  Future<AuthSession> updateUserPhone({
    required int userId,
    required String phone,
  }) async {
    try {
      final response = await _dio.put(
        '/app-users/$userId/phone',
        data: {
          'phone': _onlyDigits(phone),
        },
      );

      final saved = await getSavedSession();

      final responseData = response.data;

      final userData = responseData is Map<String, dynamic> &&
              responseData.containsKey('user')
          ? responseData['user']
          : responseData;

      if (userData is! Map<String, dynamic>) {
        throw const ApiException(
          'Resposta inválida do servidor ao atualizar telefone.',
        );
      }

      final updated = AuthSession.fromJson({
        'token': saved?.token ?? await getToken() ?? '',
        'user': userData,
      });

      await saveSession(updated);

      return updated;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AuthSession> updateProfileSecurity({
    required int userId,
    String? phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final data = <String, dynamic>{};

      final cleanPhone = phone == null ? '' : _onlyDigits(phone);

      if (cleanPhone.isNotEmpty) {
        data['phone'] = cleanPhone;
      }

      if (newPassword != null && newPassword.trim().isNotEmpty) {
        data['current_password'] = currentPassword ?? '';
        data['new_password'] = newPassword;
      }

      if (data.isEmpty) {
        throw const ApiException(
          'Informe telefone e/ou nova senha para atualizar.',
        );
      }

      final response = await _dio.put(
        '/app-users/$userId/profile-security',
        data: data,
      );

      final saved = await getSavedSession();

      final responseData = response.data;

      final userData = responseData is Map<String, dynamic> &&
              responseData.containsKey('user')
          ? responseData['user']
          : responseData;

      if (userData is! Map<String, dynamic>) {
        throw const ApiException(
          'Resposta inválida do servidor ao atualizar perfil.',
        );
      }

      final updated = AuthSession.fromJson({
        'token': saved?.token ?? await getToken() ?? '',
        'user': userData,
      });

      await saveSession(updated);

      return updated;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AuthSession> uploadSelfie({
    required int facialUserId,
    required File imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'selfie': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'selfie_$facialUserId.jpg',
        ),
      });

      final response = await _dio.post(
        '/users/$facialUserId/selfie',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final saved = await getSavedSession();

      final updated = AuthSession.fromJson({
        'token': saved?.token ?? await getToken() ?? '',
        'user': response.data,
      });

      await saveSession(updated);

      return updated;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AuthSession> me() async {
    try {
      final response = await _dio.get('/auth/me');
      final saved = await getSavedSession();

      final session = AuthSession.fromJson({
        'token': saved?.token ?? await getToken() ?? '',
        'user': response.data,
      });

      await saveSession(session);

      return session;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  ApiException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    String message = 'Erro ao comunicar com o servidor.';

    if (data is Map<String, dynamic>) {
      message = data['message']?.toString() ??
          data['error']?.toString() ??
          message;
    } else if (data is String && data.trim().isNotEmpty) {
      message = data;
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Tempo limite ao conectar no servidor.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Não foi possível conectar ao servidor.';
    }

    return ApiException(message, statusCode: statusCode);
  }
}