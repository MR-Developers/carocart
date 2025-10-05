import 'package:carocart/Apis/Vendors/vendor_products.dart';
import 'package:carocart/Vendor/Vendor_Add_Product_Wrapper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorProducts extends StatefulWidget {
  const VendorProducts({super.key});

  @override
  State<VendorProducts> createState() => _VendorProductsState();
}

class _VendorProductsState extends State<VendorProducts> {
  // Olive Green Color Palette
  static const Color oliveGreenPrimary = Color(
    0xFF273E06,
  ); // equivalent to Colors.green[700];
  static const Color oliveGreenDark = Color(0xFF556B2F);
  static const Color oliveGreenLight = Color(0xFF9ACD32);
  static const Color oliveGreenPale = Color(0xFFF5F8F0);
  static const Color oliveGreenAccent = Color(0xFF808000);

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filtered = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subCategories = [];

  String query = "";
  String? selectedCat;
  String? selectedSub;

  bool loading = true;
  bool loadingSub = false;

  String token = "";

  @override
  void initState() {
    super.initState();
    _loadTokenAndData();
  }

  Future<void> _loadTokenAndData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("auth_token") ?? "";

    try {
      final cats = await VendorProductsApi.getAllCategories();
      final prods = await VendorProductsApi.getMyProducts(token);
      setState(() {
        categories = cats;
        products = prods;
        filtered = prods;
      });
    } catch (e) {
      setState(() {
        products = [];
        filtered = [];
      });
    } finally {
      setState(() => loading = false);
    }
  }

  void _filterProducts() {
    setState(() {
      filtered = products.where((p) {
        final matchesQuery =
            query.isEmpty ||
            (p['name']?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (p['brand']?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (p['description']?.toLowerCase().contains(query.toLowerCase()) ??
                false);

        final matchesCat =
            selectedCat == null ||
            (p['categoryId']?.toString() == selectedCat ||
                p['category']?['id']?.toString() == selectedCat);

        final matchesSub =
            selectedSub == null ||
            (p['subCategoryId']?.toString() == selectedSub ||
                p['subCategory']?['id']?.toString() == selectedSub);

        return matchesQuery && matchesCat && matchesSub;
      }).toList();
    });
  }

  Future<void> _onCatChanged(String? value) async {
    setState(() {
      selectedCat = value;
      selectedSub = null;
      subCategories = [];
      loadingSub = true;
    });
    if (value != null) {
      try {
        final subs = await VendorProductsApi.getSubCategoriesByCategoryId(
          value,
        );
        setState(() => subCategories = subs);
      } catch (_) {}
    }
    setState(() => loadingSub = false);
    _filterProducts();
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text("Delete Product"),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this product? This action cannot be undone.",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: oliveGreenDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await VendorProductsApi.deleteProduct(productId, token);
        setState(() {
          products.removeWhere((p) => p['id'] == productId);
          filtered.removeWhere((p) => p['id'] == productId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Product deleted successfully"),
                ],
              ),
              backgroundColor: oliveGreenPrimary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Failed to delete product"),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: oliveGreenPale,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: oliveGreenPrimary,
        title: const Text(
          "My Products",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: oliveGreenDark, height: 2),
        ),
      ),
      body: Column(
        children: [
          // Search and Filters Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: oliveGreenPale,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: oliveGreenLight.withOpacity(0.3)),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: oliveGreenDark),
                      hintText: "Search products...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (v) {
                      query = v;
                      _filterProducts();
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips Row
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterChip(
                        label: selectedCat == null
                            ? "Category"
                            : categories.firstWhere(
                                    (c) => c['id'].toString() == selectedCat,
                                    orElse: () => {'name': 'Category'},
                                  )['name'] ??
                                  "Category",
                        icon: Icons.category_outlined,
                        onTap: () => _showCategoryPicker(),
                        isSelected: selectedCat != null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterChip(
                        label: selectedSub == null
                            ? "Subcategory"
                            : subCategories.firstWhere(
                                    (s) => s['id'].toString() == selectedSub,
                                    orElse: () => {'name': 'Subcategory'},
                                  )['name'] ??
                                  "Subcategory",
                        icon: Icons.filter_list,
                        onTap: selectedCat == null
                            ? null
                            : () => _showSubcategoryPicker(),
                        isSelected: selectedSub != null,
                        isDisabled: selectedCat == null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results Count
          if (!loading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${filtered.length} ${filtered.length == 1 ? 'Product' : 'Products'}",
                    style: TextStyle(
                      fontSize: 15,
                      color: oliveGreenDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (selectedCat != null ||
                      selectedSub != null ||
                      query.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          query = "";
                          selectedCat = null;
                          selectedSub = null;
                          subCategories = [];
                        });
                        _filterProducts();
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text("Clear"),
                      style: TextButton.styleFrom(
                        foregroundColor: oliveGreenPrimary,
                      ),
                    ),
                ],
              ),
            ),

          // Products List
          Expanded(
            child: loading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: oliveGreenPrimary,
                    ),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: oliveGreenLight.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No products found",
                          style: TextStyle(
                            fontSize: 18,
                            color: oliveGreenDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try adjusting your filters",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return _buildProductCard(p);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VendorAddProductWrapper()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
        backgroundColor: oliveGreenPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool isSelected = false,
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? oliveGreenPrimary.withOpacity(0.15)
              : (isDisabled ? Colors.grey[100] : oliveGreenPale),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? oliveGreenPrimary
                : (isDisabled
                      ? Colors.grey[300]!
                      : oliveGreenLight.withOpacity(0.4)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? oliveGreenDark
                  : (isDisabled ? Colors.grey[400] : oliveGreenAccent),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? oliveGreenDark
                      : (isDisabled ? Colors.grey[400] : oliveGreenDark),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: oliveGreenLight.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Product Image ---
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 95,
                height: 95,
                color: oliveGreenPale,
                child: p['imageUrl'] != null && p['imageUrl'].isNotEmpty
                    ? Image.network(
                        p['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.broken_image_outlined,
                          color: oliveGreenAccent,
                          size: 32,
                        ),
                      )
                    : Icon(
                        Icons.image_outlined,
                        color: oliveGreenAccent,
                        size: 32,
                      ),
              ),
            ),

            const SizedBox(width: 14),

            // --- Product Info ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Actions row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p['name'] ?? "Unnamed Product",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: oliveGreenDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          _actionChip(
                            icon: Icons.edit_outlined,
                            color: oliveGreenDark,
                            onTap: () {
                              // TODO: edit
                            },
                          ),
                          SizedBox(width: 6),
                          _actionChip(
                            icon: Icons.delete_outline,
                            color: Colors.red[400]!,
                            onTap: () => _deleteProduct(p['id'].toString()),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Price + MRP line
                  Row(
                    children: [
                      Text(
                        "₹${p['price'] ?? 0}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: oliveGreenDark,
                        ),
                      ),
                      if (p['mrp'] != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          "₹${p['mrp']}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Stock + Category
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (p['stock'] != null) _infoChip("Stock: ${p['stock']}"),
                      if (p['category'] != null)
                        _infoChip("Category: ${p['category']}"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// --- Mini action button ---
  Widget _actionChip({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  /// --- Info chip (stock/category labels) ---
  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [oliveGreenPale, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: oliveGreenLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title with Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: oliveGreenPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.category_outlined,
                            color: oliveGreenDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Select Category",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: oliveGreenDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${categories.length} available",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(height: 1, color: Colors.grey[200]),

              // List Section
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // All Categories Option
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Material(
                        color: selectedCat == null
                            ? oliveGreenPrimary.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _onCatChanged(null);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedCat == null
                                    ? oliveGreenPrimary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selectedCat == null
                                        ? oliveGreenPrimary
                                        : oliveGreenPale,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.clear_all,
                                    color: selectedCat == null
                                        ? Colors.white
                                        : oliveGreenDark,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "All Categories",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: selectedCat == null
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: selectedCat == null
                                          ? oliveGreenDark
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                                if (selectedCat == null)
                                  Icon(
                                    Icons.check_circle,
                                    color: oliveGreenPrimary,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Categories List
                    ...categories.map((c) {
                      final isSelected = selectedCat == c['id'].toString();
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Material(
                          color: isSelected
                              ? oliveGreenPrimary.withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _onCatChanged(c['id'].toString());
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? oliveGreenPrimary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? oliveGreenPrimary
                                          : oliveGreenPale,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        c['name'].isNotEmpty
                                            ? c['name'][0].toUpperCase()
                                            : "?",
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : oliveGreenAccent,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      c['name'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? oliveGreenDark
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: oliveGreenPrimary,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubcategoryPicker() {
    if (loadingSub) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [oliveGreenPale, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: oliveGreenLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title with Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: oliveGreenPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.filter_alt_outlined,
                            color: oliveGreenDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Select Subcategory",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: oliveGreenDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${subCategories.length} available",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(height: 1, color: Colors.grey[200]),

              // List Section
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // All Subcategories Option
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Material(
                        color: selectedSub == null
                            ? oliveGreenPrimary.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            setState(() => selectedSub = null);
                            _filterProducts();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedSub == null
                                    ? oliveGreenPrimary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selectedSub == null
                                        ? oliveGreenPrimary
                                        : oliveGreenPale,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.clear_all,
                                    color: selectedSub == null
                                        ? Colors.white
                                        : oliveGreenDark,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "All Subcategories",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: selectedSub == null
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: selectedSub == null
                                          ? oliveGreenDark
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                                if (selectedSub == null)
                                  Icon(
                                    Icons.check_circle,
                                    color: oliveGreenPrimary,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subcategories List
                    ...subCategories.map((s) {
                      final isSelected = selectedSub == s['id'].toString();
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Material(
                          color: isSelected
                              ? oliveGreenPrimary.withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => selectedSub = s['id'].toString());
                              _filterProducts();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? oliveGreenPrimary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? oliveGreenPrimary
                                          : oliveGreenPale,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        s['name'].isNotEmpty
                                            ? s['name'][0].toUpperCase()
                                            : "?",
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : oliveGreenAccent,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      s['name'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? oliveGreenDark
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: oliveGreenPrimary,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
