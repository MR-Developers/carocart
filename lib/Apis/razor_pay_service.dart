import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RazorpayService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "${ApiConstants.baseUrl}:8080/api/payments",
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  /// 🔹 Step 1: Create Razorpay order from backend
  static Future<Response?> createOrder({
    required int totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Not authenticated");

      final response = await _dio.post(
        "/prepare-razorpay-order",
        data: {"amount": totalAmount, "items": items},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return response;
    } on DioException catch (e) {
      print("❌ Dio error creating Razorpay order: ${e.response?.data}");
      return e.response;
    } catch (e) {
      print("❌ Unexpected error: $e");
      return null;
    }
  }

  /// 🔹 Step 2: Verify Razorpay payment
  static Future<Response?> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int amount,
    required int userId,
    required int addressId,
    required String shippingAddress,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Not authenticated");

      final response = await _dio.post(
        "/verify-and-create-order",
        data: {
          "razorpayOrderId": razorpayOrderId,
          "razorpayPaymentId": razorpayPaymentId,
          "razorpaySignature": razorpaySignature,
          "amount": amount,
          "userId": userId,
          "addressId": addressId,
          "shippingAddress": shippingAddress,
          "cartItems": items,
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
      print("❌ Dio error verifying Razorpay payment: ${e.response?.data}");
      return e.response;
    } catch (e) {
      print("❌ Unexpected error: $e");
      return null;
    }
  }
}
