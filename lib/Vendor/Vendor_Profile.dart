import 'dart:io';
import 'package:carocart/Apis/Vendors/vendor_products.dart';
import 'package:carocart/Apis/Vendors/vendor_profile.dart';
import 'package:carocart/User/UserChangePassword.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  Map<String, dynamic>? vendor;
  bool editMode = false;
  bool loading = true;
  String imageUrl = "";
  bool passwordLoading = false;

  // Password fields
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Form controllers
  final Map<String, TextEditingController> controllers = {};
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchVendor();
  }

  Future<void> fetchVendor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("auth_token") ?? "";
      final data = await VendorProductsApi.getCurrentVendor(token);
      setState(() {
        vendor = data;
        imageUrl = data["profileImageUrl"] ?? "";
        vendor?.forEach((key, value) {
          controllers[key] = TextEditingController(text: value?.toString());
        });
      });
    } catch (e) {
      _showMessage("Failed to fetch vendor info", isError: true);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> saveProfile() async {
    if (vendor == null) return;
    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("auth_token") ?? "";
      final updatedVendor = <String, dynamic>{};
      controllers.forEach((key, controller) {
        if (controller.text.trim().isNotEmpty) {
          updatedVendor[key] = controller.text.trim();
        }
      });

      await VendorProfileApi.updateVendorProfile(token, updatedVendor);
      _showMessage("Profile updated successfully!");
      setState(() => editMode = false);
      await fetchVendor();
    } catch (e) {
      _showMessage("Failed to update profile", isError: true);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> uploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    if (file.lengthSync() > 2 * 1024 * 1024) {
      _showMessage("File size must be less than 2MB", isError: true);
      return;
    }

    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("auth_token") ?? "";
      await VendorProfileApi.uploadVendorProfileImage(token, file);
      _showMessage("Profile image updated successfully!");
      await fetchVendor();
    } catch (e) {
      _showMessage("Failed to upload image", isError: true);
    } finally {
      setState(() => loading = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text("Change Password"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Current Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "New Password",
                  prefixIcon: const Icon(Icons.lock_open),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: const Icon(Icons.lock_open),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              currentPasswordController.clear();
              newPasswordController.clear();
              confirmPasswordController.clear();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _changePassword();
            },
            child: const Text("Change"),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    final current = currentPasswordController.text;
    final newPass = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showMessage("All fields are required", isError: true);
      return;
    }

    if (newPass != confirm) {
      _showMessage("New passwords do not match", isError: true);
      return;
    }

    if (newPass.length < 6) {
      _showMessage("New password must be at least 6 characters", isError: true);
      return;
    }

    setState(() => passwordLoading = true);
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      _showMessage("Password changed successfully!");
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } catch (e) {
      _showMessage("Failed to change password", isError: true);
    } finally {
      setState(() => passwordLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading && vendor == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            "Profile",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (!editMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => editMode = true),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF273E06), Color(0xFF1F2C05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : null,
                        child: imageUrl.isEmpty
                            ? Text(
                                "${vendor?['firstName']?.substring(0, 1).toUpperCase() ?? 'V'}${vendor?['lastName']?.substring(0, 1).toUpperCase() ?? ''}",
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: uploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${vendor?['firstName'] ?? ''} ${vendor?['lastName'] ?? ''}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor?['email'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Profile Information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildTextField(
                      "First Name",
                      "firstName",
                      Icons.person_outline,
                    ),
                    _buildTextField(
                      "Last Name",
                      "lastName",
                      Icons.person_outline,
                    ),
                    _buildTextField(
                      "Contact Number",
                      "contactNumber",
                      Icons.phone_outlined,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const Text(
                    "Business Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildTextField(
                      "Company Name",
                      "companyName",
                      Icons.business_outlined,
                    ),
                    _buildTextField(
                      "GST Number",
                      "gstNumber",
                      Icons.receipt_outlined,
                    ),
                    _buildTextField(
                      "Business Type",
                      "businessType",
                      Icons.category_outlined,
                    ),
                    _buildTextField(
                      "Business Address",
                      "businessAddress",
                      Icons.location_on_outlined,
                      maxLines: 3,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (editMode) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading ? null : saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: loading
                                ? null
                                : () {
                                    setState(() {
                                      editMode = false;
                                      fetchVendor();
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (!editMode) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.lock_outline),
                        label: const Text(
                          "Change Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF273E06),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(
    String label,
    String key,
    IconData icon, {
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controllers[key],
        readOnly: readOnly || !editMode,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          filled: !editMode,
          fillColor: !editMode ? Colors.grey[50] : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}
