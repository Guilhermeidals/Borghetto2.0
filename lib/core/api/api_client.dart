import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import '../../features/dependents/models/app_dependent.dart';
import '../../features/admin/models/admin_app_user.dart';
import '../../features/admin/models/admin_user_detail.dart';
import '../../features/marketing/models/marketing_banner.dart';
import '../utils/brazilian_formatters.dart';

import 'api_exception.dart';
import 'auth_session.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  VoidCallback? onSessionExpired;
  bool _isHandlingSessionExpired = false;

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

    final appVersion = buildNumber.isEmpty ? version : '$version+$buildNumber';

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
          } catch (_) {
            // Os dados de auditoria não devem impedir a requisição.
            handler.next(options);
          }
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final authorization =
              error.requestOptions.headers['Authorization']?.toString();
          final isAuthenticatedRequest =
              authorization != null && authorization.isNotEmpty;

          if (statusCode == 401 && isAuthenticatedRequest) {
            await _handleExpiredSession();
          }

          handler.next(error);
        },
      ),
    );

  Future<String?> getToken() {
    return _storage.read(key: 'auth_token');
  }

  Future<void> _handleExpiredSession() async {
    if (_isHandlingSessionExpired) {
      return;
    }

    _isHandlingSessionExpired = true;

    await _storage.deleteAll();

    onSessionExpired?.call();
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
    _isHandlingSessionExpired = false;

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

      final session =
          AuthSession.fromJson(response.data as Map<String, dynamic>);

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
          'cpf': onlyDigits(cpf),
          'phone': onlyDigits(phone),
          'birth_date': birthDate.trim(),
          'email': email.trim(),
          'password': password,
          'zip_code': onlyDigits(zipCode),
          'street': street.trim(),
          'number': number.trim(),
          'complement': complement?.trim(),
          'neighborhood': neighborhood.trim(),
          'city': city.trim(),
          'state': state.trim().toUpperCase(),
        },
      );

      final session =
          AuthSession.fromJson(response.data as Map<String, dynamic>);

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
          'cpf': onlyDigits(cpf),
          'phone': onlyDigits(phone),
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
          'phone': onlyDigits(phone),
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

      final cleanPhone = phone == null ? '' : onlyDigits(phone);

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

  Future<List<AppDependent>> getDependents(int userId) async {
    try {
      final response = await _dio.get('/app-users/$userId/dependents');

      final data = response.data;

      final rawDependents =
          data is Map<String, dynamic> ? data['dependents'] : null;

      if (rawDependents is! List) {
        return [];
      }

      return rawDependents
          .whereType<Map<String, dynamic>>()
          .map(AppDependent.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw ApiException('Erro ao buscar familiares');
    }
  }

  Future<AppDependent> createDependent({
    required int userId,
    required String name,
    required String cpf,
    required String birthDate,
    required String relationship,
  }) async {
    try {
      final response = await _dio.post(
        '/app-users/$userId/dependents',
        data: {
          'name': name.trim(),
          'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
          'birth_date': birthDate.trim(),
          'relationship': relationship,
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw ApiException('Resposta inválida ao criar familiar');
      }

      final rawDependent = data['dependent'];

      if (rawDependent is! Map<String, dynamic>) {
        throw ApiException('Dados do familiar não encontrados');
      }

      return AppDependent.fromJson(rawDependent);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Erro ao criar familiar');
    }
  }

  Future<AppDependent> updateDependent({
    required int userId,
    required int dependentId,
    required String name,
    required String cpf,
    required String birthDate,
    required String relationship,
    required bool active,
  }) async {
    try {
      final response = await _dio.put(
        '/app-users/$userId/dependents/$dependentId',
        data: {
          'name': name.trim(),
          'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
          'birth_date': birthDate.trim(),
          'relationship': relationship,
          'active': active,
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw ApiException('Resposta inválida ao atualizar familiar');
      }

      final rawDependent = data['dependent'];

      if (rawDependent is! Map<String, dynamic>) {
        throw ApiException('Dados do familiar não encontrados');
      }

      return AppDependent.fromJson(rawDependent);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Erro ao atualizar familiar');
    }
  }

  Future<void> deleteDependent({
    required int userId,
    required int dependentId,
  }) async {
    try {
      await _dio.delete('/app-users/$userId/dependents/$dependentId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw ApiException('Erro ao remover familiar');
    }
  }

  Future<void> uploadDependentFace({
    required int userId,
    required int dependentId,
    required File imageFile,
  }) async {
    try {
      final fileName = imageFile.path.split('/').last;

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      await _dio.post(
        '/app-users/$userId/dependents/$dependentId/face',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw ApiException('Erro ao enviar foto do familiar');
    }
  }

  ApiException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    String message = 'Erro ao comunicar com o servidor.';
    String? code;

    if (data is Map<String, dynamic>) {
      code = data['code']?.toString();

      message =
          data['message']?.toString() ?? data['error']?.toString() ?? message;
    } else if (data is String && data.trim().isNotEmpty) {
      message = data;
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Tempo limite ao conectar no servidor.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Não foi possível conectar ao servidor.';
    }

    if (statusCode == 401 && code == 'SESSION_EXPIRED') {
      unawaited(_handleExpiredSession());

      return ApiException(
        'Sessão expirada. Faça login novamente.',
        statusCode: statusCode,
      );
    }

    return ApiException(message, statusCode: statusCode);
  }

  Future<List<AdminAppUser>> getAdminAppUsers({
    String status = 'pending',
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'status': status,
      };

      final cleanSearch = search?.trim();

      if (cleanSearch != null && cleanSearch.isNotEmpty) {
        queryParameters['search'] = cleanSearch;
      }

      final response = await _dio.get(
        '/admin/app-users',
        queryParameters: queryParameters,
      );

      final data = response.data;

      final rawUsers = data is Map<String, dynamic> ? data['users'] : null;

      if (rawUsers is! List) {
        return [];
      }

      return rawUsers
          .whereType<Map<String, dynamic>>()
          .map(AdminAppUser.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw ApiException('Erro ao buscar usuários');
    }
  }

  Future<AdminAppUser> updateAdminUserApproval({
    required int userId,
    required bool approved,
    String? reviewNote,
  }) async {
    try {
      final data = <String, dynamic>{
        'approved': approved,
      };

      final cleanReviewNote = reviewNote?.trim();

      if (cleanReviewNote != null && cleanReviewNote.isNotEmpty) {
        data['review_note'] = cleanReviewNote;
      }

      final response = await _dio.put(
        '/admin/app-users/$userId/approval',
        data: data,
      );

      final responseData = response.data;

      final rawUser =
          responseData is Map<String, dynamic> ? responseData['user'] : null;

      if (rawUser is! Map<String, dynamic>) {
        throw ApiException('Resposta inválida ao atualizar aprovação');
      }

      return AdminAppUser.fromJson(rawUser);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Erro ao atualizar aprovação do usuário');
    }
  }

  Future<AdminUserDetail> getAdminUserDetail({
    required int userId,
  }) async {
    try {
      final response = await _dio.get('/admin/app-users/$userId');

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw ApiException('Resposta inválida ao buscar detalhes do usuário');
      }

      return AdminUserDetail.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Erro ao buscar detalhes do usuário');
    }
  }

  Future<void> updateAdminUser({
    required int userId,
    required String name,
    required String email,
    required String phone,
    required String cpf,
    required String birthDate,
    String? zipCode,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
  }) async {
    try {
      await _dio.put(
        '/admin/app-users/$userId',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'cpf': cpf,
          'birth_date': birthDate,
          'zip_code': zipCode,
          'street': street,
          'number': number,
          'complement': complement,
          'neighborhood': neighborhood,
          'city': city,
          'state': state,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Erro ao atualizar usuário');
    }
  }

  Future<void> logoutAllUserSessions(int userId) async {
    try {
      await _dio.post('/admin/app-users/$userId/logout-all');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Erro ao derrubar sessões do usuário');
    }
  }

  Future<Uint8List> getFacialUserPhotoBytes(int facialUserId) async {
    try {
      final response = await _dio.get(
        '/facial/users/$facialUserId/face',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      final data = response.data;

      if (data == null) {
        throw ApiException('Foto não encontrada');
      }

      if (data is Uint8List) {
        return data;
      }

      if (data is List<int>) {
        return Uint8List.fromList(data);
      }

      throw ApiException('Formato de foto inválido');
    } on DioException catch (e) {
      throw ApiException(
        'Erro ao carregar foto facial: ${e.response?.statusCode ?? e.message}',
      );
    } catch (_) {
      throw ApiException('Erro ao carregar foto facial');
    }
  }

  Future<List<Map<String, dynamic>>> getAccessLogs() async {
    try {
      final response = await _dio.get('/access-logs');

      final data = response.data;
      final rawLogs = data is Map ? data['access_logs'] : null;

      if (rawLogs is! List) {
        return [];
      }

      return rawLogs
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Erro ao carregar histórico de acessos');
    }
  }

  Future<List<MarketingBanner>> getMarketingBanners({
    bool admin = false,
  }) async {
    try {
      final response = await _dio.get(
        admin ? '/admin/marketing/banners' : '/marketing/banners',
      );
      final data = response.data;
      final rawBanners = data is List
          ? data
          : data is Map<String, dynamic>
              ? data['banners']
              : null;

      if (rawBanners is! List) return [];

      final banners = rawBanners
          .whereType<Map<String, dynamic>>()
          .map(MarketingBanner.fromJson)
          .where((banner) => banner.id > 0 && banner.imageUrl.isNotEmpty)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      return banners;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (_) {
      throw const ApiException('Erro ao carregar campanhas.');
    }
  }

  Future<MarketingBanner> createMarketingBanner({
    required XFile imageFile,
    String? title,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      if (imageBytes.length > 8 * 1024 * 1024) {
        throw const ApiException('A imagem deve ter no máximo 8 MB.');
      }

      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: imageFile.name,
          contentType: _marketingImageMediaType(imageFile),
        ),
        if (title?.trim().isNotEmpty == true) 'title': title!.trim(),
      });
      final response = await _dio.post(
        '/admin/marketing/banners',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      final rawBanner =
          data is Map<String, dynamic> && data['banner'] is Map<String, dynamic>
              ? data['banner'] as Map<String, dynamic>
              : data;

      if (rawBanner is! Map<String, dynamic>) {
        throw const ApiException('Resposta inválida ao criar campanha.');
      }
      return MarketingBanner.fromJson(rawBanner);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Erro ao enviar campanha.');
    }
  }

  MediaType _marketingImageMediaType(XFile imageFile) {
    final path = imageFile.name.toLowerCase();
    if (path.endsWith('.png')) return MediaType('image', 'png');
    if (path.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  Future<void> updateMarketingBanner({
    required int bannerId,
    required bool active,
  }) async {
    try {
      await _dio.put(
        '/admin/marketing/banners/$bannerId',
        data: {'active': active},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<MarketingBanner> editMarketingBanner({
    required int bannerId,
    required String title,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/marketing/banners/$bannerId',
        data: {
          'title': title.trim(),
          'starts_at': startsAt?.toUtc().toIso8601String(),
          'ends_at': endsAt?.toUtc().toIso8601String(),
        },
      );
      final data = response.data;
      final rawBanner =
          data is Map<String, dynamic> && data['banner'] is Map<String, dynamic>
              ? data['banner'] as Map<String, dynamic>
              : null;

      if (rawBanner == null) {
        throw const ApiException('Resposta inválida ao editar campanha.');
      }

      final updatedBanner = MarketingBanner.fromJson(rawBanner);

      if ((startsAt != null && updatedBanner.startsAt == null) ||
          (endsAt != null && updatedBanner.endsAt == null)) {
        throw const ApiException(
          'O servidor não confirmou a programação da campanha. Atualize o backend.',
        );
      }

      return updatedBanner;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> reorderMarketingBanners(List<int> bannerIds) async {
    try {
      await _dio.put(
        '/admin/marketing/banners/order',
        data: {'banner_ids': bannerIds},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteMarketingBanner(int bannerId) async {
    try {
      await _dio.delete('/admin/marketing/banners/$bannerId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
