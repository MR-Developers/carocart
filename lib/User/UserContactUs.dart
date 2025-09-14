import 'package:carocart/Apis/contact_us_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({Key? key}) : super(key: key);

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String topic = "";
  bool sending = false;

  final List<String> topics = [
    "Order Issue",
    "Payment Support",
    "Product Inquiry",
    "Account Help",
    "Other",
  ];

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (topic.isEmpty) {
      Fluttertoast.showToast(msg: "Please select a topic");
      return;
    }

    setState(() => sending = true);
    try {
      final response = await ContactUsService.sendContactMessage(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        topic: topic,
        message: _messageController.text.trim(),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Message sent successfully");
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
        setState(() => topic = "");
      } else {
        Fluttertoast.showToast(
          msg:
              "Failed to send message: ${response.data ?? response.statusCode}",
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
      rethrow;
    } finally {
      setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // Curved gradient header
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        "Need Help?",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "We’d love to hear from you. Our team is here to help.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      if (w > 320)
                        SvgPicture.asset(
                          "assets/images/customer_support.svg",
                          height: 88,
                          semanticsLabel: "Customer support",
                        ),
                    ],
                  ),
                ),
              ),

              // Floating-ish card
              Transform.translate(
                offset: const Offset(0, -60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Contact details - improved layout
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            _ContactInfo(
                              icon: Icons.email_outlined,
                              label: "CaroCartTeam@gmail.com",
                            ),
                            _ContactInfo(
                              icon: Icons.phone,
                              label: "+91 7569620730",
                            ),
                            _ContactInfo(
                              icon: Icons.location_on_outlined,
                              label: "Hyderabad",
                            ),
                          ],
                        ),
                        const Divider(height: 24, thickness: 0.8),
                        const SizedBox(height: 8),

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: inputDecoration(
                                  label: "Your name",
                                  icon: Icons.person,
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? "Enter name"
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: inputDecoration(
                                  label: "Your email",
                                  icon: Icons.email,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return "Enter email";
                                  final emailPattern = RegExp(
                                    r"^[^@]+@[^@]+\.[^@]+",
                                  );
                                  if (!emailPattern.hasMatch(v.trim()))
                                    return "Enter valid email";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              DropdownButtonFormField<String>(
                                dropdownColor: Colors.white,
                                value: topic.isEmpty ? null : topic,
                                decoration: inputDecoration(
                                  label: "Select topic",
                                  icon: Icons.label,
                                ),
                                items: topics
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => topic = val ?? ""),
                                validator: (v) => v == null || v.isEmpty
                                    ? "Select a topic"
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _messageController,
                                maxLines: 5,
                                decoration: inputDecoration(
                                  label: "Your message",
                                  icon: Icons.message,
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? "Enter message"
                                    : null,
                              ),
                              const SizedBox(height: 18),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: sending ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 6,
                                    backgroundColor: Colors.transparent,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade600,
                                          Colors.green.shade400,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        sending ? "Sending..." : "Send message",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          Icon(icon, size: 22, color: Colors.green),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
