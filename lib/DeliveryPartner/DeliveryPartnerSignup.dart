import 'dart:io';
import 'package:carocart/DeliveryPartner/DeliveryDocVerification.dart';
import 'package:carocart/DeliveryPartner/DeliveryPartnerData.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../Apis/delivery.Person.dart';

class DeliveryPartnerSignup extends StatefulWidget {
  const DeliveryPartnerSignup({super.key});

  @override
  State<DeliveryPartnerSignup> createState() => _DeliveryPartnerSignupState();
}

class _DeliveryPartnerSignupState extends State<DeliveryPartnerSignup> {
  // Theme colors
  static const Color primaryGreen = Color(0xFF273E06);
  static const Color lightGreen = Color(0xFF4A6B1E);
  static const Color darkGreen = Color(0xFF1A2B04);
  static const Color accentGreen = Color(0xFF3B5A0F);

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
  bool _obscurePassword = true;

  File? _profileImage;
  String? _uploadedProfileUrl;
  bool _isUploadingProfile = false;

  final List<String> _languages = [
    "Telugu",
    "Hindi",
    "English",
    "Marathi",
    "Tamil",
    "Other",
  ];
  final List<String> _selectedLanguages = [];

  final DeliveryPartnerData _deliveryData = DeliveryPartnerData();

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }

  void _toggleLanguage(String lang, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedLanguages.add(lang);
      } else {
        _selectedLanguages.remove(lang);
      }
    });
  }

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

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    setState(() => _isUploadingProfile = true);

    try {
      final result = await uploadFile(
        context: context,
        filePath: _profileImage!.path,
        folder: "profile",
      );

      print("Upload Result (profile): $result");

      if (result.containsKey("data")) {
        setState(() {
          _uploadedProfileUrl = result["data"];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to upload profile image"),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("Upload Error (profile): $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: $e"),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isUploadingProfile = false);
    }
  }

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
    _deliveryData.profilePhotoUrl = _uploadedProfileUrl;
  }

  void _goToNext() {
    if (_formKey.currentState!.validate()) {
      if (_uploadedProfileUrl == null || _uploadedProfileUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please upload a profile picture"),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (_selectedLanguages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please select at least one language"),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Personal Information",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryGreen, accentGreen],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryGreen.withOpacity(0.1),
                      accentGreen.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lightGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryGreen, accentGreen],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Let's Get Started",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Fill in your details to create an account",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Profile Photo Upload
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: lightGreen, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _uploadedProfileUrl != null
                                ? NetworkImage(_uploadedProfileUrl!)
                                : _profileImage != null
                                ? FileImage(_profileImage!) as ImageProvider
                                : null,
                            child:
                                _profileImage == null &&
                                    _uploadedProfileUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey[400],
                                  )
                                : null,
                          ),
                        ),
                        if (_isUploadingProfile)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryGreen, accentGreen],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                    const SizedBox(height: 12),
                    Text(
                      "Tap camera icon to upload photo",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // First Name
              _buildTextField(
                controller: _firstNameController,
                label: "First Name",
                hint: "Enter your first name",
                icon: Icons.person_outline,
                validator: (value) =>
                    value!.isEmpty ? "First name is required" : null,
              ),
              const SizedBox(height: 16),

              // Last Name
              _buildTextField(
                controller: _lastNameController,
                label: "Last Name",
                hint: "Enter your last name",
                icon: Icons.person_outline,
                validator: (value) =>
                    value!.isEmpty ? "Last name is required" : null,
              ),
              const SizedBox(height: 16),

              // Email
              _buildTextField(
                controller: _emailController,
                label: "Email",
                hint: "Enter your email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) return "Email is required";
                  if (!value.contains('@')) return "Enter a valid email";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lightGreen.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Enter your password",
                    prefixIcon: Icon(Icons.lock_outline, color: primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: primaryGreen,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return "Password is required";
                    if (value.length < 6)
                      return "Password must be at least 6 characters";
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Date of Birth
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lightGreen.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Date of Birth",
                    hintText: "dd-mm-yyyy",
                    prefixIcon: Icon(Icons.cake_outlined, color: primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today, color: primaryGreen),
                      onPressed: () => _selectDate(context),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Date of birth is required" : null,
                ),
              ),
              const SizedBox(height: 16),

              // Mobile Number
              _buildTextField(
                controller: _phoneController,
                label: "Mobile Number",
                hint: "+91 9999988888",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value!.isEmpty) return "Mobile number is required";
                  if (value.length != 10)
                    return "Enter a valid 10-digit number";
                  return null;
                },
                onChanged: (value) {
                  if (_sameAsMobile) {
                    _whatsappController.text = value;
                  }
                },
              ),
              const SizedBox(height: 16),

              // WhatsApp Number with "Same as mobile"
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _whatsappController,
                      label: "WhatsApp Number",
                      hint: "+91 9999988888",
                      icon: Icons.chat_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value!.isEmpty ? "WhatsApp number is required" : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _sameAsMobile
                          ? primaryGreen.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _sameAsMobile
                            ? primaryGreen
                            : lightGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Transform.scale(
                          scale: 0.9,
                          child: Checkbox(
                            value: _sameAsMobile,
                            onChanged: (value) => _handleSameAsMobile(value!),
                            activeColor: primaryGreen,
                          ),
                        ),
                        Text(
                          "Same as\nmobile",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            color: _sameAsMobile ? primaryGreen : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // City
              _buildTextField(
                controller: _cityController,
                label: "City",
                hint: "Enter your city",
                icon: Icons.location_city_outlined,
                validator: (value) =>
                    value!.isEmpty ? "City is required" : null,
              ),
              const SizedBox(height: 16),

              // Address
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lightGreen.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Address",
                    hintText: "Enter your complete address",
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: primaryGreen,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Address is required" : null,
                ),
              ),
              const SizedBox(height: 20),

              // Languages
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lightGreen.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, color: primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "Languages Known",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _languages.map((lang) {
                        final isSelected = _selectedLanguages.contains(lang);
                        return FilterChip(
                          label: Text(lang),
                          selected: isSelected,
                          onSelected: (selected) =>
                              _toggleLanguage(lang, selected),
                          selectedColor: primaryGreen.withOpacity(0.2),
                          checkmarkColor: primaryGreen,
                          backgroundColor: Colors.grey[100],
                          side: BorderSide(
                            color: isSelected
                                ? primaryGreen
                                : Colors.grey[300]!,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Next Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryGreen, accentGreen]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _goToNext,
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Next",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  @override
  void dispose() {
    _dobController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
