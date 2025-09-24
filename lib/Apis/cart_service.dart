import 'package:carocart/Apis/constants.dart';
import 'package:carocart/Utils/Messages.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "${ApiConstants.prodUrl}/cart",
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("auth_token");
  }

  static final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);
  static Future<int?> addToCart(int productId, int quantity) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print("No token found in SharedPreferences");
        return null;
      }

      final response = await _dio.post(
        "/add",
        data: {"productId": productId, "quantity": quantity},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      print("✅ Added to cart: ${response.data}");
      return response.statusCode;
    } on DioException catch (e) {
      print("❌ Dio error while adding to cart");
      print("URL: ${e.requestOptions.uri}");
      print("Headers: ${e.requestOptions.headers}");
      print("Body: ${e.requestOptions.data}");
      print("Status: ${e.response?.statusCode}");
      print("Response: ${e.response?.data}");
      return null;
    } catch (e) {
      print("Unexpected error: $e");
      return null;
    }
  }

  static Future<Map<int, int>> getCart() async {
    try {
      final token = await _getToken();
      if (token == null) return {};

      final response = await _dio.get(
        "/get",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );
      final List data = response.data;
      final Map<int, int> cart = {};
      for (final item in data) {
        cart[item["productId"]] = item["quantity"];
      }
      cartCountNotifier.value = cart.length;
      return cart;
    } catch (e) {
      return {};
    }
  }

  static Future<void> updateCartItem(int productId, int quantity) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final res = await _dio.put(
      "/update",
      data: {"productId": productId, "quantity": quantity},
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception("Failed to update cart: ${res.statusMessage}");
    }
  }

  static Future<void> clearCart() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Not authenticated");

      final response = await _dio.delete(
        "/clear",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // reset cart count to 0 and notify listeners
        cartCountNotifier.value = 0;
        print("✅ Cart cleared successfully");
      } else {
        throw Exception("Failed to clear cart: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      var errorMessage = AppMessages.error;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = AppMessages.connectionTimedOut;
      }
      rethrow;
    } catch (e) {
      print("Unexpected error while clearing cart: $e");
      rethrow;
    }
  }
}
