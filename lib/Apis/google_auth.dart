import 'package:carocart/Apis/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleAuthHelper {
  static const backendUrl =
      "${ApiConstants.prodUrl}/oauth2/authorization/google";

  static Future<bool> loginWithGoogle() async {
    final Uri url = Uri.parse(backendUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    } else {
      return true;
    }
  }

  /// Save JWT returned from deep link
  static Future<void> handleOAuthRedirect(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);

    final payload = Jwt.parseJwt(token);
    await prefs.setString("user", payload.toString());
    print("Google login successful. User info: $payload");
  }

  /// Sign out
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("user");
    print("Signed out");
  }
}
