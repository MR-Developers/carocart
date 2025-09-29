import 'package:carocart/Apis/home_api.dart';
import 'package:carocart/Utils/delivery_fee.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carocart/Apis/address_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:carocart/Apis/cart_service.dart';

// Example CartItem model (adjust to match your app's model)
class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });
}

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage>
    with SingleTickerProviderStateMixin {
  String deliveryAddress = "Fetching address...";
  String deliveryTime = "Calculating...";
  CartItem? cartItem;
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDeliveryInfo();
    _checkIfInCart();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfInCart() async {
    try {
      setState(() => isLoading = true);

      final Map<int, int> cartMap =
          await CartService.getCart() as Map<int, int>? ?? {};

      final int productId = widget.product["id"] as int;

      if (cartMap.containsKey(productId)) {
        final int quantity = cartMap[productId] ?? 0;

        setState(() {
          cartItem = CartItem(
            id: productId.toString(),
            name: widget.product["name"],
            price: (widget.product["price"] as num).toDouble(),
            quantity: quantity,
          );
        });
      }
    } catch (e) {
      print("❌ Failed to check cart: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadDeliveryInfo() async {
    try {
      final addresses = await AddressService.getMyAddresses(context);
      final defaultAddress = addresses.firstWhere(
        (a) => a["isDefault"] == true,
        orElse: () =>
            addresses.isNotEmpty ? addresses.first : <String, dynamic>{},
      );

      setState(() {
        deliveryAddress = defaultAddress["address"] ?? "Address not available";
      });

      final userLat = defaultAddress["latitude"];
      final userLng = defaultAddress["longitude"];
      double? vendorLat;
      double? vendorLng;

      final product = widget.product;
      final vendor = await getVendorById(product["vendorId"]);
      vendorLat ??= vendor["latitude"];
      vendorLng ??= vendor["longitude"];

      if (vendorLat != null &&
          vendorLng != null &&
          userLat != null &&
          userLng != null) {
        final distance = haversineKm(vendorLat, vendorLng, userLat, userLng);
        final estimatedMinutes = (distance / 10 * 30).round().clamp(15, 120);
        setState(() {
          deliveryTime = "Delivered within $estimatedMinutes minutes";
        });
      } else {
        setState(() {
          deliveryTime = "Delivery time unavailable";
        });
      }
    } catch (e) {
      setState(() {
        deliveryAddress = "Unable to fetch address";
        deliveryTime = "Delivery time unavailable";
      });
    }
  }

  Future<void> _changeQuantity(CartItem item, int delta) async {
    HapticFeedback.lightImpact();
    final newQuantity = (item.quantity + delta).clamp(0, 99);

    setState(() {
      item.quantity = newQuantity;
      if (newQuantity == 0) {
        cartItem = null;
      }
    });

    try {
      setState(() => isLoading = true);

      if (newQuantity > 0) {
        await CartService.updateCartItem(int.parse(item.id), newQuantity);
      } else {
        await CartService.updateCartItem(int.parse(item.id), 0);
      }

      await CartService.getCart();
    } catch (e) {
      print("❌ Failed to update quantity: $e");
      _showErrorSnackBar("Failed to update cart item");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double? mrp = widget.product["mrp"]?.toDouble();
    double? price = widget.product["price"]?.toDouble();

    int? discountPercent;
    if (mrp != null && price != null && mrp > price) {
      discountPercent = (((mrp - price) / mrp) * 100).round();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
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
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductImage(),
                _buildProductInfo(price, mrp, discountPercent),
                _buildDeliverySection(),
                _buildDescriptionSection(),
                const SizedBox(height: 140), // Space for bottom bar
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Stack(
          children: [
            widget.product["imageUrl"] != null
                ? Hero(
                    tag: "product-${widget.product["id"]}",
                    child: Image.network(
                      widget.product["imageUrl"],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                            strokeWidth: 3,
                            color: const Color(0xFF6366F1),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    ),
                  )
                : _buildImagePlaceholder(),
            // Gradient overlay for better text visibility
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 80, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildProductInfo(double? price, double? mrp, int? discountPercent) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product["name"] ?? "",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildRatingSection(),
          const SizedBox(height: 20),
          _buildPriceSection(price, mrp, discountPercent),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    final rating = (widget.product["avgRating"]?.toDouble() ?? 0);
    final ratingCount = widget.product["ratingCount"] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          RatingBarIndicator(
            rating: rating,
            itemBuilder: (context, index) =>
                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24)),
            itemCount: 5,
            itemSize: 20.0,
            direction: Axis.horizontal,
          ),
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "($ratingCount reviews)",
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(double? price, double? mrp, int? discountPercent) {
    return Row(
      children: [
        if (mrp != null && discountPercent != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "-$discountPercent%",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (discountPercent != null) const SizedBox(width: 8),
        if (mrp != null)
          Text(
            "₹$mrp",
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF9CA3AF),
              decoration: TextDecoration.lineThrough,
            ),
          ),
        if (mrp != null) const SizedBox(width: 8),
        Text(
          "₹${price ?? ""}",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDeliveryInfoRow(
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFF10B981),
            title: "Delivery Address",
            subtitle: deliveryAddress,
            action: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // TODO: Change address
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
              child: const Text(
                "Change",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),
          _buildDeliveryInfoRow(
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: "Delivery Time",
            subtitle: deliveryTime,
            trailing: const Icon(
              Icons.info_outline,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? action,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        if (action != null) action,
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Product Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.product["description"] ?? "No description available",
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              )
            : cartItem == null
            ? _buildAddToCartButton()
            : _buildCartControls(),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            HapticFeedback.mediumImpact();

            final newItem = CartItem(
              id: widget.product["id"].toString(),
              name: widget.product["name"],
              price: widget.product["price"]?.toDouble() ?? 0,
              quantity: 1,
            );

            setState(() => cartItem = newItem);

            try {
              await CartService.updateCartItem(int.parse(newItem.id), 1);
              await CartService.getCart();
              _showSuccessSnackBar("Added to cart!");
            } catch (e) {
              print("❌ Failed to add to cart: $e");
              setState(() => cartItem = null);
              _showErrorSnackBar("Failed to add item to cart");
            }
          },
          child: const Center(
            child: Text(
              "Add To Cart",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartControls() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "In Cart",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildQuantityControls(),
                  const SizedBox(width: 16),
                  Text(
                    "₹${(cartItem!.price * cartItem!.quantity).toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildGoToCartButton(),
      ],
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onTap: () => _changeQuantity(cartItem!, -1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "${cartItem!.quantity}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onTap: () => _changeQuantity(cartItem!, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF374151)),
      ),
    );
  }

  Widget _buildGoToCartButton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, "/usercart");
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "View Cart",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
