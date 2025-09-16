import 'package:carocart/Apis/cart_service.dart';
import 'package:carocart/Apis/home_api.dart';
import 'package:carocart/Apis/product_service.dart';
import 'package:carocart/User/ProductDetails.dart';
import 'package:carocart/Utils/Messages.dart';
import 'package:carocart/Utils/UserCards/ProductCard.dart';
import 'package:flutter/material.dart';

class VendorProductsPage extends StatefulWidget {
  final int vendorId;

  const VendorProductsPage({super.key, required this.vendorId});

  @override
  State<VendorProductsPage> createState() => _VendorProductsPageState();
}

class _VendorProductsPageState extends State<VendorProductsPage> {
  Map<String, dynamic>? vendor;
  Map<String, dynamic> groupedProducts = {};
  final Map<String, GlobalKey> _subcategoryKeys = {};
  Map<int, int> quantities = {};
  bool loading = true;
  bool cartUpdating = false;
  int? cartVendorId;

  String? error;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {}; // category -> key
  List<Map<String, dynamic>> allProducts = [];
  String filterType = "all"; // values: "all", "veg", "nonveg"

  OverlayEntry? _searchOverlay;
  final LayerLink _searchLink = LayerLink();
  final List<Color> avatarColors = [
    Colors.green.shade400,
    Colors.blue.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
  ];
  @override
  void initState() {
    super.initState();
    fetchVendor();
    fetchProducts();
  }

  @override
  void dispose() {
    _searchOverlay?.remove();
    _searchController.dispose();
    super.dispose();
  }

