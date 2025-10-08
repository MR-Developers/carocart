import 'package:cached_network_image/cached_network_image.dart';
import 'package:carocart/Apis/address_service.dart';
import 'package:carocart/Apis/cart_service.dart';
import 'package:carocart/Apis/home_api.dart';
import 'package:carocart/Apis/order_service.dart';
import 'package:carocart/Apis/product_service.dart';
import 'package:carocart/User/UserPagesScaffold.dart';
import 'package:carocart/Utils/CacheManager.dart';
import 'package:carocart/Utils/delivery_fee.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CartItem {
  final String id;
  final String productName;
  final String vendorName;
  final String imageUrl;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.productName,
    required this.vendorName,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
  });
}

class UserCartPage extends StatefulWidget {
  const UserCartPage({super.key});

  @override
  State<UserCartPage> createState() => _UserCartPageState();
}

class _UserCartPageState extends State<UserCartPage>
    with TickerProviderStateMixin {
  List<CartItem> cartItems = [];
  bool isClearing = false;
  bool isCheckingOut = false;
  String coupon = "";
  bool couponApplied = false;
  bool isLoading = true;
  double discount = 0.0;
  double deliveryFee = 0;
  bool deliveryAvailable = true;
  late AnimationController _shimmerController;

  double get totalPrice =>
      cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);
  bool get isMinimumOrderNotMet => totalPrice < 149;
  bool get isFreeDelivery => totalPrice > 499;
  double get couponDiscount => discount > 0 ? totalPrice * discount : 0;

  double get grandTotal =>
      (totalPrice - couponDiscount) + (deliveryAvailable ? deliveryFee : 0);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _fetchCart();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<int> getMyOrderCount() async {
    try {
      final response = await OrderService.getOrderCount();
      if (response != null) {
        if (response.data is int) {
          return response.data;
        } else if (response.data is Map && response.data['count'] != null) {
          return response.data['count'];
        }
      }
      return 0;
    } catch (e) {
      return 999999;
    }
  }

  void applyCoupon() async {
    var orderCount = await getMyOrderCount();

    if (coupon.trim().toUpperCase() == "FIRST15" &&
        !couponApplied &&
        orderCount == 0) {
      setState(() {
        discount = 0.15;
        couponApplied = true;
      });
    } else {
      setState(() {
        discount = 0;
        couponApplied = false;
      });
      Fluttertoast.showToast(
        msg: "Coupon valid only for first-time users",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void changeQuantity(CartItem item, int delta) async {
    final newQuantity = (item.quantity + delta).clamp(0, 99);

    setState(() {
      item.quantity = newQuantity;
      if (item.quantity == 0) {
        cartItems.removeWhere((ci) => ci.id == item.id);
      }
    });

    try {
      setState(() {
        isLoading = true;
      });
      if (newQuantity > 0) {
        await CartService.updateCartItem(int.parse(item.id), newQuantity);
      } else {
        await CartService.removeCartItem(int.parse(item.id));
      }
      await CartService.getCart();
      await _fetchCart();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("❌ Failed to update quantity: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update cart item")),
      );
    }
  }

  Future<void> _fetchCart() async {
    setState(() => isLoading = true);

    try {
      // ✅ Fetch user default address
      final addresses = await AddressService.getMyAddresses(context);
      final defaultAddress = addresses.firstWhere(
        (a) => a["isDefault"] == true,
        orElse: () =>
            addresses.isNotEmpty ? addresses.first : <String, dynamic>{},
      );

      final userLat = defaultAddress["latitude"];
      final userLng = defaultAddress["longitude"];

      // ✅ Fetch cart items
      final cartMap = await CartService.getCart();

      double? vendorLat;
      double? vendorLng;
      final firstEntry = cartMap.entries.first;

      // Fetch product details
      final product = await ProductService.getProductById(firstEntry.key);
      if (product != null) {
        final vendor = await getVendorById(product["vendorId"]);
        // 👇 Expect vendor info to come from API
        vendorLat ??= vendor["latitude"];
        vendorLng ??= vendor["longitude"];
      }
      final futures = cartMap.entries.map((entry) async {
        final product = await ProductService.getProductById(entry.key);
        if (product != null) {
          return CartItem(
            id: product["id"].toString(),
            productName: product["name"],
            vendorName: product["vendorName"],
            imageUrl: product["imageUrl"],
            price: product["price"].toDouble(),
            quantity: entry.value,
          );
        }
        return null;
      }).toList();

      final results = await Future.wait(futures);
      final items = results.whereType<CartItem>().toList();

      // ✅ Calculate delivery fee if vendor/user coords exist
      double? fee;
      if (vendorLat != null && vendorLng != null) {
        final d = haversineKm(vendorLat, vendorLng, userLat, userLng);
        if (totalPrice <= 499) {
          fee = feeFromDistance(d);
        } else {
          fee = 0;
        }
      }

      setState(() {
        cartItems = items;
        deliveryFee = fee ?? 0;
        deliveryAvailable = fee != null;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching cart: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void clearCart() async {
    setState(() => isClearing = true);
    await CartService.clearCart();
    setState(() {
      cartItems.clear();
      isClearing = false;
    });
  }

  void checkout() {
    Navigator.pushNamed(
      context,
      "/userpayment",
      arguments: {
        "cartItems": cartItems,
        "totalAmount": totalPrice,
        "grandTotal": grandTotal,
        "coupondiscount": couponDiscount,
        "deliveryfee": deliveryFee,
      },
    );
  }

  Widget _buildShimmerGradient({required Widget child}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  Widget _buildShimmerCartItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Image Shimmer
          _buildShimmerGradient(
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product details shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerGradient(
                  child: Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildShimmerGradient(
                  child: Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildShimmerGradient(
                  child: Container(
                    height: 32,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Price shimmer
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildShimmerGradient(
                child: Container(
                  height: 14,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildShimmerGradient(
                child: Container(
                  height: 16,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Cart items shimmer
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [_buildShimmerCartItem(), _buildShimmerCartItem()],
                ),
              ),
            ),

            // Action buttons shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerGradient(
                    child: Container(
                      height: 36,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  _buildShimmerGradient(
                    child: Container(
                      height: 36,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Coupon card shimmer
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerGradient(
                      child: Container(
                        height: 20,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildShimmerGradient(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildShimmerGradient(
                          child: Container(
                            height: 48,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Order summary shimmer
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildShimmerGradient(
                      child: Container(
                        height: 22,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildShimmerRow(),
                    _buildShimmerRow(),
                    _buildShimmerRow(),
                    const SizedBox(height: 16),
                    _buildShimmerGradient(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildShimmerGradient(
            child: Container(
              height: 14,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          _buildShimmerGradient(
            child: Container(
              height: 14,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Your Cart"),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          if (isLoading && cartItems.isEmpty)
            _buildShimmerLoader()
          else if (cartItems.isEmpty)
            _buildEmptyCart()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // 🛒 Cart items
                        Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: cartItems.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index != cartItems.length - 1
                                        ? 14
                                        : 0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Product Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: CachedNetworkImage(
                                          imageUrl: item.imageUrl,
                                          cacheManager: MyCacheManager(),
                                          width: 65,
                                          height: 65,
                                          fit: BoxFit.cover,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Product details + Quantity
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.vendorName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),

                                            // Quantity Selector
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () => changeQuantity(
                                                      item,
                                                      -1,
                                                    ),
                                                    child: const Icon(
                                                      Icons.remove,
                                                      size: 18,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                    child: Text(
                                                      item.quantity.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        changeQuantity(item, 1),
                                                    child: const Icon(
                                                      Icons.add,
                                                      size: 18,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Price on the right
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          // Old Price (strikethrough)
                                          Text(
                                            "₹${((item.price * 1.05) * item.quantity).toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(height: 4),

                                          // New Discounted Price
                                          Text(
                                            "₹${((item.price) * item.quantity).toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF273E06),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        // 🧹 Clear / Add More
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.add,
                                size: 20,
                                color: Color(0xFF273E06),
                              ),
                              label: const Text(
                                "Add More items",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF273E06),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: isClearing ? null : clearCart,
                              icon: isClearing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.red,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                              label: const Text(
                                "Clear Cart",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // 🎟 Coupon
                        Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.local_offer,
                                      color: Color(0xFF273E06),
                                      size: 22,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Apply Coupon",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Coupon input box
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(
                                          hintText: "Enter coupon code",
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 14,
                                                horizontal: 12,
                                              ),
                                          filled: true,
                                          fillColor: Colors.green.shade50,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.green.shade200,
                                              style: BorderStyle.solid,
                                              width: 1.2,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.green.shade200,
                                              style: BorderStyle.solid,
                                              width: 1.2,
                                            ),
                                          ),
                                        ),
                                        onChanged: (val) => coupon = val,
                                        enabled: !couponApplied,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: couponApplied
                                          ? null
                                          : applyCoupon,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: couponApplied
                                            ? Colors.grey.shade400
                                            : Color(0xFF273E06),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        couponApplied ? "Applied" : "Apply",
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                if (couponApplied)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          coupon = "";
                                          discount = 0;
                                          couponApplied = false;
                                        });
                                      },
                                      child: const Text("Remove coupon"),
                                    ),
                                  ),

                                // Status message
                                if (couponApplied)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF273E06),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Coupon applied! (${(discount * 100).toInt()}% OFF)",
                                          style: const TextStyle(
                                            color: Color(0xFF273E06),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // 📦 Order Summary
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white,
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  "Order Summary",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const Divider(),
                                summaryRow(
                                  "Subtotal",
                                  "₹${totalPrice.toStringAsFixed(2)}",
                                ),
                                summaryRow(
                                  "Delivery",
                                  deliveryAvailable
                                      ? "₹$deliveryFee"
                                      : "Not available 🚫",
                                ),
                                if (discount > 0)
                                  summaryRow(
                                    "Coupon discount",
                                    "-₹${couponDiscount.toStringAsFixed(2)}",
                                  ),
                                const Divider(),
                                summaryRow(
                                  "Total",
                                  deliveryAvailable
                                      ? "₹${grandTotal.toStringAsFixed(2)}"
                                      : "—",
                                  isBold: true,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed:
                                      (!deliveryAvailable ||
                                          isCheckingOut ||
                                          isMinimumOrderNotMet)
                                      ? null
                                      : checkout,
                                  icon: isCheckingOut
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.lock_outline),
                                  label: Text(
                                    !deliveryAvailable
                                        ? "Delivery not available"
                                        : isMinimumOrderNotMet
                                        ? "Minimum order ₹149 required"
                                        : "Proceed to Checkout",
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        (!deliveryAvailable ||
                                            isMinimumOrderNotMet)
                                        ? Colors.grey.shade400
                                        : const Color(0xFF273E06),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // 🔴 Show warning text if minimum not met
                                if (isMinimumOrderNotMet)
                                  const Center(
                                    child: Text(
                                      "Minimum order value is ₹149 to proceed",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                else if (deliveryAvailable && !isFreeDelivery)
                                  Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          "100% Secure Checkout",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "Add + ₹${(499 - totalPrice).toInt()} More To Avail Free Delivery",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          "100% Secure Checkout",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "Add +${499 - totalPrice} More To Avail Free Delivery",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (isLoading && cartItems.isNotEmpty)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF273E06)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 10),
          const Text("Your cart is empty"),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                "/userhome",
                (route) => false,
              );
            },
            child: const Text("Start Shopping"),
          ),
        ],
      ),
    );
  }

  Widget summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : null),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : null),
          ),
        ],
      ),
    );
  }
}
