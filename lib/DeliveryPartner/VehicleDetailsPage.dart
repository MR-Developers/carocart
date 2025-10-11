import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carocart/DeliveryPartner/DeliveryPartnerData.dart';
import '../Apis/delivery.Person.dart';

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

  String? _uploadedRcUrl;
  String? _uploadedLicenseUrl;

  bool _isRcUploading = false;
  bool _isLicenseUploading = false;

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
    _vehicleNumberController.text = widget.deliveryData.vehicleNumber ?? '';
    _drivingLicenseNumberController.text =
        widget.deliveryData.drivingLicenseNumber ?? '';
    _selectedVehicleType = widget.deliveryData.vehicleType;
    _vehicleRcImage = widget.deliveryData.vehicleRcImage;
    _drivingLicenseImage = widget.deliveryData.drivingLicenseImage;
    _uploadedRcUrl = widget.deliveryData.rcBookUrl;
    _uploadedLicenseUrl = widget.deliveryData.licenseUrl;
  }

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

      _saveVehicleDataToModel();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF273E06), Color(0xFF3A5A0A), Color(0xFF4D7610)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar with gradient
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Vehicle Details",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Enter Vehicle Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF273E06),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Vehicle Type Dropdown
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF273E06).withOpacity(0.2),
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedVehicleType,
                              decoration: const InputDecoration(
                                labelText: "Vehicle Type",
                                labelStyle: TextStyle(color: Color(0xFF273E06)),
                                hintText: "Select your vehicle type",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              dropdownColor: Colors.white,
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
                              validator: (value) => value == null
                                  ? "Please select vehicle type"
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Vehicle Number
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF273E06).withOpacity(0.2),
                              ),
                            ),
                            child: TextFormField(
                              controller: _vehicleNumberController,
                              decoration: const InputDecoration(
                                labelText: "Vehicle Number",
                                labelStyle: TextStyle(color: Color(0xFF273E06)),
                                hintText: "e.g., MH12AB1234",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) => value!.isEmpty
                                  ? "Vehicle number is required"
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Driving License Number
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF273E06).withOpacity(0.2),
                              ),
                            ),
                            child: TextFormField(
                              controller: _drivingLicenseNumberController,
                              decoration: const InputDecoration(
                                labelText: "Driving License Number",
                                labelStyle: TextStyle(color: Color(0xFF273E06)),
                                hintText: "Enter your license number",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) => value!.isEmpty
                                  ? "License number is required"
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // RC Book Upload
                          const Text(
                            "RC Book Upload",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF273E06),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _pickImage('rc'),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF273E06).withOpacity(0.1),
                                    const Color(0xFF4D7610).withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF273E06,
                                  ).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: _isRcUploading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF273E06),
                                            ),
                                      ),
                                    )
                                  : (_uploadedRcUrl != null &&
                                        _uploadedRcUrl!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        _uploadedRcUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _vehicleRcImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        _vehicleRcImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF273E06,
                                            ).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 48,
                                            color: Color(0xFF273E06),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Tap to upload RC Book image",
                                          style: TextStyle(
                                            color: Color(0xFF273E06),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Driving License Upload
                          const Text(
                            "Driving License Upload",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF273E06),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _pickImage('license'),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF273E06).withOpacity(0.1),
                                    const Color(0xFF4D7610).withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF273E06,
                                  ).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: _isLicenseUploading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF273E06),
                                            ),
                                      ),
                                    )
                                  : (_uploadedLicenseUrl != null &&
                                        _uploadedLicenseUrl!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        _uploadedLicenseUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _drivingLicenseImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        _drivingLicenseImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF273E06,
                                            ).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 48,
                                            color: Color(0xFF273E06),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Tap to upload License image",
                                          style: TextStyle(
                                            color: Color(0xFF273E06),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit Button with Gradient
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFF273E06),
                                  Color(0xFF3A5A0A),
                                  Color(0xFF4D7610),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF273E06,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _submitVehicleDetails,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Save Vehicle Details",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
