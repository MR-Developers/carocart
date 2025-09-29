import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorOrderService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.prodUrl, // Replace with your API base
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token") ?? "";
    return {"Authorization": "Bearer $token"};
  }

  static Future<List<Map<String, dynamic>>> getPendingOrderItems() async {
    try {
      final headers = await _getAuthHeaders();
      final res = await _dio.get(
        "/orders/vendor/orders/pending",
        options: Options(headers: headers),
      );
      return List<Map<String, dynamic>>.from(res.data);
    } catch (e) {
      throw Exception("Failed to fetch pending order items: $e");
    }
  }

  static Future<void> approveOrderItem(String orderItemId) async {
    try {
      final headers = await _getAuthHeaders();
      await _dio.put(
        "/orders/vendor/orders/$orderItemId/approve",
        options: Options(headers: headers),
      );
    } catch (e) {
      throw Exception("Failed to approve order item: $e");
    }
  }

  static Future<void> rejectOrderItem(String orderItemId) async {
    try {
      final headers = await _getAuthHeaders();
      await _dio.put(
        "/orders/vendor/orders/$orderItemId/reject",
        options: Options(headers: headers),
      );
    } catch (e) {
      throw Exception("Failed to reject order item: $e");
    }
  }

  static Future<Map<String, dynamic>> getProductById(String productId) async {
    try {
      final res = await _dio.get("/products/dto/$productId");
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      throw Exception("Failed to fetch product: $e");
    }
  }
}
