import 'package:carocart/Apis/home_api.dart';
import 'package:carocart/Utils/AppBar.dart';
import 'package:carocart/Utils/VendorCard.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String selectedTab = "FOOD";
  List<Map<String, dynamic>> foodVendors = [];
  List<Map<String, dynamic>> groceryVendors = [];
  List<Map<String, dynamic>> subCategories = [];
  bool isLoadingVendors = false;
  bool isLoadingSubs = false;

  double? lat = 18.41011;
  double? lng = 83.902951;

  @override
  void initState() {
    super.initState();
    _fetchVendorsAndSubCats();
  }

  Future<void> _fetchVendorsAndSubCats() async {
    if (lat == null || lng == null) return;
    setState(() => isLoadingVendors = true);

    try {
      final food = await getNearbyVendors(type: "FOOD", lat: lat!, lng: lng!);
      final grocery = await getNearbyVendors(
        type: "GROCERY",
        lat: lat!,
        lng: lng!,
      );

      setState(() {
        foodVendors = food;
        groceryVendors = grocery;
      });

      List<int> vendorIds = [];
      if (selectedTab == "FOOD" && food.isNotEmpty) {
        vendorIds = food.map((v) => v["id"] as int).toList();
      } else if (selectedTab == "GROCERY" && grocery.isNotEmpty) {
        vendorIds = grocery.map((v) => v["id"] as int).toList();
      }

      if (vendorIds.isNotEmpty) {
        setState(() => isLoadingSubs = true);
        final subs = await getSubCategoriesByVendorIds(vendorIds);
        setState(() {
          subCategories = subs;
          isLoadingSubs = false;
        });
      } else {
        setState(() => subCategories = []);
      }
    } catch (e) {
      setState(() {
        foodVendors = [];
        groceryVendors = [];
        subCategories = [];
      });
    }

    setState(() => isLoadingVendors = false);
  }

  Widget _buildTabButton(String type, int count, IconData icon) {
    final isActive = selectedTab == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedTab = type);
          _fetchVendorsAndSubCats();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
            ],
            border: Border.all(
              color: isActive ? Colors.green : Colors.grey.shade300,
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isActive ? Colors.white : Colors.black54),
              const SizedBox(height: 4),
              Text(
                "$type ($count)",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendors = selectedTab == "FOOD" ? foodVendors : groceryVendors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppNavbar(
        cartCount: 3,
        onCartTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Cart clicked")));
        },
        onLoginTap: () {
          Navigator.pushNamed(context, "/login");
        },
        onSellerTap: () {
          Navigator.pushNamed(context, "/seller");
        },
        onProfileTap: () {
          Navigator.pushNamed(context, "/profile");
        },
      ),
      body: lat == null || lng == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.location_on, size: 50, color: Colors.red),
                  SizedBox(height: 8),
                  Text("Choose your location to view vendors"),
                ],
              ),
            )
          : isLoadingVendors
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Tabs ----
                  Row(
                    children: [
                      _buildTabButton(
                        "FOOD",
                        foodVendors.length,
                        Icons.restaurant,
                      ),
                      _buildTabButton(
                        "GROCERY",
                        groceryVendors.length,
                        Icons.store,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ---- Subcategories ----
                  if (subCategories.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Browse by category",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        isLoadingSubs
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: subCategories.map((sub) {
                                    final name = sub["name"] ?? "";
                                    final imageUrl = sub["imageUrl"];

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 16.0,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          print("Tapped subcategory: $name");
                                        },
                                        child: Column(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: CircleAvatar(
                                                radius: 32,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                backgroundImage:
                                                    (imageUrl != null &&
                                                        imageUrl.isNotEmpty)
                                                    ? NetworkImage(imageUrl)
                                                    : null,
                                                child:
                                                    (imageUrl == null ||
                                                        imageUrl.isEmpty)
                                                    ? Text(
                                                        name.isNotEmpty
                                                            ? name[0]
                                                                  .toUpperCase()
                                                            : "?",
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black54,
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              width: 80,
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // ---- Vendors List ----
                  Text(
                    selectedTab == "FOOD"
                        ? "🍱 Restaurants near you"
                        : "🛒 Grocery Stores near you",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  vendors.isEmpty
                      ? const Text("No vendors found nearby.")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                ],
              ),
            ),
    );
  }
}
