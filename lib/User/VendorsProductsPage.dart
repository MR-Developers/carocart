import 'package:carocart/Apis/cart_service.dart';
import 'package:carocart/Apis/home_api.dart';
import 'package:carocart/Apis/product_service.dart';
import 'package:carocart/User/ProductDetails.dart';
import 'package:carocart/Utils/Messages.dart';
import 'package:carocart/Utils/UserCards/ProductCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VendorProductsPage extends StatefulWidget {
  final int vendorId;

  const VendorProductsPage({super.key, required this.vendorId});

  @override
  State<VendorProductsPage> createState() => _VendorProductsPageState();
}

class _VendorProductsPageState extends State<VendorProductsPage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? vendor;
  Map<String, dynamic> groupedProducts = {};
  final Map<String, GlobalKey> _subcategoryKeys = {};
  final List<Color> avatarColors = [
    Colors.green.shade400,
    Colors.blue.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
  ];
  Map<int, int> quantities = {};
  bool loading = true;
  bool cartUpdating = false;
  int? cartVendorId;

  String? error;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  List<Map<String, dynamic>> allProducts = [];
  String filterType = "all";

  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabScaleAnimation;

  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    fetchVendor();
    fetchProducts();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();
    _fabAnimationController.forward();
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchExpanded = _searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

        for (final category in res.keys) {
          _categoryKeys[category] = GlobalKey();
        }

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
    HapticFeedback.lightImpact();
    setState(() => cartUpdating = true);

    final current = quantities[productId] ?? 0;
    var newQty = current + delta;
    if (newQty < 0) newQty = 0;

    try {
      if (delta > 0 &&
          cartVendorId != null &&
          cartVendorId != widget.vendorId) {
        setState(() => cartUpdating = false);
        _showErrorMessage(
          "You can only order from one vendor at a time. Please clear your cart first.",
        );
        return;
      }

      if (current == 0 && delta > 0) {
        await CartService.addToCart(productId, 1);
        cartVendorId = widget.vendorId;
      } else {
        await CartService.updateCartItem(productId, newQty);
      }

      final updatedCart = await CartService.getCart();
      setState(() {
        quantities[productId] = newQty;
        if (updatedCart.isEmpty) {
          cartVendorId = null;
        }
      });
    } catch (e) {
      _showErrorMessage(AppMessages.cartError);
    } finally {
      setState(() => cartUpdating = false);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showCategoryMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
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
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF10B981),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (groupedProducts.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(
          child: Text(
            "No products found for this vendor",
            style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildSliverAppBar(),
                  _buildSearchSection(),
                  _buildVendorInfoSection(),
                  _buildFilterSection(),
                  _buildProductSections(),
                ],
              ),
            ),
          ),
          floatingActionButton: ScaleTransition(
            scale: _fabScaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF273E06), Color(0xFF1F3305)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _showCategoryMenu,
                backgroundColor: Colors.transparent,
                elevation: 0,
                label: const Text(
                  "Browse Menu",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Loading overlay
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: Color(0xFF273E06),
      foregroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        vendor?["companyName"] ?? "Vendor",
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isSearchExpanded ? 0.1 : 0.06),
                blurRadius: _isSearchExpanded ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: _isSearchExpanded
                ? Border.all(color: const Color(0xFF10B981).withOpacity(0.3))
                : null,
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: "Search delicious items...",
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _isSearchExpanded
                    ? const Color(0xFF10B981)
                    : const Color(0xFF9CA3AF),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (query) {
              setState(() {}); // Trigger rebuild for search results
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVendorInfoSection() {
    if (vendor == null)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  // Clean vendor image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: vendor?["profileImageUrl"] != null
                          ? Image.network(
                              vendor!["profileImageUrl"],
                              fit: BoxFit.cover,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.indigo.shade400,
                                    Colors.indigo.shade600,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Vendor info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                vendor?["companyName"] ?? "Restaurant Name",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                  height: 1.2,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF273E06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "OPEN",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              vendor?["city"] ?? "Location",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "25-35 mins",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Bottom info row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          vendor?["rating"]?.toString() ?? "N/A",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Free Delivery",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            _buildFilterChip(
              label: "All Items",
              icon: Icons.restaurant,
              isSelected: filterType == "all",
              onSelected: () => setState(() => filterType = "all"),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              label: "Veg",
              icon: Icons.circle,
              iconColor: Colors.green,
              isSelected: filterType == "veg",
              onSelected: () => setState(() => filterType = "veg"),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              label: "Non-Veg",
              icon: Icons.circle,
              iconColor: Colors.red,
              isSelected: filterType == "nonveg",
              onSelected: () => setState(() => filterType = "nonveg"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelected();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.orange.shade700
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (iconColor ?? const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSections() {
    final filteredProducts = _searchController.text.isNotEmpty
        ? _getFilteredProducts()
        : null;

    if (filteredProducts != null && filteredProducts.isNotEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = filteredProducts[index];
          final qty = quantities[product["id"]] ?? 0;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: ProductCard(
              product: product,
              quantity: qty,
              onQuantityChange: handleQuantityChange,
            ),
          );
        }, childCount: filteredProducts.length),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate(
        groupedProducts.entries.map((categoryEntry) {
          final categoryName = categoryEntry.key;
          final subcats = categoryEntry.value as Map;

          return Column(
            children: subcats.entries.map((subEntry) {
              final subcatName = subEntry.key;
              final products = (subEntry.value as List).where((p) {
                if (filterType == "veg") return p["veg"] == true;
                if (filterType == "nonveg") return p["veg"] == false;
                return true;
              }).toList();

              if (products.isEmpty) return const SizedBox.shrink();

              final subcatKey = "$categoryName|$subcatName";
              _subcategoryKeys[subcatKey] ??= GlobalKey();

              return Container(
                key: _subcategoryKeys[subcatKey],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        subcatName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 295,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: products.length,
                        itemBuilder: (ctx, idx) {
                          final product = products[idx];
                          final qty = quantities[product["id"]] ?? 0;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: ProductCard(
                              product: product,
                              quantity: qty,
                              onQuantityChange: handleQuantityChange,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    return allProducts.where((p) {
      final matchesSearch = p["name"].toString().toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );

      final matchesFilter =
          (filterType == "veg" && p["veg"] == true) ||
          (filterType == "nonveg" && p["veg"] == false) ||
          (filterType == "all");

      return matchesSearch && matchesFilter;
    }).toList();
  }
}
