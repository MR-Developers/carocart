import 'package:carocart/Root/RoleSelection.dart';
import 'package:carocart/User/CategorySelection.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: "/flash",
      routes: {
        "/flash": (context) => const FlashScreen(),
        "/": (context) => const CategorySelectionPage(),
        "/login": (context) => const LoginPage(),
        "/role": (context) => const RoleSelectionScreen(),
        "/userhome": (context) => const UserHome(),
        // "/cart": (context) => const CartScreen(),
        // "/vendors/login": (context) => const SellerLoginScreen(),
        // "/account": (context) => const ProfileScreen(),
      },
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
          Navigator.pushReplacementNamed(context, "/");
        } else {
          prefs.remove("auth_token");
          Navigator.pushReplacementNamed(context, "/login");
        }
      } else {
        prefs.remove("auth_token");
        Navigator.pushReplacementNamed(context, "/login");
      }
    } else {
      Navigator.pushReplacementNamed(context, "/role");
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
