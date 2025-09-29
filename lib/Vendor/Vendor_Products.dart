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
            child: const Text("Cancel"),
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
              backgroundColor: Colors.green,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "My Products",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search and Filters Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
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
                      color: Colors.grey[700],
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
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                ],
              ),
            ),

          // Products List
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No products found",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
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
        backgroundColor: Colors.blue,
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
              ? Colors.blue.withOpacity(0.1)
              : (isDisabled ? Colors.grey[100] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : (isDisabled ? Colors.grey[300]! : Colors.grey[300]!),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.blue
                  : (isDisabled ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.blue
                      : (isDisabled ? Colors.grey[400] : Colors.grey[700]),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Open Edit Modal/Dialog
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: p['imageUrl'] != null && p['imageUrl'].isNotEmpty
                        ? Image.network(
                            p['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                          )
                        : Icon(
                            Icons.image_outlined,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] ?? "Unnamed Product",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (p['brand'] != null && p['brand'].isNotEmpty)
                        Text(
                          p['brand'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "₹${p['price'] ?? 0}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[400],
                  onPressed: () => _deleteProduct(p['id'].toString()),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Select Category",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ListTile(
                    leading: const Icon(Icons.clear_all),
                    title: const Text("All Categories"),
                    onTap: () {
                      Navigator.pop(context);
                      _onCatChanged(null);
                    },
                  ),
                  ...categories.map(
                    (c) => ListTile(
                      leading: const Icon(Icons.category),
                      title: Text(c['name']),
                      selected: selectedCat == c['id'].toString(),
                      onTap: () {
                        Navigator.pop(context);
                        _onCatChanged(c['id'].toString());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubcategoryPicker() {
    if (loadingSub) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Select Subcategory",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ListTile(
                    leading: const Icon(Icons.clear_all),
                    title: const Text("All Subcategories"),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => selectedSub = null);
                      _filterProducts();
                    },
                  ),
                  ...subCategories.map(
                    (s) => ListTile(
                      leading: const Icon(Icons.filter_list),
                      title: Text(s['name']),
                      selected: selectedSub == s['id'].toString(),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => selectedSub = s['id'].toString());
                        _filterProducts();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
