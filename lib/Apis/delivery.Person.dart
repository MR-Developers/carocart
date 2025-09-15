import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'constants.dart';

/// ==============================
/// Helper to show error popup
/// ==============================
void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(
        "Error",
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

/// ==============================
/// ApiClient for Public & Private APIs
/// ==============================
class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "${ApiConstants.baseUrl}:8080",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  );

  /// Private Dio instance for authenticated requests
  static Dio getPrivateDio(String? token) {
    return Dio(
      BaseOptions(
        baseUrl: "${ApiConstants.baseUrl}:8080",
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      ),
    );
  }
}

/// ==============================
/// AUTH & USER MANAGEMENT
/// ==============================
Future<Map<String, dynamic>> deliveryRegister(
  BuildContext context,
  Map<String, dynamic> data,
) async {
  try {
    final response = await ApiClient.dio.post(
      "/deliveryboys/register",
      data: data,
    );

    print("RAW RESPONSE: ${response.data}");

    // ✅ FIXED: Safely handle response data
    if (response.data != null) {
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else {
        // If response.data is not a Map, wrap it
        return {"data": response.data};
      }
    } else {
      return {};
    }
  } on DioException catch (e) {
    _handleApiError(context, e, "Delivery Register Error");
    return {};
  } catch (e) {
    // ✅ ADDED: Catch any other unexpected errors
    print("Unexpected error in deliveryRegister: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
    }
    return {};
  }
}

Future<Map<String, dynamic>> deliveryLogin(
  BuildContext context,
  Map<String, dynamic> loginData,
) async {
  try {
    final response = await ApiClient.dio.post(
      "/deliveryboys/login",
      data: loginData,
    );
    return response.data;
  } on DioException catch (e) {
    _handleApiError(context, e, "Delivery Login Error");
    return {};
  }
}

Future<Map<String, dynamic>> deliveryBoyRequestOTP(
  BuildContext context,
  String phoneOrEmail,
) async {
  try {
    final response = await ApiClient.dio.post(
      "/deliveryboys/forgot-password",
      data: {"phoneOrEmail": phoneOrEmail},
    );
    return response.data;
  } on DioException catch (e) {
    _handleApiError(context, e, "Request OTP Error");
    return {};
  }
}

Future<Map<String, dynamic>> deliveryBoyVerifyOTP(
  BuildContext context,
  String phoneOrEmail,
  String otp,
) async {
  try {
    final response = await ApiClient.dio.post(
      "/deliveryboys/verify-otp",
      data: {"phoneOrEmail": phoneOrEmail, "otp": otp},
    );
    return response.data;
  } on DioException catch (e) {
    _handleApiError(context, e, "Verify OTP Error");
    return {};
  }
}

Future<Map<String, dynamic>> deliveryBoyResetPassword(
  BuildContext context,
  String phoneOrEmail,
  String password,
) async {
  try {
    final response = await ApiClient.dio.post(
      "/deliveryboys/reset-password",
      data: {"phoneOrEmail": phoneOrEmail, "password": password},
    );
    return response.data;
  } on DioException catch (e) {
    _handleApiError(context, e, "Reset Password Error");
    return {};
  }
}

/// ==============================
/// FILE UPLOAD
/// ==============================
Future<Map<String, dynamic>> uploadFile({
  required BuildContext context,
  required String filePath,
  String? folder,
}) async {
  try {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      if (folder != null) 'folder': folder,
    });

    final response = await ApiClient.dio.post(
      "/api/upload",
      data: formData,
      options: Options(headers: {"Content-Type": "multipart/form-data"}),
    );

    print("Upload API Raw Response: ${response.data}");
    print("Response Type: ${response.data.runtimeType}");

    // ✅ If backend returned a String, wrap it inside a Map
    if (response.data is String) {
      return {"data": response.data};
    }

    // ✅ If backend returned Map, return as is
    if (response.data is Map<String, dynamic>) {
      return response.data;
    }

    // ✅ Fallback case: Convert to string and wrap in a Map
    return {"data": response.data.toString()};
  } on DioException catch (e) {
    print("File Upload Dio Error: ${e.message}");
    print("Error Response Data: ${e.response?.data}");
    _handleApiError(context, e, "File Upload Error");
    return {};
  } catch (e) {
    print("File Upload Unknown Error: $e");
    return {};
  }
}

/// ==============================
/// PROFILE (AUTHENTICATED)
/// ==============================
Future<Map<String, dynamic>> getDeliveryProfile(
  BuildContext context,
  String token,
) async {
  try {
    final dio = ApiClient.getPrivateDio(token);
    final response = await dio.get("/deliveryboys/me");
    return response.data;
  } on DioException catch (e) {
    _handleApiError(context, e, "Get Profile Error");
    return {};
  }
}

Future<Map<String, dynamic>> updateDeliveryProfile(
  BuildContext context,
  String token,
  Map<String, dynamic> payload,
) async {
  try {
    final dio = ApiClient.getPrivateDio(token);
    final response = await dio.put("/deliveryboys/me", data: payload);
    return response.data;
  } on DioException catch (e) {
    _handleApiError(context, e, "Update Profile Error");
    return {};
  }
}

