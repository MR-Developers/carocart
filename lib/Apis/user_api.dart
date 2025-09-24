import 'dart:io';

import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';

class UserApi {
  final Dio _dio;

  UserApi({String? token})
    : _dio = Dio(
        BaseOptions(
          baseUrl: "${ApiConstants.prodUrl}/users",
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: Headers.jsonContentType,
          headers: token != null ? {"Authorization": "Bearer $token"} : {},
        ),
      );

  // Signup
  Future<Response> signup(Map<String, dynamic> body) async {
    return _dio.post("/signup", data: body);
  }

  // Login
  Future<Response> login(String email, String password) async {
    return _dio.post("/login", data: {"email": email, "password": password});
  }

  // Update Profile
  Future<bool> updateProfile({required Map<String, dynamic> user}) async {
    try {
      final response = await _dio.put("/profile", data: user);

      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Dio error: ${e.response?.data ?? e.message}");
      return false;
    }
  }

  //Get Profile (with imageUrl)
  Future<Response> getProfile() async {
    return _dio.get("/profile");
  }

  //Update profile image URL
  Future<Response> updateProfileImageUrl(String imageUrl) async {
    return _dio.put("/profile/image-url", data: {"imageUrl": imageUrl});
  }

  //Change password
  Future<Response> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    return _dio.post(
      "/change-password",
      data: {"currentPassword": currentPassword, "newPassword": newPassword},
    );
  }

  //Forgot password
  Future<Response> forgotPassword(String email) async {
    return _dio.post("/forgot-password", data: {"email": email});
  }

  //Verify OTP
  Future<Response> verifyOtp(String email, String otp) async {
    return _dio.post("/verify-otp", data: {"email": email, "otp": otp});
  }

  //Reset password
  Future<Response> resetPassword(String email, String newPassword) async {
    return _dio.post(
      "/reset-password",
      data: {"email": email, "newPassword": newPassword},
    );
  }

  //ADMIN: Get all users
  Future<Response> getAllUsers() async {
    return _dio.get("/admin/users/all");
  }

  //ADMIN: Get user count
  Future<Response> getUserCount() async {
    return _dio.get("/admin/users/count");
  }

  //ADMIN: Update user
  Future<Response> updateUserByAdmin(int id, Map<String, dynamic> body) async {
    return _dio.put("/admin/users/$id", data: body);
  }

  //ADMIN: Delete user
  Future<Response> deleteUserByAdmin(int id) async {
    return _dio.delete("/admin/users/$id");
  }

  //Get user by ID
  Future<Response> getUserById(int id) async {
    return _dio.get("/$id");
  }

  //Get current user (for Feign)
  Future<Response> getCurrentUser() async {
    return _dio.get("/me");
  }
}
