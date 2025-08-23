import 'package:carocart/Apis/user_api.dart';
import 'package:carocart/User/Login.dart';
import 'package:carocart/Utils/HexColor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int currentStep = 1;
  bool passwordVisible = true;
  bool isLoading = false;

  // Step 1 controllers
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _dob = TextEditingController();

  // Step 2 controllers
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  final UserApi _userApi = UserApi(); // API instance

  Future<void> _handleSignup() async {
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await _userApi.signup({
        "firstName": _firstName.text.trim(),
        "lastName": _lastName.text.trim(),
        "email": _email.text.trim(),
        "password": _password.text.trim(),
        "phoneNumber": _phone.text.trim(),
        "dob": _dob.text.trim(), // must be in YYYY-MM-DD format
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Signup successful!")));

        // Navigate to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup failed: ${response.data}")),
        );
      }
    } on DioException catch (e) {
      print(e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.response?.data ?? e.message}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: Column(
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

                      /// Step 1 → Basic Info
                      if (currentStep == 1) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 30),
                            child: Text(
                              'Enter Your Details',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        _buildTextField(_firstName, "First Name", Icons.person),
                        _buildTextField(
                          _lastName,
                          "Last Name",
                          Icons.person_outline,
                        ),
                        _buildTextField(_phone, "Phone Number", Icons.phone),
                        _buildTextField(
                          _dob,
                          "Date of Birth (YYYY-MM-DD)",
                          Icons.calendar_today,
                        ),

                        _buildNextButton(width, "Next", () {
                          setState(() => currentStep = 2);
                        }),
                      ],

                      /// Step 2 → Credentials
                      if (currentStep == 2) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 30),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        _buildTextField(_email, "Email", Icons.email_outlined),
                        _buildPasswordField(_password, "Enter Your Password"),
                        _buildPasswordField(
                          _confirmPassword,
                          "Re-enter Your Password",
                        ),
                        _buildNextButton(width, "Sign Up", _handleSignup),
                        TextButton(
                          onPressed: () {
                            setState(() => currentStep = 1);
                          },
                          child: const Text("← Back"),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account?"),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              child: const Text("Login"),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Reusable textfield builder
  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
      ),
    );
  }

  /// Password field with toggle
  Widget _buildPasswordField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: passwordVisible,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() => passwordVisible = !passwordVisible);
            },
            child: Icon(
              passwordVisible ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable button
  Widget _buildNextButton(double width, String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: 50,
          decoration: BoxDecoration(
            color: HexColor("#09B763"),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
