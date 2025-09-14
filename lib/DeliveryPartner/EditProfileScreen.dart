import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Apis/delivery.Person.dart';
import '../Apis/delivery.Person.dart'; // Assuming uploadFile API is here

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> existingData;

  const EditProfileScreen({super.key, required this.existingData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  String? _profilePhotoUrl;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _firstNameController = TextEditingController(
      text: widget.existingData['firstName'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.existingData['lastName'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.existingData['phone'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.existingData['email'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.existingData['address'] ?? '',
    );
    _profilePhotoUrl = widget.existingData['profilePhotoUrl'];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Pick image from gallery or camera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// Handle profile update
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null || token.isEmpty) {
        throw Exception("No token found. Please log in again.");
      }

      String? finalImageUrl = _profilePhotoUrl;
      print('finalImageUrl' + (finalImageUrl ?? 'null'));
      // If a new image is selected, upload it first
      if (_selectedImage != null) {
        final uploadResponse = await uploadFile(
          context: context,
          filePath: _selectedImage!.path,
          folder: "profile", // Folder name for backend
        );

        if (uploadResponse.isNotEmpty && uploadResponse['data'] != null) {
          finalImageUrl = uploadResponse['data']; // Image URL
        } else {
          throw Exception("Failed to upload image");
        }
      }

      // Prepare updated data
      final payload = {
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "email": _emailController.text.trim(),
        "address": _addressController.text.trim(),
        "profilePhotoUrl": finalImageUrl,
      };

      // Update profile
      final response = await updateDeliveryProfile(context, token, payload);

      if (response.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        Navigator.pop(context, true); // return to previous screen
      } else {
        throw Exception("Profile update failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Build form field
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: (value) =>
            value == null || value.trim().isEmpty ? "$label is required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile"), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Profile Image
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (_profilePhotoUrl != null &&
                                      _profilePhotoUrl!.isNotEmpty)
                                ? NetworkImage(_profilePhotoUrl!)
                                : const AssetImage(
                                        'assets/images/default_avatar.png',
                                      )
                                      as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildTextField("First Name", _firstNameController),
                    _buildTextField("Last Name", _lastNameController),
                    _buildTextField(
                      "Phone",
                      _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      "Email",
                      _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField("Address", _addressController),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Update Profile",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
