import 'package:carocart/DeliveryPartner/DeliveryPartnerData.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Apis/delivery.Person.dart'; // Your API service import

class PersonalDocumentUploadPage extends StatefulWidget {
  final DeliveryPartnerData deliveryData;

  const PersonalDocumentUploadPage({super.key, required this.deliveryData});

  @override
  State<PersonalDocumentUploadPage> createState() =>
      _PersonalDocumentUploadPageState();
}

class _PersonalDocumentUploadPageState
    extends State<PersonalDocumentUploadPage> {
  File? _aadharFrontImage;
  File? _aadharBackImage;
  File? _panFrontImage;

  final ImagePicker _picker = ImagePicker();

  // Loading states for each upload
  bool _isUploadingAadharFront = false;
  bool _isUploadingAadharBack = false;
  bool _isUploadingPanFront = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill data if it exists
    _aadharFrontImage = widget.deliveryData.aadharFrontImage;
    _aadharBackImage = widget.deliveryData.aadharBackImage;
    _panFrontImage = widget.deliveryData.panFrontImage;
  }

  // ✅ Helper method to dynamically return folder name
  String _getFolderName(String type) {
    switch (type) {
      case "AadharFront":
        return "aadhaarFront";
      case "AadharBack":
        return "aadhaarBack";
      case "PanFront":
        return "pan";
      default:
        return "documents"; // Fallback folder
    }
  }

  // ✅ Helper method to get document name for display
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

  // ✅ Pick Image from gallery and upload
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

  // ✅ Upload file to server and get URL
  Future<void> _uploadFileToServer(String type, String filePath) async {
    try {
      // Set loading state
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

      // Get dynamic folder name
      final folderName = _getFolderName(type);

      // Call the API with dynamic folder name
      final response = await uploadFile(
        context: context,
        filePath: filePath,
        folder: folderName,
      );

      print("Raw API response: $response");

      String? uploadedUrl;

      // Handle response format
      if (response is Map<String, dynamic>) {
        uploadedUrl = response['data'] as String?;
      } else if (response is String) {
        uploadedUrl = response as String?;
      } else {
        uploadedUrl = response.toString();
      }

      // Validate URL
      if (uploadedUrl != null &&
          uploadedUrl.isNotEmpty &&
          uploadedUrl != 'null') {
        print("Final URL to save: $uploadedUrl");

        // Assign the URL to DeliveryPartnerData
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
            backgroundColor: Colors.green,
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
          backgroundColor: Colors.red,
        ),
      );

      // Reset local file on failure
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
      // Reset loading state
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

  // ✅ Check if all documents are uploaded
  bool _allDocumentsUploaded() {
    return widget.deliveryData.aadhaarFrontUrl != null &&
        widget.deliveryData.aadhaarBackUrl != null &&
        widget.deliveryData.panCardUrl != null;
  }

  // ✅ Save document data to model
  void _saveDocumentDataToModel() {
    widget.deliveryData.aadharFrontImage = _aadharFrontImage;
    widget.deliveryData.aadharBackImage = _aadharBackImage;
    widget.deliveryData.panFrontImage = _panFrontImage;
  }

  // ✅ Submit documents
  void _submitDocuments() async {
    if (!_allDocumentsUploaded()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload all required documents"),
          backgroundColor: Colors.red,
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
        const SnackBar(
          content: Text("Documents saved successfully!"),
          backgroundColor: Colors.green,
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
          backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: const Text("Upload Personal Documents"),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upload Required Documents",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

                  // Aadhar Front
                  _buildUploadCard(
                    title: "Aadhar Front",
                    imageFile: _aadharFrontImage,
                    isUploading: _isUploadingAadharFront,
                    isUploaded: widget.deliveryData.aadhaarFrontUrl != null,
                    onTap: () => _pickImage("AadharFront"),
                  ),
                  const SizedBox(height: 20),

                  // Aadhar Back
                  _buildUploadCard(
                    title: "Aadhar Back",
                    imageFile: _aadharBackImage,
                    isUploading: _isUploadingAadharBack,
                    isUploaded: widget.deliveryData.aadhaarBackUrl != null,
                    onTap: () => _pickImage("AadharBack"),
                  ),
                  const SizedBox(height: 20),

                  // PAN Card
                  _buildUploadCard(
                    title: "PAN Card",
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
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, -1),
                  blurRadius: 5,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitDocuments,
              style: ElevatedButton.styleFrom(
                backgroundColor: _allDocumentsUploaded()
                    ? Colors.green
                    : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Save Documents",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Upload Card Widget
  Widget _buildUploadCard({
    required String title,
    required File? imageFile,
    required bool isUploading,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "$title Upload",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            if (isUploaded)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: isUploading ? null : onTap,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: isUploaded ? Colors.green : Colors.grey,
                width: isUploaded ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                if (imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  )
                else
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Tap to upload image"),
                      ],
                    ),
                  ),

                // Loading overlay
                if (isUploading)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            "Uploading...",
                            style: TextStyle(color: Colors.white),
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
    );
  }
}
