import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "${ApiConstants.baseUrl}:8080/products",
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  /// ✅ Fetch a single product by ID
  static Future<Map<String, dynamic>?> getProductById(int productId) async {
    try {
      final token = await _getToken();

      final response = await _dio.get(
        "/dto/$productId",
        options: Options(
          headers: token != null ? {"Authorization": "Bearer $token"} : null,
        ),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print("❌ Dio error while fetching product $productId");
      print("URL: ${e.requestOptions.uri}");
      print("Status: ${e.response?.statusCode}");
      print("Response: ${e.response?.data}");
      return null;
    } catch (e) {
      print("Unexpected error: $e");
      return null;
    }
  }
}
