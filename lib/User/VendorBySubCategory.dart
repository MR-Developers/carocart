import 'package:carocart/Apis/address_service.dart';
import 'package:flutter/material.dart';
import '../Apis/home_api.dart';
import '../Utils/UserCards/VendorCard.dart';

class VendorsBySubCategoryPage extends StatefulWidget {
  final int subCategoryId;
  final String title;

  const VendorsBySubCategoryPage({
    super.key,
    required this.subCategoryId,
    required this.title,
  });

  @override
  State<VendorsBySubCategoryPage> createState() =>
      _VendorsBySubCategoryPageState();
}

class _VendorsBySubCategoryPageState extends State<VendorsBySubCategoryPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> vendors = [];

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  Future<void> _fetchVendors() async {
    setState(() => isLoading = true);

    try {
      final addresses = await AddressService.getMyAddresses(context);
      final defaultAddress = addresses.firstWhere(
        (a) => a["isDefault"] == true,
        orElse: () =>
            addresses.isNotEmpty ? addresses.first : <String, dynamic>{},
      );

      final userLat = defaultAddress["latitude"];
      final userLng = defaultAddress["longitude"];
      final result = await getNearbyVendorsBySubCategory(
        subCategoryId: widget.subCategoryId.toString(),
        lat: userLat, // You can pass user location if needed
        lng: userLng,
      );

      setState(() {
        vendors = result;
      });
    } catch (e) {
      setState(() {
        vendors = [];
      });
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : vendors.isEmpty
          ? const Center(child: Text("No vendors found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vendors.length,
              itemBuilder: (context, index) {
                final v = vendors[index];
                return VendorCard(
                  vendor: v,
                  onTap: () {
                    print("Navigate to vendor ${v["id"]}");
                  },
                );
              },
            ),
    );
  }
}
