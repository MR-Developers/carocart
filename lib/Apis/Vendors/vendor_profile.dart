import 'dart:io';
import 'package:dio/dio.dart';
import 'package:carocart/Apis/constants.dart';

class VendorProfileApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.prodUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  /// Update vendor profile
  static Future<Map<String, dynamic>> updateVendorProfile(
    String token,
    Map<String, dynamic> updatedVendor,
  ) async {
    try {
      final response = await _dio.put(
        "/vendors/me",
        data: updatedVendor,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Make sure the data is Map
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else if (response.data is String) {
          // Some APIs return a plain string
          return {"message": response.data};
        } else {
          return {"message": "Profile updated"};
        }
      } else {
        throw Exception(
          "Failed to update vendor profile: ${response.statusCode} ${response.data}",
        );
      }
    } catch (e) {
      if (e is DioException) {
        print("Error status: ${e.response?.statusCode}");
        print("Response data: ${e.response?.data}");
      }
      throw Exception("Error updating profile: $e");
    }
  }

  /// Upload vendor profile image
  static Future<Map<String, dynamic>> uploadVendorProfileImage(
    String token,
    File file,
  ) async {
    try {
      final fileName = file.path.split("/").last;
      final formData = FormData.fromMap({
        "profileImage": await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        "/vendors/me/profile-image",
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception("Failed to upload profile image");
      }
    } catch (e) {
      throw Exception("Error uploading profile image: $e");
    }
  }

  /// Get vendor profile image
  static Future<List<int>> getVendorProfileImage(String token) async {
    try {
      final response = await _dio.get(
        "/vendors/profile/image",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        return List<int>.from(response.data);
      } else {
        throw Exception("Failed to fetch vendor profile image");
      }
    } catch (e) {
      throw Exception("Error fetching profile image: $e");
    }
  }
}
