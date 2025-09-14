import 'dart:io';
import 'package:carocart/Apis/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Apis/delivery.Person.dart';

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
  final TextEditingController _email = TextEditingController();

  bool saving = false;
  bool loading = true;
  File? _profileImage;
  String? _profileImageUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String formatDob(String input) {
    try {
      final parsed = DateFormat("d/M/yyyy").parseStrict(input);
      return DateFormat("yyyy-MM-dd").format(parsed);
    } catch (e) {
      print("❌ DOB parsing failed: $e");
      return "";
    }
  }

  String parseDob(String input) {
    try {
      final parsed = DateFormat("yyyy-MM-dd").parseStrict(input);
      return DateFormat("d/M/yyyy").format(parsed);
    } catch (e) {
      return "";
    }
  }

  Future<void> _loadProfile() async {
    final profile = await UserService.getProfile();
    if (profile != null) {
      setState(() {
        _firstName.text = profile["firstName"] ?? "";
        _lastName.text = profile["lastName"] ?? "";
        _phone.text = profile["phoneNumber"] ?? "";
        _dob.text = parseDob(profile["dob"] ?? "");
        _email.text = profile["email"] ?? "";
        _profileImageUrl = profile["profileImageUrl"];
        loading = false;
      });
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load profile")));
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    // Update UI preview immediately
    setState(() {
      _profileImage = file;
    });
    String url = "";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    final userId = decodedToken["userId"];
    try {
      // 🔑 Upload to Firebase Storage
      final response = await uploadFile(
        context: context,
        filePath: pickedFile.path,
        folder: "profile_images/${userId}",
      );
      if (response.containsKey("data")) {
        url = response["data"];
      } else {
        throw Exception("Problem occured when uploading an image");
      }

      // 🔄 Update backend profile with new image URL
      final success = await UserService.updateProfileImage({"imageUrl": url});

      if (success) {
        setState(() {
          _profileImageUrl = url; // update avatar image
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile picture updated successfully!"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile image.")),
        );
      }
    } catch (e) {
      print("❌ Image upload error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error uploading image")));
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    final user = {
      "firstName": _firstName.text.trim(),
      "lastName": _lastName.text.trim(),
      "phoneNumber": _phone.text.trim(),
      "dob": formatDob(_dob.text.trim()),
      "email": _email.text.trim(),
      "profileImageUrl": _profileImageUrl,
    };

    bool success = await UserService.updateProfile(user);

    setState(() => saving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Edit Profile"), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 45,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (_profileImageUrl != null &&
                              _profileImageUrl!.isNotEmpty)
                        ? NetworkImage(_profileImageUrl!)
                        : const NetworkImage("https://i.pravatar.cc/150?img=5")
                              as ImageProvider,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "${_firstName.text} ${_lastName.text}".trim().isEmpty
                      ? "Your Name"
                      : "${_firstName.text} ${_lastName.text}",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _updateProfile,
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
