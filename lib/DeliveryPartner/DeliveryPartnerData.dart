import 'dart:io';
import 'package:flutter/material.dart';
import '../Apis/delivery.Person.dart';

class DeliveryPartnerData {
  // ------------------- Personal Information -------------------
  String? firstName;
  String? lastName;
  String? email;
  String? password;
  String? phone;
  String? whatsapp;
  bool? sameWhatsapp;
  String? dateOfBirth;
  String? city;
  String? address;
  List<String> languages = [];
  File? profileImage;
  String? profilePhotoUrl;

  // ------------------- Document URLs -------------------
  String? aadhaarFrontUrl;
  String? aadhaarBackUrl;
  String? panCardUrl;
  String? licenseUrl;
  String? rcBookUrl;
  String? passbookUrl;

  // ------------------- Local Files for Documents -------------------
  File? aadharFrontImage;
  File? aadharBackImage;
  File? panFrontImage;

  // ------------------- Vehicle Details -------------------
  String? vehicleType;
  String? vehicleNumber; // will be mapped to vehicleRegNo for backend
  String? drivingLicenseNumber;
  File? vehicleRcImage;
  File? drivingLicenseImage;

  // ------------------- Bank Account Details -------------------
  String? bankName;
  String? accountNumber;
  String? ifscCode;
  String? accountHolderName;
  String? upiId;
  File? bankStatementImage;

  DeliveryPartnerData();

  // ------------------- Print All Data -------------------
  void printAllData() {
    print("=== DELIVERY PARTNER DATA ===");
    print("📋 Personal Information:");
    print("  First Name: $firstName");
    print("  Last Name: $lastName");
    print("  Email: $email");
    print("  Phone: $phone");
    print("  WhatsApp: $whatsapp");
    print("  Same WhatsApp: $sameWhatsapp");
    print("  Date of Birth: $dateOfBirth");
    print("  City: $city");
    print("  Address: $address");
    print("  Languages: ${languages.join(', ')}");
    print("  Profile Image: ${profileImage?.path ?? 'Not uploaded'}");
    print("  Profile Photo URL: $profilePhotoUrl");

    print("\n📄 Document URLs:");
    print("  Aadhaar Front URL: $aadhaarFrontUrl");
    print("  Aadhaar Back URL: $aadhaarBackUrl");
    print("  PAN Card URL: $panCardUrl");
    print("  License URL: $licenseUrl");
    print("  RC Book URL: $rcBookUrl");
    print("  Passbook URL: $passbookUrl");

    print("\n📄 Personal Documents:");
    print("  Aadhar Front: ${aadharFrontImage?.path ?? 'Not uploaded'}");
    print("  Aadhar Back: ${aadharBackImage?.path ?? 'Not uploaded'}");
    print("  PAN Front: ${panFrontImage?.path ?? 'Not uploaded'}");

    print("\n🚗 Vehicle Details:");
    print("  Vehicle Type: $vehicleType");
    print("  Vehicle Number: $vehicleNumber");
    print("  Driving License Number: $drivingLicenseNumber");
    print("  Vehicle RC: ${vehicleRcImage?.path ?? 'Not uploaded'}");
    print("  Driving License: ${drivingLicenseImage?.path ?? 'Not uploaded'}");

    print("\n🏦 Bank Account Details:");
    print("  Bank Name: $bankName");
    print("  Account Number: $accountNumber");
    print("  IFSC Code: $ifscCode");
    print("  Account Holder Name: $accountHolderName");
    print("  UPI ID: $upiId");
    print("  Bank Statement: ${bankStatementImage?.path ?? 'Not uploaded'}");

    print("=============================");
  }

  // ------------------- Convert to JSON -------------------
  Map<String, dynamic> toJson() {
    return {
      // Personal Information
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'sameWhatsapp': sameWhatsapp,
      'city': city,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'languages': languages, // remains as a List<String>
      'password': password,
      'profilePhotoUrl': profilePhotoUrl,

      // Document URLs
      'aadhaarFrontUrl': aadhaarFrontUrl,
      'aadhaarBackUrl': aadhaarBackUrl,
      'panCardUrl': panCardUrl,
      'licenseUrl': licenseUrl,
      'rcBookUrl': rcBookUrl,
      'passbookUrl': passbookUrl,

      // Vehicle Details
      'vehicleType': vehicleType,
      'vehicleRegNo': vehicleNumber, // ✅ Backend expects vehicleRegNo
      'drivingLicenseNumber': drivingLicenseNumber,

      // Bank Details
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'ifscCode': ifscCode,
      'upiId': upiId,
    };
  }

  // ------------------- Submit Data to API -------------------
  Future<void> submitData(BuildContext context) async {
    try {
      // Convert current object to JSON
      final data = toJson();
      print("FINAL PAYLOAD BEING SENT: $data");

      // Make the API call
      final response = await deliveryRegister(context, data);

      // Handle the API response
      if (response.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration Successful!")),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to register. Please try again."),
            ),
          );
        }
      }
    } catch (e) {
      print("Submit Data Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error occurred: $e")));
      }
    }
  }
}

// ------------------- API Function -------------------

// // ------------------- API Error Handler -------------------
// void _handleApiError(BuildContext context, DioException e, String message) {
//   try {
//     String errorMessage = 'Unknown error';

//     // ✅ FIXED: Safely extract error message
//     if (e.response?.data != null) {
//       final responseData = e.response!.data;

//       if (responseData is Map<String, dynamic>) {
//         // If response data is a Map, try to get message
//         errorMessage =
//             responseData['message']?.toString() ??
//             responseData['error']?.toString() ??
//             e.message ??
//             'Unknown error';
//       } else if (responseData is String) {
//         // If response data is a String
//         errorMessage = responseData;
//       } else {
//         // If response data is something else, use the DioException message
//         errorMessage = e.message ?? 'Unknown error';
//       }
//     } else {
//       // No response data, use the DioException message
//       errorMessage = e.message ?? 'Unknown error';
//     }

//     print("API ERROR [$message]: $errorMessage");

//     if (context.mounted) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(errorMessage)));
//     }
//   } catch (handleError) {
//     // ✅ ADDED: Fallback error handling
//     print("Error in _handleApiError: $handleError");
//     print("Original API ERROR [$message]: ${e.toString()}");

//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("An error occurred. Please try again.")),
//       );
//     }
//   }
// }
