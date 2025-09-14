import 'package:carocart/Utils/LocationPicker.dart';
import 'package:flutter/material.dart';
import 'package:carocart/Apis/address_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EditAddressPage extends StatefulWidget {
  final Map<String, dynamic> address;
  const EditAddressPage({super.key, required this.address});

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _instructionsController;

  String addressType = "Home";
  LatLng? selectedLatLng;
  String formattedAddress = "";

  bool saving = false;

  final List<String> addressTypes = ["Home", "Work", "Other"];

  @override
  void initState() {
    super.initState();
    final addr = widget.address;
    _nameController = TextEditingController(text: addr["fullName"] ?? "");
    _phoneController = TextEditingController(text: addr["phoneNumber"] ?? "");
    _instructionsController = TextEditingController(
      text: addr["instructions"] ?? "",
    );
    addressType = addr["type"] ?? "Home";
    formattedAddress = addr["address"] ?? "";
    selectedLatLng = LatLng(addr["latitude"] ?? 0, addr["longitude"] ?? 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedLatLng == null || formattedAddress.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pick a location on map")));
      return;
    }

    setState(() => saving = true);

    final success =
        await AddressService.updateAddress(context, widget.address["id"], {
          "fullName": _nameController.text.trim(),
          "phoneNumber": _phoneController.text.trim(),
          "instructions": _instructionsController.text.trim(),
          "type": addressType,
          "address": formattedAddress,
          "latitude": selectedLatLng!.latitude,
          "longitude": selectedLatLng!.longitude,
          "isDefault": widget.address["isDefault"] ?? false,
        });

    setState(() => saving = false);

    if (success != null) {
      Navigator.pop(context, true); // return to previous page
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Address updated")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update address")));
    }
  }

  void _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(
          initialLatLng: selectedLatLng!,
          apiKey: "AIzaSyAJ0oDKBoCOF6cOEttl3Yf8QU8gFRrI4FU",
        ),
      ),
    );

    if (result != null) {
      setState(() {
        selectedLatLng = LatLng(result["lat"], result["lng"]);
        formattedAddress = result["description"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Address")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Map picker
              GestureDetector(
                onTap: _openMapPicker,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade600),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    formattedAddress.isEmpty
                        ? "Pick delivery location on map"
                        : formattedAddress,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (val) {
                  if (val == null || val.trim().length < 10) {
                    return "Enter valid phone number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address Type
              DropdownButtonFormField<String>(
                value: addressType,
                decoration: const InputDecoration(
                  labelText: "Address Type",
                  border: OutlineInputBorder(),
                ),
                items: addressTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => addressType = val!),
              ),
              const SizedBox(height: 16),

              // Instructions
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: "Delivery Instructions (optional)",
                  border: OutlineInputBorder(),
                ),
                maxLength: 80,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: saving ? null : _saveChanges,
                  child: Text(saving ? "Saving..." : "Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
