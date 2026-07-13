import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioError(DioException error) {
    String message = 'Terjadi kesalahan server. Coba lagi.';
    int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Koneksi timeout — pastikan server backend running dan URL benar.';
        break;
      case DioExceptionType.connectionError:
        message = 'Server tidak dapat dijangkau. Periksa koneksi & pastikan backend jalan.';
        break;
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map) {
          if (data['message'] != null) message = data['message'].toString();
          else if (data['error'] != null) message = data['error'].toString();
        }
        break;
      default:
        message = 'Kesalahan: ${error.message ?? "tidak diketahui"}';
    }
    return ApiException(message: message, statusCode: statusCode);
  }

  @override
  String toString() => message;
}
