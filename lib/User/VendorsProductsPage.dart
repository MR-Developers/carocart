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
  @override
  void initState() {
    super.initState();
    fetchVendor();
    fetchProducts();
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
      if (cart.length != 0) {
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  "Menu",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Scrollable list of subcategories
                Expanded(
                  child: ListView(
                    children: groupedProducts.entries.expand((categoryEntry) {
                      final categoryName = categoryEntry.key;
                      final subcats = categoryEntry.value as Map;

                      return subcats.keys.map((subcatName) {
                        final itemCount = (subcats[subcatName] as List).length;

                        return Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                subcatName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                "$itemCount items",
                                style: const TextStyle(fontSize: 13),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _scrollToSubcategory(categoryName, subcatName);
                              },
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const Divider(
                              height: 1,
                            ), // 👈 Divider after every tile
                          ],
                        );
                      });
                    }).toList(),
                  ),
                ),
              ],
            ),
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
                    setState(() {}); // refresh search suggestions
                  },
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
                        .where(
                          (p) => p["name"].toString().toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          ),
                        )
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
                  margin: const EdgeInsets.all(12),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (vendor?["profileImageUrl"] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              vendor!["profileImageUrl"],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.store,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendor?["companyName"] ?? "Restaurant",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (vendor?["city"] != null)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        vendor!["city"],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
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
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "30 - 40 Mins",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...subcats.entries.map((subEntry) {
                        final subcatName = subEntry.key;
                        final products = subEntry.value as List;
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
