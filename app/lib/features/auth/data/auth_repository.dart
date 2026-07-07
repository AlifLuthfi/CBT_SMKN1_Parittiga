import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/security/security_service.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_models.dart';

class AuthRepository {
  Future<({String token, UserModel user})> login(String email, String password) async {
    try {
      final dio      = await ApiClient.getInstance();
      final deviceId = await SecurityService.getDeviceId();
      final resp     = await dio.post('/auth/login', data: {
        'email':       email,
        'password':    password,
        'device_name': 'ExamCore Mobile',
        'device_id':   deviceId,
      });

      if (resp.statusCode == 422) {
        final msg = resp.data['message'] ?? 'Email atau password salah.';
        throw ApiException(message: msg.toString(), statusCode: 422);
      }

      final token = resp.data['token'] as String;
      final user  = UserModel.fromJson(Map<String, dynamic>.from(resp.data['user'] as Map));

      await SecureStorage.saveToken(token);
      await SecureStorage.saveUser(user.toJson());
      await SecureStorage.saveRole(user.role);
      ApiClient.reset();

      return (token: token, user: user);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> me() async {
    try {
      final dio  = await ApiClient.getInstance();
      final resp = await dio.get('/auth/me');
      return UserModel.fromJson(Map<String, dynamic>.from(resp.data['user'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      final dio = await ApiClient.getInstance();
      await dio.post('/auth/logout');
    } catch (_) {}
    await SecureStorage.clearAuth();
    ApiClient.reset();
  }

  Future<void> logoutAll() async {
    try {
      final dio = await ApiClient.getInstance();
      await dio.post('/auth/logout-all');
    } catch (_) {}
    await SecureStorage.clearAll();
    ApiClient.reset();
  }
}
