import 'package:carocart/DeliveryPartner/DeliveryDocVerification.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeliveryPartnerSignup extends StatefulWidget {
  const DeliveryPartnerSignup({super.key});

  @override
  State<DeliveryPartnerSignup> createState() => _DeliveryPartnerSignupState();
}

class _DeliveryPartnerSignupState extends State<DeliveryPartnerSignup> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dobController = TextEditingController();

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

              // First Name
              TextFormField(
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
                decoration: const InputDecoration(
                  labelText: "Last Name",
                  hintText: "Please enter last name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Last name is required" : null,
              ),
              const SizedBox(height: 15),

              // Father's Name
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Father’s Name",
                  hintText: "Please enter father’s name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Father’s name is required" : null,
              ),
              const SizedBox(height: 15),

              // Date of Birth
              TextFormField(
                controller: _dobController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Date of birth",
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

              // Primary Mobile Number
              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Primary mobile number",
                  hintText: "+91 9999988888",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Primary mobile is required" : null,
              ),
              const SizedBox(height: 15),

              // WhatsApp Number
              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "WhatsApp number",
                  hintText: "+91 9999988888",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // Secondary Mobile (Optional)
              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Secondary mobile number (Optional)",
                  hintText: "e.g. 9999999999",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // Blood Group
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Blood Group",
                  hintText: "Enter blood group here",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DeliveryDocVerification(),
                        ),
                      );
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Submit", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
