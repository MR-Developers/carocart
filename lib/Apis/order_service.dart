import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "${ApiConstants.baseUrl}:8080/orders",
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  static Future<Response?> placeOrder({
    required List<Map<String, dynamic>> items,
    required int totalAmount,
    required String paymentMethod,
    required String shippingAdress,
    required int addressId,
    required int userId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Not authenticated");

      final response = await _dio.post(
        "/place",
        data: {
          "userId": userId,
          "items": items,
          "totalAmount": totalAmount,
          "paymentMethod": paymentMethod,
          "addressId": addressId,
          "shippingAddress": shippingAdress,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return response;
    } on DioException catch (e) {
      print("❌ Dio error placing order: ${e.response?.data}");
      return e.response;
    } catch (e) {
      print("❌ Unexpected error: $e");
      return null;
    }
  }
}