  void _showSearchOverlay(String query) {
    // Remove previous overlay if exists
    _searchOverlay?.remove();
    _searchOverlay = null;

    if (query.isEmpty) return;

    final filteredProducts = allProducts.where((p) {
      return p["name"].toString().toLowerCase().contains(query.toLowerCase());
    }).toList();

    _searchOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 24, // match padding
        child: CompositedTransformFollower(
          link: _searchLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60), // height of the TextField + margin
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: filteredProducts.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "No results found",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: filteredProducts.length,
                      itemBuilder: (ctx, idx) {
                        final p = filteredProducts[idx];
                        return ListTile(
                          title: Text(p["name"]),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            _searchController.clear();
                            _searchOverlay?.remove();
                            _searchOverlay = null;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsPage(product: p),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_searchOverlay!);
  }

  Future<void> fetchVendor() async {
    try {
      final res = await getVendorById(widget.vendorId);
      setState(() => vendor = res);
    } catch (e) {
      setState(() => vendor = null);
    }
  }

  Future<void> fetchProducts() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await getVendorProductsGrouped(widget.vendorId);
      final cart = await CartService.getCart();
      if (cart.isNotEmpty) {
        final firstEntry = cart.entries.first;
        final product = await ProductService.getProductById(firstEntry.key);
        if (product != null) {
          cartVendorId = product["vendorId"];
        } else {
          cartVendorId = null;
        }
      }
      final tempProducts = <Map<String, dynamic>>[];
      for (final category in res.keys) {
        final subcats = res[category] as Map;
        for (final subcatName in subcats.keys) {
          final products = subcats[subcatName] as List;
          for (final p in products) {
            tempProducts.add(p);
          }
        }
      }
      setState(() => allProducts = tempProducts);
      setState(() {
        groupedProducts = res;
        quantities = {};
        _categoryKeys.clear();

        // Create keys for each category
        for (final category in res.keys) {
          _categoryKeys[category] = GlobalKey();
        }

        // Initialize quantities from cart (default 0 if not in cart)
        for (final subcats in res.values) {
          for (final products in (subcats as Map).values) {
            for (final p in products) {
              quantities[p["id"]] = cart[p["id"]] ?? 0;
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        groupedProducts = {};
        error = "Failed to load products. Please try again later.";
      });
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> handleQuantityChange(int productId, int delta) async {
    setState(() => cartUpdating = true);

    final current = quantities[productId] ?? 0;
    var newQty = current + delta;
    if (newQty < 0) newQty = 0;

    try {
      // 🔒 Block if cart has items from another vendor
      if (delta > 0 &&
          cartVendorId != null &&
          cartVendorId != widget.vendorId) {
        setState(() => cartUpdating = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "You can only order from one vendor at a time. Please clear your cart first.",
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return; // stop here
      }

      // Normal add/update
      if (current == 0 && delta > 0) {
        await CartService.addToCart(productId, 1);
        cartVendorId = widget.vendorId; // ✅ lock cart to this vendor
      } else {
        await CartService.updateCartItem(productId, newQty);
      }

      // Refresh local cart state
      final updatedCart = await CartService.getCart();
      setState(() {
        quantities[productId] = newQty;
        if (updatedCart.isEmpty) {
          cartVendorId = null; // reset if cart cleared
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppMessages.cartError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => cartUpdating = false);
    }
  }

  void _showCategoryMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.5, // shows half the screen initially
            minChildSize: 0.4,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    const Text(
                      "Menu",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scrollable list
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: groupedProducts.entries.expand((
                          categoryEntry,
                        ) {
                          final categoryName = categoryEntry.key;
                          final subcats = categoryEntry.value as Map;

                          return subcats.keys.map((subcatName) {
                            final itemCount =
                                (subcats[subcatName] as List).length;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  _scrollToSubcategory(
                                    categoryName,
                                    subcatName,
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            avatarColors[subcats.keys
                                                    .toList()
                                                    .indexOf(subcatName) %
                                                avatarColors.length],
                                        child: Text(
                                          subcatName[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              subcatName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "$itemCount items",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          });
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _scrollToSubcategory(String category, String subcat) {
    final key = _subcategoryKeys["$category|$subcat"];
    if (key != null) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(body: Center(child: Text(error!)));
    }
    if (groupedProducts.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No products found for this vendor")),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(vendor?["companyName"] ?? "Vendor"),
            elevation: 4,
            centerTitle: true,
          ),
          body: ListView(
            controller: _scrollController,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: CompositedTransformTarget(
                  link: _searchLink,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search products...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (query) {
                      if (query.isNotEmpty)
                        _showSearchOverlay(query);
                      else {
                        // Remove overlay if text is empty
                        _searchOverlay?.remove();
                        _searchOverlay = null;
                      }
                    },
                  ),
                ),
              ),

              if (_searchController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: allProducts
                        .where((p) {
                          final matchesSearch = p["name"]
                              .toString()
                              .toLowerCase()
                              .contains(_searchController.text.toLowerCase());

                          final matchesFilter =
                              (filterType == "veg" && p["veg"] == true) ||
                              (filterType == "nonveg" && p["veg"] == false) ||
                              (filterType == "all");

                          return matchesSearch && matchesFilter;
                        })
                        .map(
                          (p) => InkWell(
                            onTap: () {
                              _searchController.clear();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailsPage(product: p),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(child: Text(p["name"])),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (vendor != null)
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 255, 207, 111),
                          Colors.white,
                          Colors.white,
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        // Optional: floating icons in background
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Icon(
                            Icons.local_grocery_store,
                            size: 40,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vendor image
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Colors.white,
                                  child: vendor?["profileImageUrl"] != null
                                      ? ClipOval(
                                          child: Image.network(
                                            vendor!["profileImageUrl"],
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.store,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                ),
                                // Open badge
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      "Open Now",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vendor?["companyName"] ?? "Restaurant",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          vendor?["city"] ?? "City",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "30 - 40 Mins",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ChoiceChip(
                      label: Row(
                        children: const [
                          Icon(Icons.circle, color: Colors.green, size: 12),
                          SizedBox(width: 6),
                          Text("Veg"),
                        ],
                      ),
                      selected: filterType == "veg",
                      onSelected: (selected) {
                        setState(() => filterType = selected ? "veg" : "all");
                      },
                      selectedColor: Colors.green.shade100,
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: Row(
                        children: const [
                          Icon(Icons.circle, color: Colors.red, size: 12),
                          SizedBox(width: 6),
                          Text("Non-Veg"),
                        ],
                      ),
                      selected: filterType == "nonveg",
                      onSelected: (selected) {
                        setState(
                          () => filterType = selected ? "nonveg" : "all",
                        );
                      },
                      selectedColor: Colors.red.shade100,
                    ),
                  ],
                ),
              ),

              // Product Categories and Products
              ...groupedProducts.entries.map((categoryEntry) {
                final categoryName = categoryEntry.key;
                final subcats = categoryEntry.value as Map;

                return Padding(
                  key: _categoryKeys[categoryName],
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...subcats.entries.map((subEntry) {
                        final subcatName = subEntry.key;
                        final products = (subEntry.value as List).where((p) {
                          if (filterType == "veg") return p["veg"] == true;
                          if (filterType == "nonveg") return p["veg"] == false;
                          return true; // all
                        }).toList();
                        final subcatKey = "$categoryName|$subcatName";

                        _subcategoryKeys[subcatKey] ??= GlobalKey();

                        return Padding(
                          key: _subcategoryKeys[subcatKey],
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subcatName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(
                                height: 270,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: products.length,
                                  itemBuilder: (ctx, idx) {
                                    final product = products[idx];
                                    final qty = quantities[product["id"]] ?? 0;

                                    return ProductCard(
                                      product: product,
                                      quantity: qty,
                                      onQuantityChange: handleQuantityChange,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showCategoryMenu,
            label: Text("Menu", style: TextStyle(color: Colors.white)),
            icon: const Icon(Icons.menu, color: Colors.white),
            backgroundColor: Colors.green.shade700,
          ),
        ),

        // Full-screen loading overlay when cart is updating
        if (cartUpdating)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
