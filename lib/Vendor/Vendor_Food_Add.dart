import 'dart:io';
import 'package:carocart/Apis/delivery.Person.dart';
import 'package:carocart/Utils/generatefirebasepath.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carocart/Apis/Vendors/vendor_products.dart';

class VendorFoodAddProduct extends StatefulWidget {
  final Map<String, dynamic> vendor;

  const VendorFoodAddProduct({super.key, required this.vendor});

  @override
  State<VendorFoodAddProduct> createState() => _VendorFoodAddProductState();
}

class _VendorFoodAddProductState extends State<VendorFoodAddProduct> {
  final _formKey = GlobalKey<FormState>();
  final int maxDescLength = 200;

  // Form fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitController = TextEditingController(text: "Plate");
  final _foodCategoryController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  final _customizationController = TextEditingController();
  final _addOnsController = TextEditingController();

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subcategories = [];
  String? selectedCategoryId;
  String? selectedSubCategoryId;

  bool isVeg = true;
  bool isBestseller = false;
  bool isAvailable = true;
  bool uploading = false;
  bool isSubmitting = false;

  String? imageUrl;
  File? imageFile;
  String? message;
  String token = "";

  double get computedDiscount {
    final price = double.tryParse(_priceController.text) ?? 0;
    final mrp = double.tryParse(_mrpController.text) ?? 0;
    if (mrp > 0 && price >= 0 && mrp > price) {
      return ((mrp - price) / mrp) * 100;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _restaurantNameController.text = widget.vendor['companyName'] ?? "";
    _loadTokenAndCategories();
  }

  Future<void> _loadTokenAndCategories() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("auth_token") ?? "";

    try {
      final cats = await VendorProductsApi.getAllCategories();
      setState(() => categories = cats);
    } catch (e) {
      _showMessage("Failed to load categories", isError: true);
    }
  }

