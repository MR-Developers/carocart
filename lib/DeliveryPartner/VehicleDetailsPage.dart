import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carocart/DeliveryPartner/DeliveryPartnerData.dart';
import '../Apis/delivery.Person.dart'; // ✅ API for file upload

class VehicleDetailsPage extends StatefulWidget {
  final DeliveryPartnerData deliveryData;

  const VehicleDetailsPage({super.key, required this.deliveryData});

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _drivingLicenseNumberController =
      TextEditingController();

  String? _selectedVehicleType;
  File? _vehicleRcImage;
  File? _drivingLicenseImage;

  String? _uploadedRcUrl; // ✅ Uploaded RC URL
  String? _uploadedLicenseUrl; // ✅ Uploaded License URL

  bool _isRcUploading = false; // ✅ Loader state for RC
  bool _isLicenseUploading = false; // ✅ Loader state for License

  final List<String> _vehicleTypes = [
    'Motorcycle',
    'Scooter',
    'Bicycle',
    'Auto Rickshaw',
    'Car',
    'Van',
  ];

  @override
  void initState() {
    super.initState();

    // Pre-fill data if exists
    _vehicleNumberController.text = widget.deliveryData.vehicleNumber ?? '';
    _drivingLicenseNumberController.text =
        widget.deliveryData.drivingLicenseNumber ?? '';
    _selectedVehicleType = widget.deliveryData.vehicleType;

    _vehicleRcImage = widget.deliveryData.vehicleRcImage;
    _drivingLicenseImage = widget.deliveryData.drivingLicenseImage;

    _uploadedRcUrl = widget.deliveryData.rcBookUrl;
    _uploadedLicenseUrl = widget.deliveryData.licenseUrl;
  }

  /// ==========================
  /// Pick Image
  /// ==========================
  Future<void> _pickImage(String imageType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      if (imageType == 'rc') {
        setState(() {
          _vehicleRcImage = File(pickedFile.path);
        });
        await _uploadImage('rc');
      } else if (imageType == 'license') {
        setState(() {
          _drivingLicenseImage = File(pickedFile.path);
        });
        await _uploadImage('license');
      }
    }
  }

  /// ==========================
  /// Upload Image to Server
  /// ==========================
  Future<void> _uploadImage(String imageType) async {
    final file = imageType == 'rc' ? _vehicleRcImage : _drivingLicenseImage;
    if (file == null) return;

    if (imageType == 'rc') {
      setState(() => _isRcUploading = true);
    } else {
      setState(() => _isLicenseUploading = true);
    }

    try {
      final result = await uploadFile(
        context: context,
        filePath: file.path,
        folder: imageType == 'rc' ? "rc" : "license",
      );

      print("Upload Result ($imageType): $result");

      if (result.containsKey("data")) {
        setState(() {
          if (imageType == 'rc') {
            _uploadedRcUrl = result["data"];
          } else {
            _uploadedLicenseUrl = result["data"];
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload $imageType image")),
        );
      }
    } catch (e) {
      print("Upload Error ($imageType): $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (imageType == 'rc') {
        setState(() => _isRcUploading = false);
      } else {
        setState(() => _isLicenseUploading = false);
      }
    }
  }

  /// ==========================
  /// Save Data to Model
  /// ==========================
  void _saveVehicleDataToModel() {
    widget.deliveryData.vehicleType = _selectedVehicleType;
    widget.deliveryData.vehicleNumber = _vehicleNumberController.text;
    widget.deliveryData.drivingLicenseNumber =
        _drivingLicenseNumberController.text;

    widget.deliveryData.vehicleRcImage = _vehicleRcImage;
    widget.deliveryData.drivingLicenseImage = _drivingLicenseImage;

    widget.deliveryData.rcBookUrl = _uploadedRcUrl;
    widget.deliveryData.licenseUrl = _uploadedLicenseUrl;
  }

  /// ==========================
  /// Submit Form
  /// ==========================
  void _submitVehicleDetails() {
    if (_formKey.currentState!.validate()) {
      if (_selectedVehicleType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select vehicle type")),
        );
        return;
      }

      if (_uploadedRcUrl == null || _uploadedRcUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload RC book image")),
        );
        return;
      }

      if (_uploadedLicenseUrl == null || _uploadedLicenseUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload driving license image")),
        );
        return;
      }

      // Save data before returning
      _saveVehicleDataToModel();
      Navigator.pop(context, true);
    }
  }

  /// ==========================
  /// UI Build
  /// ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Details"),
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
                "Enter Vehicle Information",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              // Vehicle Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedVehicleType,
                decoration: const InputDecoration(
                  labelText: "Vehicle Type",
                  hintText: "Select your vehicle type",
                  border: OutlineInputBorder(),
                ),
                items: _vehicleTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedVehicleType = value;
                  });
                },
                validator: (value) =>
                    value == null ? "Please select vehicle type" : null,
              ),
              const SizedBox(height: 15),

              // Vehicle Number
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(
                  labelText: "Vehicle Number",
                  hintText: "e.g., MH12AB1234",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Vehicle number is required" : null,
              ),
              const SizedBox(height: 15),

              // Driving License Number
              TextFormField(
                controller: _drivingLicenseNumberController,
                decoration: const InputDecoration(
                  labelText: "Driving License Number",
                  hintText: "Enter your license number",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "License number is required" : null,
              ),
              const SizedBox(height: 20),

              // RC Book Upload
              const Text(
                "RC Book Upload",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _pickImage('rc'),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isRcUploading
                      ? const Center(child: CircularProgressIndicator())
                      : (_uploadedRcUrl != null && _uploadedRcUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _uploadedRcUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _vehicleRcImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _vehicleRcImage!,
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
                            Text("Tap to upload RC Book image"),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Driving License Upload
              const Text(
                "Driving License Upload",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _pickImage('license'),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLicenseUploading
                      ? const Center(child: CircularProgressIndicator())
                      : (_uploadedLicenseUrl != null &&
                            _uploadedLicenseUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _uploadedLicenseUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _drivingLicenseImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _drivingLicenseImage!,
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
                            Text("Tap to upload License image"),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitVehicleDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Save Vehicle Details",
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
    _vehicleNumberController.dispose();
    _drivingLicenseNumberController.dispose();
    super.dispose();
  }
}
