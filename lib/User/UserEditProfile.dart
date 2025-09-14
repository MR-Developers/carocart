import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserEditProfile extends StatefulWidget {
  const UserEditProfile({Key? key}) : super(key: key);

  @override
  State<UserEditProfile> createState() => _UserEditProfileState();
}

class _UserEditProfileState extends State<UserEditProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final TextEditingController _email = TextEditingController(
    text: "user@email.com",
  );

  bool saving = false;
  File? _profileImage; // Holds selected image

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildInput({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          readOnly: readOnly || onTap != null,
          onTap: onTap,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: Icon(icon, size: 22),
            labelText: label,
            labelStyle: const TextStyle(fontWeight: FontWeight.w500),
            hintText: hint,
          ),
          validator: (val) {
            if (!readOnly && (val == null || val.isEmpty)) {
              return "Please enter $label";
            }
            return null;
          },
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dob.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Edit Profile"), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile header
            Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 45,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const NetworkImage("https://i.pravatar.cc/150?img=5")
                              as ImageProvider,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your Name",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),

            // Inputs
            _buildInput(
              icon: Icons.person,
              label: "First Name",
              controller: _firstName,
              hint: "Enter your first name",
            ),
            _buildInput(
              icon: Icons.person_outline,
              label: "Last Name",
              controller: _lastName,
              hint: "Enter your last name",
            ),
            _buildInput(
              icon: Icons.phone,
              label: "Phone Number",
              controller: _phone,
              hint: "Enter your phone number",
              keyboardType: TextInputType.phone,
            ),
            _buildInput(
              icon: Icons.calendar_month,
              label: "Date of Birth",
              controller: _dob,
              onTap: _pickDate,
            ),
            _buildInput(
              icon: Icons.email,
              label: "Email Address",
              controller: _email,
              readOnly: true,
            ),

            const SizedBox(height: 30),

            // Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          setState(() => saving = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            setState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Profile Updated Successfully"),
                              ),
                            );
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Update Profile",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
