import 'package:carocart/Root/RoleSelection.dart';
import 'package:carocart/User/Login.dart';
import 'package:carocart/User/UserHome.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaroCart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const FlashScreen(),
    );
  }
}

class FlashScreen extends StatefulWidget {
  const FlashScreen({super.key});

  @override
  State<FlashScreen> createState() => _FlashScreenState();
}

class _FlashScreenState extends State<FlashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");
    print("Token: $token");
    await Future.delayed(const Duration(seconds: 3));
    if (token != null && token.isNotEmpty) {
      if (!JwtDecoder.isExpired(token)) {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        String role = decodedToken["role"] ?? "";
        if (role == "USER") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserHome()),
          );
        } else {
          prefs.remove("auth_token");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        prefs.remove("auth_token");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      // No token → go to role selection
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Image.asset('assets/images/Logo.jpg', height: 200)),
    );
  }
}
