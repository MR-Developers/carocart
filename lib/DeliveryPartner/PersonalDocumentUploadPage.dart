import 'package:carocart/DeliveryPartner/DeliveryPartnerData.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Apis/delivery.Person.dart';

class PersonalDocumentUploadPage extends StatefulWidget {
  final DeliveryPartnerData deliveryData;

  const PersonalDocumentUploadPage({super.key, required this.deliveryData});

  @override
  State<PersonalDocumentUploadPage> createState() =>
      _PersonalDocumentUploadPageState();
}

class _PersonalDocumentUploadPageState
    extends State<PersonalDocumentUploadPage> {
  // Theme colors
  static const Color primaryGreen = Color(0xFF273E06);
  static const Color lightGreen = Color(0xFF4A6B1E);
  static const Color darkGreen = Color(0xFF1A2B04);
  static const Color accentGreen = Color(0xFF3B5A0F);

  File? _aadharFrontImage;
  File? _aadharBackImage;
  File? _panFrontImage;

  final ImagePicker _picker = ImagePicker();

  bool _isUploadingAadharFront = false;
  bool _isUploadingAadharBack = false;
  bool _isUploadingPanFront = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _aadharFrontImage = widget.deliveryData.aadharFrontImage;
    _aadharBackImage = widget.deliveryData.aadharBackImage;
    _panFrontImage = widget.deliveryData.panFrontImage;
  }

  String _getFolderName(String type) {
    switch (type) {
      case "AadharFront":
        return "aadhaarFront";
      case "AadharBack":
        return "aadhaarBack";
      case "PanFront":
        return "pan";
      default:
        return "documents";
    }
  }

  String _getDocumentName(String type) {
    switch (type) {
      case "AadharFront":
        return "Aadhar Front";
      case "AadharBack":
        return "Aadhar Back";
      case "PanFront":
        return "PAN Card";
      default:
        return "Document";
    }
  }

  Future<void> _pickImage(String type) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setState(() {
        switch (type) {
          case "AadharFront":
            _aadharFrontImage = File(pickedFile.path);
            break;
          case "AadharBack":
            _aadharBackImage = File(pickedFile.path);
            break;
          case "PanFront":
            _panFrontImage = File(pickedFile.path);
            break;
        }
      });

      await _uploadFileToServer(type, pickedFile.path);
    }
  }

  Future<void> _uploadFileToServer(String type, String filePath) async {
    try {
      setState(() {
        switch (type) {
          case "AadharFront":
            _isUploadingAadharFront = true;
            break;
          case "AadharBack":
            _isUploadingAadharBack = true;
            break;
          case "PanFront":
            _isUploadingPanFront = true;
            break;
        }
      });

      print("Starting upload for $type with file: $filePath");

      final folderName = _getFolderName(type);

      final response = await uploadFile(
        context: context,
        filePath: filePath,
        folder: folderName,
      );

      print("Raw API response: $response");

      String? uploadedUrl;

      if (response is Map<String, dynamic>) {
        uploadedUrl = response['data'] as String?;
      } else if (response is String) {
        uploadedUrl = response as String?;
      } else {
        uploadedUrl = response.toString();
      }

      if (uploadedUrl != null &&
          uploadedUrl.isNotEmpty &&
          uploadedUrl != 'null') {
        print("Final URL to save: $uploadedUrl");

        switch (type) {
          case "AadharFront":
            widget.deliveryData.aadhaarFrontUrl = uploadedUrl;
            break;
          case "AadharBack":
            widget.deliveryData.aadhaarBackUrl = uploadedUrl;
            break;
          case "PanFront":
            widget.deliveryData.panCardUrl = uploadedUrl;
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${_getDocumentName(type)} uploaded successfully!"),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception("Upload failed: No valid URL received from server");
      }
    } on DioException catch (e) {
      print("Dio error: ${e.message}");
      print("Dio error response: ${e.response?.data}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Network error uploading ${_getDocumentName(type)}: ${e.message}",
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        switch (type) {
          case "AadharFront":
            _aadharFrontImage = null;
            break;
          case "AadharBack":
            _aadharBackImage = null;
            break;
          case "PanFront":
            _panFrontImage = null;
            break;
        }
      });
    } finally {
      setState(() {
        switch (type) {
          case "AadharFront":
            _isUploadingAadharFront = false;
            break;
          case "AadharBack":
            _isUploadingAadharBack = false;
            break;
          case "PanFront":
            _isUploadingPanFront = false;
            break;
        }
      });
    }
  }

  bool _allDocumentsUploaded() {
    return widget.deliveryData.aadhaarFrontUrl != null &&
        widget.deliveryData.aadhaarBackUrl != null &&
        widget.deliveryData.panCardUrl != null;
  }

  void _saveDocumentDataToModel() {
    widget.deliveryData.aadharFrontImage = _aadharFrontImage;
    widget.deliveryData.aadharBackImage = _aadharBackImage;
    widget.deliveryData.panFrontImage = _panFrontImage;
  }

  void _submitDocuments() async {
    if (!_allDocumentsUploaded()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please upload all required documents"),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      _saveDocumentDataToModel();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Documents saved successfully!"),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      print("Document URLs saved:");
      print("Aadhar Front URL: ${widget.deliveryData.aadhaarFrontUrl}");
      print("Aadhar Back URL: ${widget.deliveryData.aadhaarBackUrl}");
      print("PAN Card URL: ${widget.deliveryData.panCardUrl}");

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving documents: ${e.toString()}"),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Personal Documents",
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                            Icons.description,
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
                                "Upload Required Documents",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Please upload clear photos of your documents",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Aadhar Front
                  _buildUploadCard(
                    title: "Aadhar Front",
                    icon: Icons.credit_card,
                    imageFile: _aadharFrontImage,
                    isUploading: _isUploadingAadharFront,
                    isUploaded: widget.deliveryData.aadhaarFrontUrl != null,
                    onTap: () => _pickImage("AadharFront"),
                  ),
                  const SizedBox(height: 16),

                  // Aadhar Back
                  _buildUploadCard(
                    title: "Aadhar Back",
                    icon: Icons.credit_card,
                    imageFile: _aadharBackImage,
                    isUploading: _isUploadingAadharBack,
                    isUploaded: widget.deliveryData.aadhaarBackUrl != null,
                    onTap: () => _pickImage("AadharBack"),
                  ),
                  const SizedBox(height: 16),

                  // PAN Card
                  _buildUploadCard(
                    title: "PAN Card",
                    icon: Icons.card_membership,
                    imageFile: _panFrontImage,
                    isUploading: _isUploadingPanFront,
                    isUploaded: widget.deliveryData.panCardUrl != null,
                    onTap: () => _pickImage("PanFront"),
                  ),
                ],
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: _allDocumentsUploaded()
                    ? LinearGradient(colors: [primaryGreen, accentGreen])
                    : LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[300]!],
                      ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _allDocumentsUploaded()
                    ? [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _isSubmitting ? null : _submitDocuments,
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Save Documents",
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
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required IconData icon,
    required File? imageFile,
    required bool isUploading,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded ? primaryGreen : lightGreen.withOpacity(0.3),
          width: isUploaded ? 2 : 1,
        ),
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUploaded
                          ? [primaryGreen, accentGreen]
                          : [Colors.grey[300]!, Colors.grey[200]!],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isUploaded ? Icons.check_circle : icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isUploaded)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Uploaded",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isUploading ? null : onTap,
            child: Container(
              height: 160,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryGreen.withOpacity(0.05),
                    accentGreen.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: lightGreen.withOpacity(0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Stack(
                children: [
                  if (imageFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.cloud_upload,
                              size: 40,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Tap to upload image",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "JPG, PNG (Max 5MB)",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Loading overlay
                  if (isUploading)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Uploading...",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
