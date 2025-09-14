import 'dart:io';

class DeliveryPartnerData {
  // Personal Information
  String? firstName;
  String? lastName;
  String? email;
  String? password;
  String? phone; // Changed from mobileNumber to phone
  String? whatsapp; // Changed from whatsappNumber to whatsapp
  bool? sameWhatsapp; // Added - missing field from React
  String? dateOfBirth;
  String? city;
  String? address;
  List<String> languages = [];
  File? profileImage;
  String? profilePhotoUrl; // Added - missing field from React

  // Document URLs (from React data)
  String? aadhaarFrontUrl; // Added - missing field from React
  String? aadhaarBackUrl; // Added - missing field from React
  String? panCardUrl; // Added - missing field from React
  String? licenseUrl; // Added - missing field from React
  String? rcBookUrl; // Added - missing field from React
  String? passbookUrl; // Added - missing field from React

  // Personal Documents (local files)
  File? aadharFrontImage;
  File? aadharBackImage;
  File? panFrontImage;
  // Removed panBackImage as it's not in React data

  // Vehicle Details
  String? vehicleType;
  String? vehicleNumber;
  String? drivingLicenseNumber; // Added - missing field from React
  // Removed vehicleModel as it's not in React data
  File? vehicleRcImage;
  File? drivingLicenseImage;

  // Bank Account Details
  String? bankName;
  String? accountNumber;
  String? ifscCode;
  String? accountHolderName;
  String? upiId; // Added - missing field from React
  File? bankStatementImage;

  // Removed Emergency Details as they're not in React data

  DeliveryPartnerData();

  // Method to print all data
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

  // Method to convert to JSON (matching React structure)
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'sameWhatsapp': sameWhatsapp,
      'city': city,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'languages': languages,
      'password': password,
      'profilePhotoUrl': profilePhotoUrl,
      'aadhaarFrontUrl': aadhaarFrontUrl,
      'aadhaarBackUrl': aadhaarBackUrl,
      'panCardUrl': panCardUrl,
      'licenseUrl': licenseUrl,
      'rcBookUrl': rcBookUrl,
      'passbookUrl': passbookUrl,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'drivingLicenseNumber': drivingLicenseNumber,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'ifscCode': ifscCode,
      'upiId': upiId,
    };
  }
}
