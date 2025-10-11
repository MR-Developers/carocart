import 'package:carocart/DeliveryPartner/BankDetails.dart';
import 'package:carocart/DeliveryPartner/DeliveryPartnerData.dart';
import 'package:carocart/DeliveryPartner/PersonalDocumentUploadPage.dart';
import 'package:carocart/DeliveryPartner/VehicleDetailsPage.dart';
import 'package:flutter/material.dart';

class DeliveryDocVerification extends StatefulWidget {
  final DeliveryPartnerData? deliveryData;

  const DeliveryDocVerification({super.key, required this.deliveryData});

  @override
  State<DeliveryDocVerification> createState() =>
      _DeliveryDocVerificationState();
}

class _DeliveryDocVerificationState extends State<DeliveryDocVerification> {
  // Theme colors
  static const Color primaryGreen = Color(0xFF273E06);
  static const Color lightGreen = Color(0xFF4A6B1E);
  static const Color darkGreen = Color(0xFF1A2B04);
  static const Color accentGreen = Color(0xFF3B5A0F);

  bool isPersonalDocCompleted = false;
  bool isVehicleDetailsCompleted = false;
  bool isBankDetailsCompleted = false;
  bool isEmergencyDetailsCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkCompletionStatus();
  }

  void _checkCompletionStatus() {
    if (widget.deliveryData != null) {
      setState(() {
        // Add your own logic to check completion status
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen, accentGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome ${widget.deliveryData?.firstName ?? 'User'}!",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Complete your profile to start earning",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Document Verification Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
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
                    Icons.assignment_outlined,
                    color: primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Document Verification",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Document tiles
          _buildEditableDocTile(
            context,
            "Personal Documents",
            isPersonalDocCompleted,
            Icons.person_outline,
          ),
          _buildEditableDocTile(
            context,
            "Vehicle Details",
            isVehicleDetailsCompleted,
            Icons.directions_car_outlined,
          ),
          _buildEditableDocTile(
            context,
            "Bank Account Details",
            isBankDetailsCompleted,
            Icons.account_balance_outlined,
          ),

          const SizedBox(height: 24),

          // Progress Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: lightGreen.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryGreen.withOpacity(0.1),
                              accentGreen.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.trending_up,
                          color: primaryGreen,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Your Progress",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _getCompletionPercentage(),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${(_getCompletionPercentage() * 100).toInt()}% Complete",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryGreen,
                        ),
                      ),
                      Text(
                        "${_getCompletedCount()}/3 Steps",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Print Data Button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[400]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        widget.deliveryData?.printAllData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "Data printed to console! Check debug output.",
                            ),
                            backgroundColor: Colors.blue[700],
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.print_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Print All Data",
                              style: TextStyle(
                                fontSize: 16,
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
                const SizedBox(height: 12),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _isAllDocumentsCompleted()
                        ? LinearGradient(colors: [primaryGreen, accentGreen])
                        : LinearGradient(
                            colors: [Colors.grey[400]!, Colors.grey[300]!],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isAllDocumentsCompleted()
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
                      onTap: _isAllDocumentsCompleted()
                          ? () {
                              _showSubmitConfirmationDialog();
                            }
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    "Please complete all document uploads first.",
                                  ),
                                  backgroundColor: Colors.orange[700],
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Submit Application",
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
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEditableDocTile(
    BuildContext context,
    String title,
    bool isCompleted,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? primaryGreen.withOpacity(0.5)
              : lightGreen.withOpacity(0.3),
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToDocumentPage(context, title, isCompleted),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isCompleted
                        ? LinearGradient(colors: [primaryGreen, accentGreen])
                        : LinearGradient(
                            colors: [Colors.grey[300]!, Colors.grey[200]!],
                          ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? Colors.black87
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted
                            ? "Completed - Tap to edit"
                            : "Tap to complete",
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? primaryGreen : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? primaryGreen.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCompleted ? Icons.edit_outlined : Icons.arrow_forward_ios,
                    size: 16,
                    color: isCompleted ? primaryGreen : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
    }
  }

  bool _isAllDocumentsCompleted() {
    return isPersonalDocCompleted &&
        isVehicleDetailsCompleted &&
        isBankDetailsCompleted;
  }

  int _getCompletedCount() {
    int count = 0;
    if (isPersonalDocCompleted) count++;
    if (isVehicleDetailsCompleted) count++;
    if (isBankDetailsCompleted) count++;
    return count;
  }

  double _getCompletionPercentage() {
    return _getCompletedCount() / 3.0;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSubmitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
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
                child: Icon(Icons.send_outlined, color: primaryGreen),
              ),
              const SizedBox(width: 12),
              const Text("Submit Application"),
            ],
          ),
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
                widget.deliveryData?.submitData(context);
                _submitApplication();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void _submitApplication() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Application submitted successfully! You can still edit your details anytime.",
        ),
        backgroundColor: primaryGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
