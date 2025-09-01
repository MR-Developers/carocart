import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "${ApiConstants.baseUrl}:8080/cart",
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

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
      return cart;
    } catch (e) {
      print("❌ Error fetching cart: $e");
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
}
