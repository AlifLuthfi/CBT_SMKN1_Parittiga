import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

class ApiClient {
  static Dio? _dio;

  static Future<Dio> getInstance() async {
    if (_dio != null) return _dio!;

    final baseUrl = await SecureStorage.getBaseUrl();
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
    );

    _dio = Dio(options);

    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await SecureStorage.clearAuth();
            reset();
          }
          return handler.next(e);
        },
      ),
    );

    return _dio!;
  }

  static void reset() {
    _dio = null;
  }

  static Future<void> updateBaseUrl(String url) async {
    await SecureStorage.saveBaseUrl(url);
    reset();
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final dio = await getInstance();
      final response = await dio.get(path, queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  static Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final dio = await getInstance();
      final response = await dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  static Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final dio = await getInstance();
      final response = await dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  static Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final dio = await getInstance();
      final response = await dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  static Future<dynamic> delete(String path, {dynamic data}) async {
    try {
      final dio = await getInstance();
      final response = await dio.delete(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Upload file dari path (native)
  static Future<dynamic> uploadFile(String path, String fileField, String filePath, Map<String, dynamic> fields, {String method = 'POST'}) async {
    try {
      final dio   = await getInstance();
      final form  = FormData.fromMap({
        fileField: await MultipartFile.fromFile(filePath, filename: filePath.split(RegExp(r'[/\\]')).last),
        ...fields.map((k, v) => MapEntry(k, v is List ? v.map((e) => e.toString()).join(',') : (v?.toString() ?? ''))),
      });
      final response = method == 'PUT'
          ? await dio.put(path, data: form)
          : await dio.post(path, data: form);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Upload file dari bytes (web — klo [path] ga available)
  static Future<dynamic> uploadFileBytes(String path, String fileField, Uint8List bytes, String filename, Map<String, dynamic> fields, {String method = 'POST'}) async {
    try {
      final dio   = await getInstance();
      final form  = FormData.fromMap({
        fileField: MultipartFile.fromBytes(bytes, filename: filename),
        ...fields.map((k, v) => MapEntry(k, v is List ? v.map((e) => e.toString()).join(',') : (v?.toString() ?? ''))),
      });
      final response = method == 'PUT'
          ? await dio.put(path, data: form)
          : await dio.post(path, data: form);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
