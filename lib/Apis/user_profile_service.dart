import 'package:carocart/Apis/constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "${ApiConstants.prodUrl}/users",
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Retrieve JWT token from storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  /// Update profile details
  static Future<bool> updateProfile(Map<String, dynamic> user) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print("❌ No token found in SharedPreferences");
        return false;
      }

      final response = await _dio.put(
        "/profile",
        data: user,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        print("✅ Profile updated: ${response.data}");
        return true;
      } else {
        print("❌ Failed to update profile: ${response.statusMessage}");
        return false;
      }
    } on DioException catch (e) {
      print("❌ Dio error while updating profile");
      _logDioError(e);
      return false;
    } catch (e) {
      print("Unexpected error while updating profile: $e");
      return false;
    }
  }

  static Future<bool> updateProfileImage(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print("❌ No token found in SharedPreferences");
        return false;
      }

      final response = await _dio.put(
        "/profile/image-url",
        data: data,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        print("✅ Profile updated: ${response.data}");
        return true;
      } else {
        print("❌ Failed to update profile: ${response.statusMessage}");
        return false;
      }
    } on DioException catch (e) {
      print("❌ Dio error while updating profile");
      _logDioError(e);
      return false;
    } catch (e) {
      print("Unexpected error while updating profile: $e");
      return false;
    }
  }

  static Future<bool> changePassword(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print("❌ No token found in SharedPreferences");
        return false;
      }

      final response = await _dio.post(
        "/change-password",
        data: data,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        print("✅ Profile updated: ${response.data}");
        return true;
      } else {
        print("❌ Failed to update profile: ${response.statusMessage}");
        return false;
      }
    } on DioException catch (e) {
      print("❌ Dio error while updating profile");
      _logDioError(e);
      return false;
    } catch (e) {
      print("Unexpected error while updating profile: $e");
      return false;
    }
  }

  /// Fetch profile details
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final token = await _getToken();
      if (token == null) {
        print("❌ No token found in SharedPreferences");
        return null;
      }

      final response = await _dio.get(
        "/profile",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        print("✅ Profile fetched: ${response.data}");
        return Map<String, dynamic>.from(response.data);
      } else {
        print("❌ Failed to fetch profile: ${response.statusMessage}");
        return null;
      }
    } on DioException catch (e) {
      print("❌ Dio error while fetching profile");
      _logDioError(e);
      return null;
    } catch (e) {
      print("Unexpected error while fetching profile: $e");
      return null;
    }
  }

  /// Common error logger
  static void _logDioError(DioException e) {
    print("URL: ${e.requestOptions.uri}");
    print("Headers: ${e.requestOptions.headers}");
    print("Body: ${e.requestOptions.data}");
    print("Status: ${e.response?.statusCode}");
    print("Response: ${e.response?.data}");
  }
}
