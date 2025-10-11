import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carocart/DeliveryPartner/DeliveryPartnerData.dart';
import '../Apis/delivery.Person.dart';

class BankDetailsPage extends StatefulWidget {
  final DeliveryPartnerData deliveryData;

  const BankDetailsPage({super.key, required this.deliveryData});

  @override
  State<BankDetailsPage> createState() => _BankDetailsPageState();
}

class _BankDetailsPageState extends State<BankDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // Theme colors
  static const Color primaryGreen = Color(0xFF273E06);
  static const Color lightGreen = Color(0xFF4A6B1E);
  static const Color darkGreen = Color(0xFF1A2B04);
  static const Color accentGreen = Color(0xFF3B5A0F);

  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _confirmAccountNumberController =
      TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _accountHolderNameController =
      TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();

  File? _bankStatementImage;
  String? _uploadedImageUrl;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill data if exists
    _bankNameController.text = widget.deliveryData.bankName ?? '';
    _accountNumberController.text = widget.deliveryData.accountNumber ?? '';
    _confirmAccountNumberController.text =
        widget.deliveryData.accountNumber ?? '';
    _ifscCodeController.text = widget.deliveryData.ifscCode ?? '';
    _accountHolderNameController.text =
        widget.deliveryData.accountHolderName ?? '';
    _upiIdController.text = widget.deliveryData.upiId ?? '';

    _bankStatementImage = widget.deliveryData.bankStatementImage;
    _uploadedImageUrl = widget.deliveryData.passbookUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setState(() {
        _bankStatementImage = File(pickedFile.path);
      });

      await _uploadBankStatement();
    }
  }

  Future<void> _uploadBankStatement() async {
    if (_bankStatementImage == null) return;

    setState(() => _isUploading = true);

    try {
      final result = await uploadFile(
        context: context,
        filePath: _bankStatementImage!.path,
        folder: "passbook",
      );

      print("Upload Result: $result");

      if (result.containsKey("data")) {
        _uploadedImageUrl = result["data"];
        print("Uploaded Image URL: $_uploadedImageUrl");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to upload image"),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("Image Upload Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: $e"),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _saveBankDataToModel() {
    widget.deliveryData.bankName = _bankNameController.text;
    widget.deliveryData.accountNumber = _accountNumberController.text;
    widget.deliveryData.ifscCode = _ifscCodeController.text;
    widget.deliveryData.accountHolderName = _accountHolderNameController.text;
    widget.deliveryData.upiId = _upiIdController.text;
    widget.deliveryData.bankStatementImage = _bankStatementImage;
    widget.deliveryData.passbookUrl = _uploadedImageUrl;
  }

  void _submitBankDetails() {
    if (_formKey.currentState!.validate()) {
      if (_accountNumberController.text !=
          _confirmAccountNumberController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Account numbers do not match"),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please upload bank statement image"),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      _saveBankDataToModel();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Bank details saved successfully"),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    }
  }

  String? _validateIFSC(String? value) {
    if (value == null || value.isEmpty) {
      return "IFSC code is required";
    }
    if (value.length != 11) {
      return "IFSC code must be 11 characters";
    }
    return null;
  }

  String? _validateAccountNumber(String? value) {
    if (value == null || value.isEmpty) {
      return "Account number is required";
    }
    if (value.length < 9 || value.length > 18) {
      return "Account number must be 9-18 digits";
    }
    return null;
  }

  String? _validateUPI(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!value.contains('@')) {
        return "Invalid UPI ID format";
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Bank Details",
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryGreen, accentGreen],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bank Account Information",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Enter your bank details for payments",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Account Holder Name
              _buildTextField(
                controller: _accountHolderNameController,
                label: "Account Holder Name",
                hint: "Enter name as per bank records",
                icon: Icons.person_outline,
                validator: (value) =>
                    value!.isEmpty ? "Account holder name is required" : null,
              ),
              const SizedBox(height: 16),

              // Bank Name
              _buildTextField(
                controller: _bankNameController,
                label: "Bank Name",
                hint: "e.g., State Bank of India",
                icon: Icons.account_balance_outlined,
                validator: (value) =>
                    value!.isEmpty ? "Bank name is required" : null,
              ),
              const SizedBox(height: 16),

              // Account Number
              _buildTextField(
                controller: _accountNumberController,
                label: "Account Number",
                hint: "Enter your account number",
                icon: Icons.credit_card,
                keyboardType: TextInputType.number,
                validator: _validateAccountNumber,
              ),
              const SizedBox(height: 16),

              // Confirm Account Number
              _buildTextField(
                controller: _confirmAccountNumberController,
                label: "Confirm Account Number",
                hint: "Re-enter your account number",
                icon: Icons.verified_user_outlined,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Please confirm account number" : null,
              ),
              const SizedBox(height: 16),

              // IFSC Code
              _buildTextField(
                controller: _ifscCodeController,
                label: "IFSC Code",
                hint: "e.g., SBIN0001234",
                icon: Icons.qr_code,
                validator: _validateIFSC,
              ),
              const SizedBox(height: 16),

              // UPI ID (Optional)
              _buildTextField(
                controller: _upiIdController,
                label: "UPI ID (Optional)",
                hint: "e.g., yourname@paytm",
                icon: Icons.payment,
                validator: _validateUPI,
              ),
              const SizedBox(height: 24),

              // Bank Statement Upload Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lightGreen.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryGreen.withOpacity(0.1),
                                accentGreen.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.upload_file,
                            color: primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Bank Statement / Passbook",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryGreen.withOpacity(0.05),
                              accentGreen.withOpacity(0.05),
                            ],
                          ),
                          border: Border.all(
                            color: lightGreen.withOpacity(0.4),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isUploading
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Uploading...",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : (_uploadedImageUrl != null &&
                                  _uploadedImageUrl!.isNotEmpty)
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      _uploadedImageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [primaryGreen, accentGreen],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _bankStatementImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _bankStatementImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryGreen.withOpacity(0.1),
                                          accentGreen.withOpacity(0.1),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.cloud_upload,
                                      size: 48,
                                      color: primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Tap to upload bank statement",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "or passbook image",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Upload first page of bank statement or passbook showing account details",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
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
                    onTap: _submitBankDetails,
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Save Bank Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[300]!, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _ifscCodeController.dispose();
    _accountHolderNameController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }
}
