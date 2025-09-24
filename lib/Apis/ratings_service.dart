import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingsService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "${ApiConstants.prodUrl}/products",
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  // Get stored token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  /// ------------------------------
  /// 📌 Create Rating
  /// ------------------------------
  static Future<Response?> addRating({
    required int productId,
    required int orderItemId,
    required int rating,
    required String review,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Not authenticated");

      final response = await _dio.post(
        "/$productId/ratings",
        data: {"orderItemId": orderItemId, "rating": rating, "review": review},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return response;
    } on DioException catch (e) {
      print("❌ Dio error adding rating: ${e.response?.data}");
      return e.response;
    } catch (e) {
      print("❌ Unexpected error: $e");
      return null;
    }
  }

  /// ------------------------------
  /// 📌 List Ratings (Paginated)
  /// ------------------------------
  static Future<Response?> getRatings({
    required int productId,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get(
        "/$productId/ratings",
        queryParameters: {"page": page, "size": size},
      );
      return response;
    } on DioException catch (e) {
      print("❌ Dio error fetching ratings: ${e.response?.data}");
      return e.response;
    } catch (e) {
      print("❌ Unexpected error: $e");
      return null;
    }
  }

  /// ------------------------------
  /// 📌 Get My Rating (for a specific order item)
  /// ------------------------------
  static Future<Response?> getMyRating({
    required int productId,
    required int orderItemId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Not authenticated");

      final response = await _dio.get(
        "/$productId/ratings/mine",
        queryParameters: {"orderItemId": orderItemId},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response;
    } on DioException catch (e) {
      print("❌ Dio error fetching my rating: ${e.response?.data}");
      return e.response;
    } catch (e) {
      print("❌ Unexpected error: $e");
      return null;
    }
  }

  /// ------------------------------
  /// 📌 Update Rating
  /// ------------------------------
  static Future<Response?> updateRating({
    required int productId,
    required int ratingId,
    required int rating,
    required String review,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Not authenticated");

      final response = await _dio.put(
        "/$productId/ratings/$ratingId",
        data: {"rating": rating, "review": review},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return response;
    } on DioException catch (e) {
      print("❌ Dio error updating rating: ${e.response?.data}");
      return e.response;
    } catch (e) {
      print("❌ Unexpected error: $e");
      return null;
    }
  }

  /// ------------------------------
  /// 📌 Delete Rating
  /// ------------------------------
  static Future<Response?> deleteRating({
    required int productId,
    required int ratingId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Not authenticated");

      final response = await _dio.delete(
        "/$productId/ratings/$ratingId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response;
    } on DioException catch (e) {
      print("❌ Dio error deleting rating: ${e.response?.data}");
      return e.response;
    } catch (e) {
      print("❌ Unexpected error: $e");
      return null;
    }
  }

  /// ------------------------------
  /// 📌 Check Rating Eligibility
  /// ------------------------------
  static Future<Response?> checkEligibility({
    required int productId,
    required int orderId,
    required int orderItemId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Not authenticated");

      final response = await _dio.get(
        "/$productId/ratings/eligibility",
        queryParameters: {"orderId": orderId, "orderItemId": orderItemId},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response;
    } on DioException catch (e) {
      print("❌ Dio error checking eligibility: ${e.response?.data}");
      return e.response;
    } catch (e) {
      print("❌ Unexpected error: $e");
      return null;
    }
  }

  /// ------------------------------
  /// 📌 Get Ratings Summary
  /// ------------------------------
  static Future<Response?> getSummary(int productId) async {
    try {
      final response = await _dio.get("/$productId/ratings/summary");
      return response;
    } on DioException catch (e) {
      print("❌ Dio error fetching summary: ${e.response?.data}");
      return e.response;
    } catch (e) {
      print("❌ Unexpected error: $e");
      return null;
    }
  }
}
