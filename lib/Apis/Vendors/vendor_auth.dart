import 'dart:convert';
import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';

class VendorApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.prodUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  /// Vendor login
  static Future<String> loginVendor(String email, String password) async {
    try {
      final response = await _dio.post(
        '/vendors/login',
        data: {"email": email, "password": password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return response.data.toString(); // JWT token
      } else if (response.statusCode == 403 &&
          response.data.toString().toLowerCase().contains("not approved")) {
        throw Exception("Your vendor account is pending approval.");
      } else {
        throw Exception("Login failed: ${response.data}");
      }
    } on DioError catch (e) {
      if (e.response != null) {
        throw Exception("Login failed: ${e.response?.data}");
      } else {
        throw Exception("Network error: ${e.message}");
      }
    }
  }

  /// Parse JWT token
  static Map<String, dynamic>? parseJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
