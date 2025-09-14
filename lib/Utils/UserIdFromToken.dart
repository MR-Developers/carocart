import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("auth_token");
}

/// Decode a JWT and return only the userId
Future<String?> parseJwtUserId() async {
  final token = await _getToken();
  if (token == null || token.isEmpty) return null;

  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('Invalid JWT token');
  }

  final payload = parts[1];

  // Pad base64 if needed
  String normalized = base64Url.normalize(payload);

  // Decode base64 → JSON string
  final payloadString = utf8.decode(base64Url.decode(normalized));

  // Parse JSON → Map
  final payloadMap = json.decode(payloadString);

  if (payloadMap is! Map<String, dynamic>) {
    throw Exception('Invalid JWT payload');
  }

  // Adjust the key name based on your backend (likely "userId" not "user Id")
  return payloadMap["userId"]?.toString();
}