  Future<void> _onCategoryChanged(String? categoryId) async {
    setState(() {
      selectedCategoryId = categoryId;
      selectedSubCategoryId = null;
      subcategories = [];
    });

    if (categoryId != null) {
      try {
        final subs = await VendorProductsApi.getSubCategoriesByCategoryId(
          categoryId,
        );
        setState(() => subcategories = subs);
      } catch (e) {
        _showMessage("Failed to load subcategories", isError: true);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileSize = await file.length();

    if (fileSize > 3 * 1024 * 1024) {
      _showMessage("Image must be ≤ 3MB", isError: true);
      return;
    }

    setState(() {
      imageFile = file;
      uploading = true;
    });

    try {
      var path = generateFirebasePath("products", pickedFile.path);
      final response = await uploadFile(
        context: context,
        filePath: pickedFile.path,
        folder: path,
      );
      setState(() {
        imageUrl = response["data"];
        uploading = false;
      });
      _showMessage("Image uploaded successfully!");
    } catch (e) {
      setState(() {
        imageFile = null;
        uploading = false;
      });
      _showMessage("Image upload failed", isError: true);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    setState(() => message = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (imageUrl == null) {
      _showMessage("Please upload a product image", isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    final payload = {
      "name": _nameController.text.trim(),
      "description": _descriptionController.text.trim(),
      "price": double.parse(_priceController.text),
      "mrp": double.parse(_mrpController.text),
      "discount": double.parse(computedDiscount.toStringAsFixed(2)),
      "stock": int.parse(_stockController.text),
      "unit": _unitController.text.trim(),
      "isAvailable": isAvailable,
      "imageUrl": imageUrl,
      "subCategoryId": selectedSubCategoryId,
      "categoryId": selectedCategoryId,
      "productType": "FOOD",
      "foodCategory": _foodCategoryController.text.trim(),
      "veg": isVeg,
      "restaurantName": _restaurantNameController.text.trim(),
      "customizationOptions": _customizationController.text.trim(),
      "addOns": _addOnsController.text.trim(),
      "bestseller": isBestseller,
    };

    try {
      await VendorProductsApi.addProduct(payload, token);
      _showMessage("Product added successfully!");

      // Wait a moment then pop
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showMessage("Failed to add product: $e", isError: true);
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Add Food Item",
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Upload Section
            _buildImageUploadSection(),
            const SizedBox(height: 24),

            // Name + Veg/Non-Veg + Bestseller
            _buildNameAndBadges(),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: "Description",
              hint: "Short description (max $maxDescLength chars)",
              maxLines: 3,
              maxLength: maxDescLength,
              validator: (v) => v == null || v.trim().isEmpty
                  ? "Description is required"
                  : null,
            ),
            const SizedBox(height: 16),

            // Food Category + Unit
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _foodCategoryController,
                    label: "Menu Section",
                    hint: "e.g., Biryani, Starters",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _unitController,
                    label: "Unit",
                    hint: "e.g., Plate, Bowl",
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? "Unit required" : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price, MRP, Discount
            _buildPricingSection(),
            const SizedBox(height: 16),

            // Stock
            _buildTextField(
              controller: _stockController,
              label: "Stock",
              hint: "Available units",
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return "Stock required";
                if (int.tryParse(v) == null) return "Invalid stock";
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            _buildCategoryDropdown(),
            const SizedBox(height: 16),

            // Subcategory
            _buildSubcategoryDropdown(),
            const SizedBox(height: 16),

            // Restaurant Name
            _buildTextField(
              controller: _restaurantNameController,
              label: "Restaurant Name",
              hint: "Your restaurant",
              validator: (v) => v == null || v.trim().isEmpty
                  ? "Restaurant name required"
                  : null,
            ),
            const SizedBox(height: 16),

            // Customizations
            _buildTextField(
              controller: _customizationController,
              label: "Customizations (Optional)",
              hint: "e.g., Less Spicy, Extra Raita",
            ),
            const SizedBox(height: 16),

            // Add-ons
            _buildTextField(
              controller: _addOnsController,
              label: "Add-ons (Optional)",
              hint: "e.g., Papad, Salad",
            ),
            const SizedBox(height: 16),

            // Available Toggle
            _buildAvailabilitySwitch(),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSubmitting || uploading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Add Food Item",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Product Image",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: uploading ? null : _pickImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: uploading
                  ? const Center(child: CircularProgressIndicator())
                  : imageFile != null || imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageFile != null
                          ? Image.file(imageFile!, fit: BoxFit.cover)
                          : Image.network(imageUrl!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap to upload image",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameAndBadges() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Item Name",
              hintText: "e.g., Chicken Biryani",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? "Name required" : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildVegSwitch()),
              const SizedBox(width: 12),
              Expanded(child: _buildBestsellerSwitch()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVegSwitch() {
    return InkWell(
      onTap: () => setState(() => isVeg = !isVeg),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isVeg
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isVeg ? Colors.green : Colors.red),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVeg ? Icons.eco : Icons.whatshot,
              size: 18,
              color: isVeg ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 6),
            Text(
              isVeg ? "Veg" : "Non-Veg",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isVeg ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestsellerSwitch() {
    return InkWell(
      onTap: () => setState(() => isBestseller = !isBestseller),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isBestseller
              ? Colors.amber.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBestseller ? Colors.amber : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              size: 18,
              color: isBestseller ? Colors.amber : Colors.grey[400],
            ),
            const SizedBox(width: 6),
            Text(
              "Bestseller",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isBestseller ? Colors.amber[800] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pricing",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: "Price (₹)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Required";
                    final price = double.tryParse(v);
                    if (price == null || price < 0) return "Invalid";
                    final mrp = double.tryParse(_mrpController.text);
                    if (mrp != null && price > mrp) return "Price > MRP";
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _mrpController,
                  decoration: InputDecoration(
                    labelText: "MRP (₹)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Required";
                    if (double.tryParse(v) == null) return "Invalid";
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Discount",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "${computedDiscount.toStringAsFixed(2)}%",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        value: selectedCategoryId,
        decoration: InputDecoration(
          labelText: "Category",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: categories.map((c) {
          return DropdownMenuItem(
            value: c['id'].toString(),
            child: Text(c['name']),
          );
        }).toList(),
        onChanged: _onCategoryChanged,
        validator: (v) => v == null ? "Please select a category" : null,
      ),
    );
  }

  Widget _buildSubcategoryDropdown() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        value: selectedSubCategoryId,
        decoration: InputDecoration(
          labelText: "Subcategory",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: subcategories.map((s) {
          return DropdownMenuItem(
            value: s['id'].toString(),
            child: Text(s['name']),
          );
        }).toList(),
        onChanged: (v) => setState(() => selectedSubCategoryId = v),
        validator: (v) => v == null ? "Please select a subcategory" : null,
      ),
    );
  }

  Widget _buildAvailabilitySwitch() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Product Available",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: (v) => setState(() => isAvailable = v),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          counterText: maxLength != null ? null : "",
        ),
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    _foodCategoryController.dispose();
    _restaurantNameController.dispose();
    _customizationController.dispose();
    _addOnsController.dispose();
    super.dispose();
  }
}
