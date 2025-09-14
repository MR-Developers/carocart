// lib/services/address_service.dart
import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressService {
  // ✅ Use only the host + port as baseUrl
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "${ApiConstants.baseUrl}:8080", // host + port only
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Retrieve token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  // Helper to show SnackBar for errors
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // -------------------- GET ALL ADDRESSES --------------------
  static Future<List<Map<String, dynamic>>> getMyAddresses(
    BuildContext context,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showError(context, "User not authenticated");
        return [];
      }

      final response = await _dio.get(
        "/api/addresses/me",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      final List data = response.data;
      return List<Map<String, dynamic>>.from(data);
    } on DioException catch (e) {
      _showError(context, "Failed to fetch addresses}");
      return [];
    } catch (e) {
      _showError(context, "Failed to fetch addresses");
      return [];
    }
  }

  // -------------------- CREATE ADDRESS --------------------
  static Future<Map<String, dynamic>?> createAddress(
    BuildContext context,
    Map<String, dynamic> addressData,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showError(context, "User not authenticated");
        return null;
      }

      final response = await _dio.post(
        "/api/addresses",
        data: addressData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      _showError(context, "Failed to create address");
      return null;
    } catch (e) {
      _showError(context, "Failed to create address");
      return null;
    }
  }

  // -------------------- UPDATE ADDRESS --------------------
  static Future<Map<String, dynamic>?> updateAddress(
    BuildContext context,
    int id,
    Map<String, dynamic> addressData,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showError(context, "User not authenticated");
        return null;
      }

      final response = await _dio.put(
        "/api/addresses/$id",
        data: addressData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      _showError(context, "Failed to update address");
      return null;
    } catch (e) {
      _showError(context, "Failed to update address");
      return null;
    }
  }

  // -------------------- DELETE ADDRESS --------------------
  static Future<bool> deleteAddress(BuildContext context, int id) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showError(context, "User not authenticated");
        return false;
      }

      final response = await _dio.delete(
        "/api/addresses/$id",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      _showError(context, "Failed to delete address");
      return false;
    } catch (e) {
      _showError(context, "Failed to delete address");
      return false;
    }
  }

  // -------------------- GET ADDRESS BY ID --------------------
  static Future<Map<String, dynamic>?> getAddressById(
    BuildContext context,
    String id,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showError(context, "User not authenticated");
        return null;
      }

      final response = await _dio.get(
        "/api/addresses/$id",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      _showError(context, "Failed to fetch address");
      return null;
    } catch (e) {
      _showError(context, "Failed to fetch address");
      return null;
    }
  }

  // -------------------- SET DEFAULT ADDRESS --------------------
  static Future<bool> setDefaultAddress(BuildContext context, int id) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _showError(context, "User not authenticated");
        return false;
      }

      final response = await _dio.patch(
        "/api/addresses/$id/default",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      _showError(context, "Failed to set default address");
      return false;
    } catch (e) {
      _showError(context, "Failed to set default address");
      return false;
    }
  }
}
