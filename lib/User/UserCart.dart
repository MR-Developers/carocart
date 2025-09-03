import 'package:carocart/Apis/address_service.dart';
import 'package:carocart/Apis/cart_service.dart';
import 'package:carocart/Apis/product_service.dart';
import 'package:carocart/Utils/delivery_fee.dart';
import 'package:flutter/material.dart';

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

class _UserCartPageState extends State<UserCartPage> {
  List<CartItem> cartItems = [];
  bool isClearing = false;
  bool isCheckingOut = false;
  String coupon = "";
  bool couponApplied = false;
  bool isLoading = true;
  double discount = 0.0;
  double deliveryFee = 0;
  bool deliveryAvailable = true;

  double get totalPrice =>
      cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);

  double get couponDiscount => discount > 0 ? totalPrice * discount : 0;

  double get grandTotal =>
      (totalPrice - couponDiscount) + (deliveryAvailable ? deliveryFee : 0);

  void applyCoupon() {
    if (coupon.trim().toUpperCase() == "OLIVE20" && !couponApplied) {
      setState(() {
        discount = 0.2;
        couponApplied = true;
      });
    } else {
      setState(() {
        discount = 0;
        couponApplied = false;
      });
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
        // 🔄 Update cart item in backend
        await CartService.updateCartItem(int.parse(item.id), newQuantity);
      } else {
        // 🗑 Remove item from backend (set quantity = 0)

        await CartService.updateCartItem(int.parse(item.id), 0);
      }
      // 🔔 Refresh global count for AppNavbar
      await CartService.getCart();
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

  @override
  void initState() {
    super.initState();
    _fetchCart();
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
      final List<CartItem> items = [];

      double? vendorLat;
      double? vendorLng;

      for (final entry in cartMap.entries) {
        final product = await ProductService.getProductById(entry.key);

        if (product != null) {
          // 👇 Expect vendor info to come from API
          vendorLat ??= product["vendorLat"];
          vendorLng ??= product["vendorLng"];

          items.add(
            CartItem(
              id: product["id"].toString(),
              productName: product["name"],
              vendorName: product["vendorName"],
              imageUrl: product["imageUrl"],
              price: product["price"].toDouble(),
              quantity: entry.value,
            ),
          );
        }
      }

      // ✅ Calculate delivery fee if vendor/user coords exist
      double? fee;
      if (vendorLat != null && vendorLng != null) {
        final d = haversineKm(vendorLat, vendorLng, userLat, userLng);
        fee = feeFromDistance(d);
      }

      setState(() {
        cartItems = items;
        deliveryFee = fee ?? 0;
        deliveryAvailable = fee != null;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching cart: $e");
      setState(() => isLoading = false);
    }
  }

  void clearCart() async {
    setState(() => isClearing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      cartItems.clear();
      isClearing = false;
    });
  }

  void checkout() async {
    setState(() => isCheckingOut = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isCheckingOut = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Proceeding to checkout...")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Your Cart"),
        elevation: 0,
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          cartItems.isEmpty
              ? (isLoading
                    ? const SizedBox.shrink() // blank widget while loading
                    : _buildEmptyCart())
              : LayoutBuilder(
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
                                  children: cartItems.asMap().entries.map((
                                    entry,
                                  ) {
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
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.network(
                                              item.imageUrl,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () =>
                                                            changeQuantity(
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
                                                          item.quantity
                                                              .toString(),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () =>
                                                            changeQuantity(
                                                              item,
                                                              1,
                                                            ),
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
                                          // Price on the right
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              // Old Price (strikethrough)
                                              Text(
                                                "₹${(item.price * item.quantity).toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                              const SizedBox(height: 4),

                                              // New Discounted Price
                                              Text(
                                                "₹${((item.price * 0.8) * item.quantity).toStringAsFixed(2)}", // 20% discount
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
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
                                    color: Colors.green,
                                  ),
                                  label: const Text(
                                    "Add More items",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
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
                                          color: Colors.green,
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
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.green.shade200,
                                                  style: BorderStyle.solid,
                                                  width: 1.2,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                                : Colors.green.shade600,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            couponApplied ? "Applied" : "Apply",
                                            style: const TextStyle(
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Status message
                                    if (couponApplied)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Coupon applied! (${(discount * 100).toInt()}% OFF)",
                                              style: const TextStyle(
                                                color: Colors.green,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                          (!deliveryAvailable || isCheckingOut)
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
                                        deliveryAvailable
                                            ? "Proceed to Checkout"
                                            : "Delivery not available",
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: deliveryAvailable
                                            ? Colors.green.shade600
                                            : Colors.grey.shade400,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (deliveryAvailable)
                                      const Center(
                                        child: Text(
                                          "100% Secure Checkout",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
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
                  },
                ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.green),
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
          ElevatedButton(onPressed: () {}, child: const Text("Start Shopping")),
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
