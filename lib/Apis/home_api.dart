// Dio client setup
import 'package:dio/dio.dart';
import 'package:carocart/Apis/constants.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.prodUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  );
}

// API services
Future<List<Map<String, dynamic>>> getNearbyVendors({
  required String type,
  required double lat,
  required double lng,
  int radius = 10,
}) async {
  try {
    final response = await ApiClient.dio.get(
      "/vendors/nearby",
      queryParameters: {
        "type": type,
        "lat": lat,
        "lng": lng,
        "radiusKm": radius,
      },
    );

    if (response.statusCode == 200) {
      final List data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to load vendors: ${response.statusCode}");
    }
  } on DioException catch (e) {
    throw Exception("Dio error: ${e.message}");
  }
}

Future<List<Map<String, dynamic>>> getSubCategoriesByVendorIds(
  List<int> vendorIds,
) async {
  try {
    final queryParams = vendorIds.map((id) => "vendorIds=$id").join("&");

    final response = await ApiClient.dio.get(
      "/categories/vendor-subcategories?$queryParams",
    );

    if (response.statusCode == 200) {
      final List data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to load subcategories: ${response.statusCode}");
    }
  } on DioException catch (e) {
    throw Exception("Dio error: ${e.message}");
  }
}

Future<List<Map<String, dynamic>>> getNearbyVendorsBySubCategory({
  required String subCategoryId,
  required double lat,
  required double lng,
  int radius = 10,
}) async {
  try {
    final response = await ApiClient.dio.get(
      "/categories/subcategory/$subCategoryId/vendors/nearby",
      queryParameters: {"lat": lat, "lng": lng, "radiusKm": radius},
    );

    if (response.statusCode == 200) {
      final List data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        "Failed to load vendors by subcategory: ${response.statusCode}",
      );
    }
  } on DioException catch (e) {
    throw Exception("Dio error: ${e.message}");
  }
}

// Get grouped products by vendorId
Future<Map<String, dynamic>> getVendorProductsGrouped(int vendorId) async {
  try {
    final response = await ApiClient.dio.get(
      "/products/vendor/$vendorId/grouped",
    );

    if (response.statusCode == 200) {
      // backend returns JSON object with categories → subcats → products
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception(
        "Failed to load grouped products: ${response.statusCode}",
      );
    }
  } on DioException catch (e) {
    throw Exception("Dio error: ${e.message}");
  }
}

// Get vendor by ID
Future<Map<String, dynamic>> getVendorById(int vendorId) async {
  try {
    final response = await ApiClient.dio.get("/vendors/$vendorId");

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception("Failed to load vendor: ${response.statusCode}");
    }
  } on DioException catch (e) {
    throw Exception("Dio error: ${e.message}");
  }
}
