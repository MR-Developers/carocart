// lib/Helpers/google_auth_helper.dart

import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Apis/constants.dart';

class GoogleAuthHelper {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _initialized = false;
  static Future<void> _ensureInitialized({
    String? clientId,
    String? serverClientId,
  }) async {
    if (_initialized) return;
    try {
      await _googleSignIn.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );
      _initialized = true;
    } catch (e) {
      print('GoogleSignIn initialization error: $e');
      rethrow;
    }
  }

  static Future<bool> signInWithGoogle({
    String? clientId,
    String? serverClientId,
  }) async {
    try {
      await _ensureInitialized(
        clientId: clientId,
        serverClientId: serverClientId,
      );
      GoogleSignInAccount account;
      if (_googleSignIn.supportsAuthenticate()) {
        account = await _googleSignIn.authenticate(
          scopeHint: const ['email', 'profile'],
        );
      } else {
        // fallback: try lightweight (may return a previously signed-in user)
        final maybe = await _googleSignIn.attemptLightweightAuthentication();
        if (maybe == null) {
          throw Exception(
            'Interactive authentication not supported on this platform. On web, use web.renderButton() or the web-specific flow.',
          );
        }
        account = maybe;
      }

      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        print('Google idToken is null — cannot proceed.');
        return false;
      }
      final response = await Dio().post(
        '${ApiConstants.baseUrl}/oauth2/authorization/google',
        data: {'idToken': idToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        String token;
        final data = response.data;
        if (data is String) {
          token = data;
        } else if (data is Map && data['token'] != null) {
          token = data['token'] as String;
        } else {
          token = data.toString();
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return true;
      } else {
        print(
          'Backend error during Google login: ${response.statusCode} ${response.statusMessage}',
        );
        return false;
      }
    } on GoogleSignInException catch (e) {
      print(
        'GoogleSignInException: code=${e.code} description=${e.description} details=${e.details}',
      );
      return false;
    } catch (e) {
      print('Unexpected Google sign-in error: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
