import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.prodUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  static Map<String, String> _authHeaders(String token) {
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  // ========== Get Earnings ==========
  static Future<int> getMyVendorEarningsByPeriod(String period) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final response = await _dio.get(
        "/vendor/earnings/$period",
        options: Options(headers: _authHeaders(token)),
      );

      final data = response.data;
      if (data is int) return data;
      if (data is Map) {
        for (final key in [
          "amount",
          "totalAmount",
          "total",
          "sum",
          "earnings",
          "value",
        ]) {
          if (data[key] != null) {
            return int.tryParse(data[key].toString()) ?? 0;
          }
        }
      }
      return 0;
    } catch (e) {
      throw Exception("Failed to fetch vendor earnings ($period): $e");
    }
  }

  // ========== Get Product Count ==========
  static Future<int> getMyProductsCount({bool availableOnly = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final url =
          "/products/vendor/my-products/count${availableOnly ? "?availableOnly=true" : ""}";

      final response = await _dio.get(
        url,
        options: Options(headers: _authHeaders(token)),
      );

      if (response.data is int) return response.data;
      return int.tryParse(response.data.toString()) ?? 0;
    } catch (e) {
      throw Exception("Failed to fetch product count: $e");
    }
  }
}
