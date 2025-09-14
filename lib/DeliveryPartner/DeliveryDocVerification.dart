import 'package:carocart/DeliveryPartner/BankDetails.dart';
import 'package:carocart/DeliveryPartner/DeliveryPartnerData.dart';
import 'package:carocart/DeliveryPartner/PersonalDocumentUploadPage.dart';
import 'package:carocart/DeliveryPartner/VehicleDetailsPage.dart';
import 'package:flutter/material.dart';
// Import the data model

class DeliveryDocVerification extends StatefulWidget {
  final DeliveryPartnerData? deliveryData;

  const DeliveryDocVerification({super.key, required this.deliveryData});

  @override
  State<DeliveryDocVerification> createState() =>
      _DeliveryDocVerificationState();
}

class _DeliveryDocVerificationState extends State<DeliveryDocVerification> {
  bool isPersonalDocCompleted = false;
  bool isVehicleDetailsCompleted = false;
  bool isBankDetailsCompleted = false;
  bool isEmergencyDetailsCompleted = false;

  @override
  void initState() {
    super.initState();
    // Check if documents are already completed based on the deliveryData
    _checkCompletionStatus();
  }

  void _checkCompletionStatus() {
    // You can add logic here to check if documents are already filled
    // For example, check if certain fields in deliveryData are not null/empty
    // This is just an example - adjust based on your DeliveryPartnerData structure

    if (widget.deliveryData != null) {
      // Example: Check if personal documents are completed
      // Adjust these conditions based on your actual data structure
      setState(() {
        // Add your own logic to check completion status
        // isPersonalDocCompleted = widget.deliveryData!.somePersonalField != null;
        // isVehicleDetailsCompleted = widget.deliveryData!.someVehicleField != null;
        // isBankDetailsCompleted = widget.deliveryData!.someBankField != null;
        // isEmergencyDetailsCompleted = widget.deliveryData!.someEmergencyField != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header Section with Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2ECC71)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Welcome ${widget.deliveryData?.firstName ?? 'User'}!",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Just a few steps to complete and then you can start earning with Us",
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ✅ All Documents Section (Always visible for editing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Document Verification",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          // ✅ All document tiles - always visible and editable
          _buildEditableDocTile(
            context,
            "Personal Documents",
            isPersonalDocCompleted,
          ),
          _buildEditableDocTile(
            context,
            "Vehicle Details",
            isVehicleDetailsCompleted,
          ),
          _buildEditableDocTile(
            context,
            "Bank Account Details",
            isBankDetailsCompleted,
          ),

          const SizedBox(height: 20),

          // ✅ Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Progress",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _getCompletionPercentage(),
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 5),
                Text(
                  "${(_getCompletionPercentage() * 100).toInt()}% Complete",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ✅ Print Data Button (for testing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Print all data to console
                  widget.deliveryData?.printAllData();

                  // Show snackbar for user feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Data printed to console! Check debug output.",
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Print All Data",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Submit Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Check if all documents are completed
                  if (_isAllDocumentsCompleted()) {
                    // Show confirmation dialog before submitting
                    _showSubmitConfirmationDialog();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please complete all document uploads first.",
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAllDocumentsCompleted()
                      ? Colors.green
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Submit Application",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ New Editable Doc Tile that shows status and allows editing
  Widget _buildEditableDocTile(
    BuildContext context,
    String title,
    bool isCompleted,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            color: isCompleted ? Colors.black : Colors.grey[700],
          ),
        ),
        subtitle: Text(
          isCompleted ? "Completed - Tap to edit" : "Tap to complete",
          style: TextStyle(
            fontSize: 12,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
        ),
        trailing: Icon(
          isCompleted ? Icons.edit : Icons.arrow_forward_ios,
          size: 16,
          color: Colors.green,
        ),
        onTap: () => _navigateToDocumentPage(context, title, isCompleted),
      ),
    );
  }

  // ✅ Navigation logic for document pages
  Future<void> _navigateToDocumentPage(
    BuildContext context,
    String title,
    bool isCompleted,
  ) async {
    dynamic result;

    if (title == "Personal Documents") {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PersonalDocumentUploadPage(deliveryData: widget.deliveryData!),
        ),
      );

      // Update completion status based on result
      if (result == true) {
        setState(() {
          isPersonalDocCompleted = true;
        });
        _showSuccessMessage("Personal documents updated successfully!");
      }
    } else if (title == "Vehicle Details") {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              VehicleDetailsPage(deliveryData: widget.deliveryData!),
        ),
      );

      if (result == true) {
        setState(() {
          isVehicleDetailsCompleted = true;
        });
        _showSuccessMessage("Vehicle details updated successfully!");
      }
    } else if (title == "Bank Account Details") {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BankDetailsPage(deliveryData: widget.deliveryData!),
        ),
      );

      if (result == true) {
        setState(() {
          isBankDetailsCompleted = true;
        });
        _showSuccessMessage("Bank details updated successfully!");
      }
    } else if (title == "Emergency Details") {
      // For now, just mark as completed - implement your emergency details page
      setState(() {
        isEmergencyDetailsCompleted = !isEmergencyDetailsCompleted;
      });

      if (isEmergencyDetailsCompleted) {
        _showSuccessMessage("Emergency details completed!");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Emergency details page - Coming Soon!"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ✅ Helper methods
  bool _isAllDocumentsCompleted() {
    return isPersonalDocCompleted &&
        isVehicleDetailsCompleted &&
        isBankDetailsCompleted;
  }

  double _getCompletionPercentage() {
    int completedCount = 0;
    if (isPersonalDocCompleted) completedCount++;
    if (isVehicleDetailsCompleted) completedCount++;
    if (isBankDetailsCompleted) completedCount++;

    return completedCount / 3.0;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSubmitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Submit Application"),
          content: const Text(
            "Are you sure you want to submit your application? "
            "You can still edit your details after submission if needed.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitApplication();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _submitApplication() {
    // Add your submission logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Application submitted successfully! You can still edit your details anytime.",
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
