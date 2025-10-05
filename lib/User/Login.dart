import 'package:carocart/Apis/google_auth.dart';
import 'package:carocart/Apis/user_api.dart';
import 'package:carocart/User/CategorySelection.dart';
import 'package:carocart/User/SignUp.dart';
import 'package:carocart/Utils/HexColor.dart';
import 'package:carocart/Utils/Messages.dart';
import 'package:carocart/Utils/ResetPassword.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool passwordvisible = true;
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final UserApi _userApi = UserApi();
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    width: 220,
                    height: 230,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/images/Logo.jpg',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 30),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 30, right: 30),
                  child: TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      hintText: 'Enter Your Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
                  child: TextField(
                    controller: _password,
                    obscureText: passwordvisible,
                    decoration: InputDecoration(
                      hintText: 'Enter Your Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      focusColor: Colors.green,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            passwordvisible = !passwordvisible;
                          });
                        },
                        child: Icon(
                          passwordvisible == false
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: GestureDetector(
                    onTap: () async {
                      setState(() => isLoading = true);
                      try {
                        final response = await _userApi.login(
                          _email.text.trim(),
                          _password.text.trim(),
                        );

                        if (response.statusCode == 200) {
                          final token = response.data;
                          // TODO: store token in SharedPreferences (so user stays logged in)
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString("auth_token", token);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppMessages.loginSuccess),
                            ),
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategorySelectionPage(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppMessages.loginFailed)),
                          );
                        }
                      } catch (e) {
                        String errorMessage = AppMessages.loginFailed;
                        print(e);
                        if (e is DioException) {
                          if (e.response?.statusCode == 401) {
                            errorMessage = AppMessages.incorrectCredentials;
                          } else if (e.type ==
                                  DioExceptionType.connectionTimeout ||
                              e.type == DioExceptionType.receiveTimeout) {
                            errorMessage = AppMessages.connectionTimedOut;
                          } else {
                            errorMessage = AppMessages.error;
                          }
                        }
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(errorMessage)));
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },

                    child: Padding(
                      padding: const EdgeInsets.only(left: 30.0, right: 30),
                      child: Container(
                        width: width,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF273E06),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 30.0,
                    right: 30,
                    top: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.black, fontSize: 15),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.blue, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    "or login with...",
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: GestureDetector(
                    onTap: () async {
                      setState(() => isLoading = true);

                      final success = await GoogleAuthHelper.loginWithGoogle();

                      setState(() => isLoading = false);

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppMessages.loginSuccess),
                          ),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategorySelectionPage(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppMessages.loginFailed),
                          ),
                        );
                      }
                    },

                    child: Padding(
                      padding: const EdgeInsets.only(left: 30.0, right: 30),
                      child: Container(
                        width: width,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: const Color.fromARGB(123, 0, 0, 0),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Image.asset(
                                'assets/images/google.png',
                                width: 30,
                                height: 30,
                              ),
                            ),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
