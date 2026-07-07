import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioError(DioException error) {
    String message = 'Terjadi kesalahan pada server. Silakan coba lagi.';
    int? statusCode = error.response?.statusCode;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Koneksi ke server timeout. Periksa jaringan Anda.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Tidak dapat terhubung ke server. Periksa URL dan jaringan Anda.';
    } else if (error.response != null) {
      final data = error.response?.data;
      if (data is Map) {
        if (data.containsKey('message')) {
          message = data['message'].toString();
        } else if (data.containsKey('error')) {
          message = data['error'].toString();
        }
      }
    }
    return ApiException(message: message, statusCode: statusCode);
  }

  @override
  String toString() => message;
}
