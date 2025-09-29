import 'dart:convert';
import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorProductsApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.prodUrl, // Replace with your base URL
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  static Future<List<Map<String, dynamic>>> getAllCategories() async {
    final res = await _dio.get("/categories");
    return List<Map<String, dynamic>>.from(res.data);
  }

  static Future<List<Map<String, dynamic>>> getSubCategoriesByCategoryId(
    String catId,
  ) async {
    final res = await _dio.get("/categories/$catId/subcategories");
    return List<Map<String, dynamic>>.from(res.data);
  }

  static Future<List<Map<String, dynamic>>> getMyProducts(String token) async {
    final res = await _dio.get(
      "/products/vendor/my-products",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
    return List<Map<String, dynamic>>.from(res.data);
  }

  static Future<void> deleteProduct(String productId, String token) async {
    await _dio.delete(
      "/products/$productId",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
  }

  static Future<Map<String, dynamic>> getCurrentVendor(String token) async {
    try {
      final response = await _dio.get(
        "/vendors/me",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to fetch vendor profile');
      }
    } catch (e) {
      throw Exception('Error fetching vendor: $e');
    }
  }

  // ✅ Add Product function
  static Future<Map<String, dynamic>> addProduct(
    Map<String, dynamic> productPayload,
    String token,
  ) async {
    try {
      final response = await _dio.post(
        "/products",
        data: productPayload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception("Failed to add product");
      }
    } catch (e) {
      throw Exception("Error adding product: $e");
    }
  }
}
