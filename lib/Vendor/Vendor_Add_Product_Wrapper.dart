import 'package:carocart/Vendor/Vendor_Food_Add.dart';
import 'package:carocart/Vendor/Vendor_Grocery_Add.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carocart/Apis/Vendors/vendor_products.dart';

class VendorAddProductWrapper extends StatefulWidget {
  const VendorAddProductWrapper({super.key});

  @override
  State<VendorAddProductWrapper> createState() =>
      _VendorAddProductWrapperState();
}

class _VendorAddProductWrapperState extends State<VendorAddProductWrapper> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? vendor;

  @override
  void initState() {
    super.initState();
    _fetchVendor();
  }

  Future<void> _fetchVendor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";

      final vendorData = await VendorProductsApi.getCurrentVendor(token);
      print(vendorData);
      setState(() {
        vendor = vendorData;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = "Could not load vendor profile";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            "Add Product",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                "Loading vendor profile...",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null || vendor == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            "Add Product",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                error ?? "Unknown error",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    loading = true;
                    error = null;
                  });
                  _fetchVendor();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final vendorType = vendor!['vendorType'] as String?;

    if (vendorType == "FOOD") {
      return VendorFoodAddProduct(vendor: vendor!);
    } else if (vendorType == "GROCERY") {
      return VendorGroceryAddProduct(vendor: vendor!);
    } else {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            "Add Product",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.help_outline, size: 80, color: Colors.orange[300]),
              const SizedBox(height: 16),
              Text(
                "Unknown vendor type: ${vendorType ?? 'null'}",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }
  }
}
