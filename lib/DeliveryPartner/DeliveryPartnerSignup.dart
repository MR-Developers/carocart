import 'dart:io';
import 'package:carocart/DeliveryPartner/DeliveryDocVerification.dart';
import 'package:carocart/DeliveryPartner/DeliveryPartnerData.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../Apis/delivery.Person.dart'; // ✅ Import API for file upload

class DeliveryPartnerSignup extends StatefulWidget {
  const DeliveryPartnerSignup({super.key});

  @override
  State<DeliveryPartnerSignup> createState() => _DeliveryPartnerSignupState();
}

class _DeliveryPartnerSignupState extends State<DeliveryPartnerSignup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _sameAsMobile = false;

  // For storing picked image
  File? _profileImage;
  String? _uploadedProfileUrl; // ✅ Uploaded Profile Image URL
  bool _isUploadingProfile = false; // ✅ Loader state

  // Languages
  final List<String> _languages = [
    "Telugu",
    "Hindi",
    "English",
    "Marathi",
    "Tamil",
    "Other",
  ];
  final List<String> _selectedLanguages = [];

  // Data model instance
  final DeliveryPartnerData _deliveryData = DeliveryPartnerData();

  /// ==========================
  /// Date Picker
  /// ==========================
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }

  /// ==========================
  /// Toggle Languages
  /// ==========================
  void _toggleLanguage(String lang, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedLanguages.add(lang);
      } else {
        _selectedLanguages.remove(lang);
      }
    });
  }

  /// ==========================
  /// Same as mobile logic
  /// ==========================
  void _handleSameAsMobile(bool value) {
    setState(() {
      _sameAsMobile = value;
      if (value) {
        _whatsappController.text = _phoneController.text;
      } else {
        _whatsappController.clear();
      }
    });
  }

  /// ==========================
  /// Pick Image
  /// ==========================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      await _uploadProfileImage();
    }
  }

  /// ==========================
  /// Upload Profile Image to Server
  /// ==========================
  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    setState(() => _isUploadingProfile = true);

    try {
      final result = await uploadFile(
        context: context,
        filePath: _profileImage!.path,
        folder: "profile", // ✅ Folder name is `profile`
      );

      print("Upload Result (profile): $result");

      if (result.containsKey("data")) {
        setState(() {
          _uploadedProfileUrl = result["data"];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload profile image")),
        );
      }
    } catch (e) {
      print("Upload Error (profile): $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      setState(() => _isUploadingProfile = false);
    }
  }

  /// ==========================
  /// Save Data to Model
  /// ==========================
  void _saveDataToModel() {
    _deliveryData.firstName = _firstNameController.text;
    _deliveryData.lastName = _lastNameController.text;
    _deliveryData.email = _emailController.text;
    _deliveryData.password = _passwordController.text;
    _deliveryData.dateOfBirth = _dobController.text;
    _deliveryData.phone = _phoneController.text;
    _deliveryData.whatsapp = _whatsappController.text;
    _deliveryData.sameWhatsapp = _sameAsMobile;
    _deliveryData.city = _cityController.text;
    _deliveryData.address = _addressController.text;
    _deliveryData.languages = List.from(_selectedLanguages);

    _deliveryData.profileImage = _profileImage;
    _deliveryData.profilePhotoUrl = _uploadedProfileUrl; // ✅ Save URL
  }

  /// ==========================
  /// Validate and Go to Next Step
  /// ==========================
  void _goToNext() {
    if (_formKey.currentState!.validate()) {
      if (_uploadedProfileUrl == null || _uploadedProfileUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload a profile picture")),
        );
        return;
      }

      if (_selectedLanguages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select at least one language")),
        );
        return;
      }

      // Save data to model before navigation
      _saveDataToModel();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DeliveryDocVerification(deliveryData: _deliveryData),
        ),
      );
    }
  }

  /// ==========================
  /// Build UI
  /// ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Information"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter Your Details",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              // Profile Photo Upload
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _uploadedProfileUrl != null
                                ? NetworkImage(_uploadedProfileUrl!)
                                : _profileImage != null
                                ? FileImage(_profileImage!) as ImageProvider
                                : null,
                            child:
                                _profileImage == null &&
                                    _uploadedProfileUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          if (_isUploadingProfile)
                            const CircularProgressIndicator(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Upload Profile Photo"),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: "First Name",
                  hintText: "Please enter first name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "First name is required" : null,
              ),
              const SizedBox(height: 15),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: "Last Name",
                  hintText: "Please enter last name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Last name is required" : null,
              ),
              const SizedBox(height: 15),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  hintText: "Enter your email",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Email is required" : null,
              ),
              const SizedBox(height: 15),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  hintText: "Enter your password",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Password is required" : null,
              ),
              const SizedBox(height: 15),

              // Date of Birth
              TextFormField(
                controller: _dobController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Date of Birth",
                  hintText: "dd-mm-yyyy",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.red),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Date of birth is required" : null,
              ),
              const SizedBox(height: 15),

              // Mobile Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Mobile Number",
                  hintText: "+91 9999988888",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Mobile number is required" : null,
                onChanged: (value) {
                  if (_sameAsMobile) {
                    _whatsappController.text = value;
                  }
                },
              ),
              const SizedBox(height: 15),

              // WhatsApp Number with "Same as mobile"
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "WhatsApp Number",
                        hintText: "+91 9999988888",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "WhatsApp number is required" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Checkbox(
                        value: _sameAsMobile,
                        onChanged: (value) => _handleSameAsMobile(value!),
                      ),
                      const Text(
                        "Same as mobile",
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // City
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: "City",
                  hintText: "Enter your city",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "City is required" : null,
              ),
              const SizedBox(height: 15),

              // Address
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Address",
                  hintText: "Enter your address",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Address is required" : null,
              ),
              const SizedBox(height: 15),

              // Languages
              const Text(
                "Languages Known",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _languages.map((lang) {
                  final isSelected = _selectedLanguages.contains(lang);
                  return FilterChip(
                    label: Text(lang),
                    selected: isSelected,
                    onSelected: (selected) => _toggleLanguage(lang, selected),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Next", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
