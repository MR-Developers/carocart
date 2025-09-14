import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';

class ContactUsService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "${ApiConstants.baseUrl}:8080",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  );

  /// Sends contact form data to the backend
  static Future<Response> sendContactMessage({
    required String name,
    required String email,
    required String topic,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        "/notifications/contact",
        data: {
          "name": name.trim(),
          "email": email.trim(),
          "topic": topic,
          "message": message.trim(),
        },
      );
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      } else {
        throw Exception("Network error: ${e.message}");
      }
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }
}
