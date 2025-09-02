import 'package:carocart/Apis/home_api.dart';
import 'package:carocart/Apis/user_api.dart';
import 'package:carocart/Utils/AppBar.dart';
import 'package:carocart/Utils/LocationPicker.dart';
import 'package:carocart/Utils/UserCards/VendorCard.dart';
import 'package:flutter/material.dart';

class UserHome extends StatefulWidget {
  final String initialTab;
  const UserHome({super.key, this.initialTab = "FOOD"});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String selectedTab = "FOOD";
  List<Map<String, dynamic>> foodVendors = [];
  List<Map<String, dynamic>> groceryVendors = [];
  List<Map<String, dynamic>> subCategories = [];
  List<Map<String, dynamic>> filteredVendors = []; // filtered by subcategory
  bool isLoadingVendors = false;
  bool isLoadingSubs = false;
  String? selectedLocation;
  double? lat = 18.41011;
  double? lng = 83.902951;
  int? selectedSubCategoryId;

  @override
  void initState() {
    selectedTab = widget.initialTab;
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

      // set default vendors
      _applyFilter();
    } catch (e) {
      setState(() {
        foodVendors = [];
        groceryVendors = [];
        subCategories = [];
        filteredVendors = [];
      });
    }

    setState(() => isLoadingVendors = false);
  }

  Future<void> _filterBySubCategory(int subCategoryId) async {
    if (lat == null || lng == null) return;

    // ✅ toggle selection
    if (selectedSubCategoryId == subCategoryId) {
      setState(() {
        selectedSubCategoryId = null;
        // Reset to all vendors for the current tab
        filteredVendors = selectedTab == "FOOD" ? foodVendors : groceryVendors;
      });
      return;
    }

    setState(() {
      selectedSubCategoryId = subCategoryId;
      isLoadingVendors = true;
    });

    try {
      final vendors = await getNearbyVendorsBySubCategory(
        subCategoryId: subCategoryId.toString(),
        lat: lat!,
        lng: lng!,
      );

      setState(() {
        filteredVendors = vendors;
      });
    } catch (e) {
      setState(() {
        filteredVendors = [];
      });
    }

    setState(() => isLoadingVendors = false);
  }

  void _applyFilter() {
    final base = selectedTab == "FOOD" ? foodVendors : groceryVendors;
    if (selectedSubCategoryId == null) {
      setState(() {
        filteredVendors = base;
      });
    } else {
      _filterBySubCategory(selectedSubCategoryId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendors = filteredVendors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppNavbar(
        cartCount: 3,
        selectedLocation: selectedLocation,
        onCartTap: () {
          Navigator.pushNamed(context, "/usercart");
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
        onLocationTap: () async {
          var result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LocationPicker(
                apiKey: "AIzaSyAJ0oDKBoCOF6cOEttl3Yf8QU8gFRrI4FU",
              ),
            ),
          );

          if (result != null) {
            setState(() {
              selectedLocation = result["description"];
              lat = result["lat"];
              lng = result["lng"];
            });

            // refresh vendors with new coordinates
            _fetchVendorsAndSubCats();
          }
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
                  // Subcategories
                  if (subCategories.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Categories",
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
                                    final id = sub["id"];
                                    final name = sub["name"] ?? "";
                                    final imageUrl = sub["imageUrl"];
                                    final isSelected =
                                        id == selectedSubCategoryId;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 16.0,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          _filterBySubCategory(id);
                                        },
                                        child: Column(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: isSelected
                                                    ? Border.all(
                                                        color: Colors.orange,
                                                        width: 3,
                                                      )
                                                    : null,
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
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: isSelected
                                                      ? Colors.orange
                                                      : Colors.black,
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

                  // Vendors List
                  Text(
                    selectedTab == "FOOD"
                        ? "Featured Restaurants"
                        : "Featured Grocery Stores",
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
