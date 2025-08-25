import 'package:flutter/material.dart';

// Mock services (replace with real HTTP calls)
Future<List<Map<String, dynamic>>> getNearbyVendors({
  required String type,
  required double lat,
  required double lng,
}) async {
  return [
    {"id": 1, "name": "$type Vendor 1", "city": "Hyderabad"},
    {"id": 2, "name": "$type Vendor 2", "city": "Hyderabad"},
  ];
}

Future<List<Map<String, dynamic>>> getSubCategoriesByVendorIds(
  List<int> vendorIds,
) async {
  return [
    {"id": 101, "name": "Biryani", "imageUrl": null},
    {"id": 102, "name": "Snacks", "imageUrl": null},
  ];
}

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

  double? lat = 17.3850; // mock location
  double? lng = 78.4867;
  String locationDisplay = "Hyderabad";

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
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.green : Colors.grey[200],
        foregroundColor: isActive ? Colors.white : Colors.black,
      ),
      onPressed: () {
        setState(() {
          selectedTab = type;
        });
        _fetchVendorsAndSubCats();
      },
      icon: Icon(icon),
      label: Text("$type ($count)"),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendors = selectedTab == "FOOD" ? foodVendors : groceryVendors;

    return Scaffold(
      appBar: AppBar(
        title: Text("CaroCart - $locationDisplay"),
        backgroundColor: Colors.green,
      ),
      body: lat == null || lng == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 50, color: Colors.red),
                  const SizedBox(height: 8),
                  const Text("Choose your location to view vendors"),
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
                  // Food / Grocery Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

                  // Subcategories
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
                            : Wrap(
                                spacing: 12,
                                children: subCategories
                                    .map(
                                      (sub) => Chip(label: Text(sub["name"])),
                                    )
                                    .toList(),
                              ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Vendors List
                  Text(
                    selectedTab == "FOOD"
                        ? "🍱 Restaurants in $locationDisplay"
                        : "🛒 Grocery Stores in $locationDisplay",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  vendors.isEmpty
                      ? const Text("No vendors found nearby.")
                      : Column(
                          children: vendors
                              .map(
                                (v) => Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.store),
                                    title: Text(v["name"]),
                                    subtitle: Text(v["city"] ?? ""),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ],
              ),
            ),
    );
  }
}
