import 'package:dio/dio.dart';

class HomeApi {
  static const String baseUrl = "http://10.0.2.2:8081";

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  );

  /// Get nearby vendors (Food / Grocery)
  static Future<List<dynamic>> getNearbyVendors({
    required String type,
    required double lat,
    required double lng,
    int radius = 10,
  }) async {
    try {
      final response = await _dio.get(
        "/vendors/nearby",
        queryParameters: {
          "type": type,
          "lat": lat,
          "lng": lng,
          "radius": radius,
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      } else {
        throw Exception("Failed to load vendors");
      }
    } on DioException catch (e) {
      throw Exception("API Error: ${e.message}");
    }
  }

  /// Get subcategories by vendor IDs
  static Future<List<dynamic>> getSubCategoriesByVendorIds(
    List<String> vendorIds,
  ) async {
    try {
      final response = await _dio.post(
        "/categories/subcategories",
        data: {"vendorIds": vendorIds},
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      } else {
        throw Exception("Failed to load subcategories");
      }
    } on DioException catch (e) {
      throw Exception("API Error: ${e.message}");
    }
  }
}
