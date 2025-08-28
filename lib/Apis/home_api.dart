// Dio client setup
import 'package:dio/dio.dart';
import 'package:carocart/Apis/constants.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "${ApiConstants.baseUrl}:8080",
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