/// ==============================
/// ORDER APIs
/// ==============================
Future<List<Map<String, dynamic>>> getAssignedOrders(
  BuildContext context,
  String token,
) async {
  try {
    final dio = ApiClient.getPrivateDio(token);
    final response = await dio.get("/orders/my-assigned");

    if (response.statusCode == 200) {
      final List data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to load assigned orders: ${response.statusCode}");
    }
  } on DioException catch (e) {
    _handleApiError(context, e, "Get Assigned Orders Error");
    return [];
  }
}

Future<List<Map<String, dynamic>>> getOrderHistory(
  BuildContext context,
  String token,
) async {
  return getAssignedOrders(context, token);
}

Future<Map<String, dynamic>> updateOrderStatus(
  BuildContext context,
  String token,
  int orderId,
  String status,
) async {
  try {
    final dio = ApiClient.getPrivateDio(token);
    final response = await dio.put(
      "/orders/delivery/update-status/$orderId",
      queryParameters: {"status": status},
    );
    return response.data;
  } on DioException catch (e) {
    _handleApiError(context, e, "Update Order Status Error");
    return {};
  }
}

Future<List<Map<String, dynamic>>> getAvailableOrdersForAssignment(
  BuildContext context,
  String token,
) async {
  try {
    final dio = ApiClient.getPrivateDio(token);
    final response = await dio.get("/orders/delivery/available");

    if (response.statusCode == 200) {
      final List data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        "Failed to load available orders: ${response.statusCode}",
      );
    }
  } on DioException catch (e) {
    _handleApiError(context, e, "Get Available Orders Error");
    return [];
  }
}

Future<Map<String, dynamic>> selfAssignOrder(
  BuildContext context,
  String token,
  int orderId,
) async {
  try {
    final dio = ApiClient.getPrivateDio(token);
    final response = await dio.put("/orders/delivery/assign/$orderId");
    return response.data;
  } on DioException catch (e) {
    _handleApiError(context, e, "Self Assign Order Error");
    return {};
  }
}

Future<Map<String, dynamic>> getDeliveryBoyLocationByOrderId(
  BuildContext context,
  String token,
  int orderId,
) async {
  try {
    final dio = ApiClient.getPrivateDio(token);
    final response = await dio.get("/orders/$orderId/deliveryboy-location");
    return response.data;
  } on DioException catch (e) {
    _handleApiError(context, e, "Get Delivery Boy Location Error");
    return {};
  }
}

/// ==============================
/// EARNINGS APIs
/// ==============================
Future<Map<String, dynamic>> getDeliveryEarnings(
  BuildContext context,
  String token, {
  String? from,
  String? to,
}) async {
  try {
    final dio = ApiClient.getPrivateDio(token);
    final response = await dio.get(
      "/delivery/earnings",
      queryParameters: {
        if (from != null) "from": from,
        if (to != null) "to": to,
      },
    );
    return {"data": response.data};
  } on DioException catch (e) {
    _handleApiError(context, e, "Get Earnings Error");
    return {};
  }
}

Future<Map<String, dynamic>> getDeliveryEarningsSummary(
  BuildContext context,
  String token,
  String period,
) async {
  try {
    final dio = ApiClient.getPrivateDio(token);
    final response = await dio.get(
      "/delivery/earnings/summary",
      queryParameters: {"period": period},
    );
    return response.data;
  } on DioException catch (e) {
    _handleApiError(context, e, "Get Earnings Summary Error");
    return {};
  }
}

/// ==============================
/// FIXED: Private Helper - API Error Handler
/// ==============================
void _handleApiError(BuildContext context, DioException e, String prefix) {
  try {
    String errorMessage = "Unknown error occurred";

    // ✅ FIXED: Safely extract error message from response
    if (e.response?.data != null) {
      final responseData = e.response!.data;

      // Check if response data is a Map (JSON object)
      if (responseData is Map<String, dynamic>) {
        errorMessage =
            responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            responseData['details']?.toString() ??
            e.response?.statusMessage ??
            e.message ??
            "Unknown error occurred";
      }
      // Check if response data is a String
      else if (responseData is String) {
        errorMessage = responseData;
      }
      // Check if response data is a List (less common but possible)
      else if (responseData is List && responseData.isNotEmpty) {
        // If it's a list of maps, try to get message from first item
        if (responseData.first is Map<String, dynamic>) {
          final firstItem = responseData.first as Map<String, dynamic>;
          errorMessage =
              firstItem['message']?.toString() ??
              firstItem['error']?.toString() ??
              responseData.toString();
        } else {
          errorMessage = responseData.toString();
        }
      }
      // Fallback for other data types
      else {
        errorMessage = responseData.toString();
      }
    }
    // No response data, use DioException properties
    else {
      errorMessage =
          e.response?.statusMessage ?? e.message ?? "Network error occurred";
    }

    // ✅ Print detailed error for debugging
    print("⚠️ $prefix");
    print("Status Code: ${e.response?.statusCode}");
    print("Response Data Type: ${e.response?.data.runtimeType}");
    print("Response Data: ${e.response?.data}");
    print("Error Message: $errorMessage");
    print("Stack Trace: ${e.stackTrace}");

    // ✅ Show user-friendly error message
    if (context.mounted) {
      showErrorDialog(context, "$prefix: $errorMessage");
    }
  } catch (handleError) {
    // ✅ Ultimate fallback - handle errors in error handler
    print("❌ Error in _handleApiError: $handleError");
    print("❌ Original API ERROR [$prefix]: ${e.toString()}");

    if (context.mounted) {
      showErrorDialog(
        context,
        "An unexpected error occurred. Please try again.",
      );
    }
  }
}
