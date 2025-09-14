import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carocart/DeliveryPartner/DeliveryPartnerData.dart';
import '../Apis/delivery.Person.dart'; // ✅ Import the API file

class BankDetailsPage extends StatefulWidget {
  final DeliveryPartnerData deliveryData;

  const BankDetailsPage({super.key, required this.deliveryData});

  @override
  State<BankDetailsPage> createState() => _BankDetailsPageState();
}

class _BankDetailsPageState extends State<BankDetailsPage> {
  final _formKey = GlobalKey<FormState>();

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
  String? _uploadedImageUrl; // ✅ Store uploaded image URL

  bool _isUploading = false; // ✅ Loader state for upload

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

  /// ==========================
  /// Pick Image and Upload
  /// ==========================
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

      // Immediately upload after picking
      await _uploadBankStatement();
    }
  }

  /// ==========================
  /// Upload Bank Statement Image
  /// ==========================
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

      // ✅ Handle safe response
      if (result.containsKey("data")) {
        _uploadedImageUrl = result["data"];
        print("Uploaded Image URL: $_uploadedImageUrl");
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to upload image")));
      }
    } catch (e) {
      print("Image Upload Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// ==========================
  /// Save Data to Model
  /// ==========================
  void _saveBankDataToModel() {
    widget.deliveryData.bankName = _bankNameController.text;
    widget.deliveryData.accountNumber = _accountNumberController.text;
    widget.deliveryData.ifscCode = _ifscCodeController.text;
    widget.deliveryData.accountHolderName = _accountHolderNameController.text;
    widget.deliveryData.upiId = _upiIdController.text;
    widget.deliveryData.bankStatementImage = _bankStatementImage;
    widget.deliveryData.passbookUrl = _uploadedImageUrl; // ✅ Save uploaded URL
  }

  /// ==========================
  /// Form Submit
  /// ==========================
  void _submitBankDetails() {
    if (_formKey.currentState!.validate()) {
      // Validate account numbers match
      if (_accountNumberController.text !=
          _confirmAccountNumberController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account numbers do not match")),
        );
        return;
      }

      // Ensure image is uploaded
      if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload bank statement image")),
        );
        return;
      }

      // Save data before returning
      _saveBankDataToModel();

      Navigator.pop(context, true);
    }
  }

  /// ==========================
  /// Validators
  /// ==========================
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

  /// ==========================
  /// UI Build
  /// ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bank Details"),
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
                "Enter Bank Account Information",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              // Account Holder Name
              TextFormField(
                controller: _accountHolderNameController,
                decoration: const InputDecoration(
                  labelText: "Account Holder Name",
                  hintText: "Enter name as per bank records",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Account holder name is required" : null,
              ),
              const SizedBox(height: 15),

              // Bank Name
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: "Bank Name",
                  hintText: "e.g., State Bank of India",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Bank name is required" : null,
              ),
              const SizedBox(height: 15),

              // Account Number
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Account Number",
                  hintText: "Enter your account number",
                  border: OutlineInputBorder(),
                ),
                validator: _validateAccountNumber,
              ),
              const SizedBox(height: 15),

              // Confirm Account Number
              TextFormField(
                controller: _confirmAccountNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Confirm Account Number",
                  hintText: "Re-enter your account number",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please confirm account number" : null,
              ),
              const SizedBox(height: 15),

              // IFSC Code
              TextFormField(
                controller: _ifscCodeController,
                decoration: const InputDecoration(
                  labelText: "IFSC Code",
                  hintText: "e.g., SBIN0001234",
                  border: OutlineInputBorder(),
                ),
                validator: _validateIFSC,
              ),
              const SizedBox(height: 15),

              // UPI ID (Optional)
              TextFormField(
                controller: _upiIdController,
                decoration: const InputDecoration(
                  labelText: "UPI ID (Optional)",
                  hintText: "e.g., yourname@paytm",
                  border: OutlineInputBorder(),
                ),
                validator: _validateUPI,
              ),
              const SizedBox(height: 20),

              // Bank Statement Upload
              const Text(
                "Bank Statement / Passbook Upload",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : (_uploadedImageUrl != null &&
                            _uploadedImageUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _uploadedImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _bankStatementImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _bankStatementImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 40,
                              color: Colors.grey,
                            ),
                            Text("Tap to upload bank statement"),
                            Text(
                              "or passbook image",
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Upload first page of bank statement or passbook showing account details",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitBankDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Save Bank Details",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
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
