import 'dart:async';

import 'package:carocart/Apis/address_service.dart';
import 'package:carocart/Apis/home_api.dart';
import 'package:carocart/Apis/user_api.dart';
import 'package:carocart/User/ViewAllCategories.dart';
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
  bool isLoadingAddress = true;
  String? selectedLocation;
  final PageController _bannerController = PageController(viewportFraction: 1);
  int _currentBannerIndex = 0;
  List<int>? vendorIdList;
  Timer? _bannerTimer;
  double? lat;
  double? lng;
  int? selectedSubCategoryId;
  List<Map<String, String>> banners = [
    {"imageUrl": "assets/images/Banner_1.png"},
    {"imageUrl": "assets/images/Banner_2.jpg"},
  ];

  @override
  void initState() {
    selectedTab = widget.initialTab;
    super.initState();
    _loadDefaultAddress();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (banners.isEmpty) return;

      _currentBannerIndex = (_currentBannerIndex + 1) % banners.length;

      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final addresses = await AddressService.getMyAddresses(context);
      final defaultAddress = addresses.firstWhere(
        (a) => a["isDefault"] == true,
        orElse: () =>
            addresses.isNotEmpty ? addresses.first : <String, dynamic>{},
      );
      if (!mounted) return; // <- from user_api.dart
      setState(() {
        lat = defaultAddress["latitude"];
        lng = defaultAddress["longitude"];
        selectedLocation =
            defaultAddress["address"] ?? defaultAddress["description"];
      });
      _fetchVendorsAndSubCats();
    } catch (e) {
      if (!mounted) return;
      // fallback if API fails
      setState(() {
        selectedLocation = null;
        lat = null;
        lng = null;
      });
    } finally {
      if (!mounted) return;
      setState(() => isLoadingAddress = false);
    }
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
        setState(() {
          vendorIdList = vendorIds;
        });
      } else if (selectedTab == "GROCERY" && grocery.isNotEmpty) {
        vendorIds = grocery.map((v) => v["id"] as int).toList();
        setState(() {
          vendorIdList = vendorIds;
        });
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
      if (!mounted) return;
      setState(() {
        foodVendors = [];
        groceryVendors = [];
        subCategories = [];
        filteredVendors = [];
      });
    }
    if (!mounted) return;
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
  void dispose() {
    super.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final vendors = filteredVendors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppNavbar(
        onLocationChanged: (location, newLat, newLng) {
          setState(() {
            selectedLocation = location;
            lat = newLat;
            lng = newLng;
          });
          _fetchVendorsAndSubCats(); // reload vendors when location changes
        },
      ),
      body:
          (!isLoadingAddress && !isLoadingSubs && (lat == null || lng == null))
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.location_on, size: 60, color: Colors.redAccent),
                  SizedBox(height: 10),
                  Text(
                    "Choose your location to view vendors",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : isLoadingAddress
          ? const Center(child: CircularProgressIndicator())
          : (selectedTab == "GROCERY")
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Gradient Container with Shadow - Fresh Green Theme
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF38ef7d).withOpacity(0.4),
                            blurRadius: 30,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Gradient Text Effect - Green Gradient
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                      ).createShader(bounds),
                      child: Text(
                        "Coming Soon!",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        "We're crafting something amazing! 🎉\nYour grocery shopping experience is about to get a whole lot better.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748b),
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Color.fromARGB(255, 255, 250, 242), // soft orange
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // Background grocery icons
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.35, // subtle
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 30,
                            crossAxisSpacing: 30,
                          ),
                      itemCount: 20, // number of icons
                      itemBuilder: (context, index) {
                        return const Icon(
                          Icons.shopping_cart, // you can mix other icons too
                          size: 50,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Scroller
                      if (banners.isNotEmpty)
                        Column(
                          children: [
                            SizedBox(
                              height: 180,
                              child: PageView.builder(
                                itemCount: banners.length,
                                controller: _bannerController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentBannerIndex = index;
                                  });
                                },

                                itemBuilder: (context, index) {
                                  final banner = banners[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            banner["imageUrl"]!,
                                            fit: BoxFit.cover,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.black.withOpacity(0.3),
                                                  Colors.transparent,
                                                ],
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Small dot indicator
                            // Small dot indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                banners.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  height: 8,
                                  width: _currentBannerIndex == index
                                      ? 16
                                      : 8, // active dot wider
                                  decoration: BoxDecoration(
                                    color: _currentBannerIndex == index
                                        ? Colors.orangeAccent
                                        : Colors.grey.withOpacity(
                                            0.5,
                                          ), // inactive grey
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      // Subcategories
                      if (subCategories.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Categories",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AllCategoriesPage(
                                          vendorIds: vendorIdList,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "View All",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            isLoadingSubs
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : SizedBox(
                                    height: 120,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: subCategories.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 16),
                                      itemBuilder: (context, index) {
                                        final sub = subCategories[index];
                                        final id = sub["id"];
                                        final name = sub["name"] ?? "";
                                        final imageUrl = sub["imageUrl"];
                                        final isSelected =
                                            id == selectedSubCategoryId;

                                        return GestureDetector(
                                          onTap: () => _filterBySubCategory(id),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeOut,
                                            width: 80,
                                            child: Column(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: isSelected
                                                        ? const LinearGradient(
                                                            colors: [
                                                              Colors.orange,
                                                              Colors.deepOrange,
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          )
                                                        : null,
                                                    boxShadow: [
                                                      if (isSelected)
                                                        BoxShadow(
                                                          color: Colors.orange
                                                              .withOpacity(0.5),
                                                          blurRadius: 10,
                                                          spreadRadius: 2,
                                                        ),
                                                    ],
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: isSelected
                                                        ? 38
                                                        : 34,
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
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 22,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black54,
                                                                ),
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? Colors.orange
                                                              .withOpacity(0.1)
                                                        : Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isSelected
                                                          ? Colors.deepOrange
                                                          : Colors.black87,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ],
                        ),

                      const SizedBox(height: 10),

                      // Vendors List
                      Text(
                        selectedTab == "FOOD"
                            ? "🍔 Featured Restaurants"
                            : "🛒 Featured Grocery Stores",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 14),
                      isLoadingVendors
                          ? ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  5, // show 5 shimmer cards while loading
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (_, __) => const VendorCardShimmer(),
                            )
                          : vendors.isEmpty
                          ? const Text("No vendors found nearby.")
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: vendors.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
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
              ],
            ),
    );
  }
}

Widget _buildDot({bool isActive = false}) {
  return Container(
    width: isActive ? 24 : 8,
    height: 8,
    decoration: BoxDecoration(
      gradient: isActive
          ? LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
          : null,
      color: isActive ? null : Color(0xFFe2e8f0),
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
