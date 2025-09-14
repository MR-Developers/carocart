import 'package:carocart/Apis/home_api.dart';
import 'package:carocart/Utils/delivery_fee.dart';
import 'package:flutter/material.dart';
import 'package:carocart/Apis/address_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:carocart/Apis/cart_service.dart';

// Example CartItem model (adjust to match your app’s model)
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

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String deliveryAddress = "Fetching address...";
  String deliveryTime = "Calculating...";
  CartItem? cartItem; // track this product in cart
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeliveryInfo();
    _checkIfInCart();
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
    final newQuantity = (item.quantity + delta).clamp(0, 99);

    setState(() {
      item.quantity = newQuantity;
      if (newQuantity == 0) {
        cartItem = null; // reset to Add To Cart mode
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update cart item")),
      );
    } finally {
      setState(() => isLoading = false);
    }
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
      appBar: AppBar(title: Text(widget.product["name"] ?? "Product")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            widget.product["imageUrl"] != null
                ? Image.network(
                    widget.product["imageUrl"],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, size: 80),
                      );
                    },
                  )
                : Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 80),
                  ),

            // Title + rating + price
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product["name"] ?? "",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: (widget.product["avgRating"]?.toDouble() ?? 0),
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 18.0,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "(${widget.product["ratingCount"] ?? 0})",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (mrp != null)
                        Text(
                          "₹$mrp",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        "₹${price ?? ""}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (discountPercent != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            "-$discountPercent%",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: Text("Delivers to: $deliveryAddress"),
              trailing: TextButton(
                onPressed: () {
                  // TODO: Change address
                },
                child: const Text("Change"),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delivery_dining, color: Colors.green),
              title: Text(deliveryTime),
              subtitle: const Text("Delivery charges vary with location"),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                "Description",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.product["description"] ?? "No description available",
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),

      // Bottom bar
      bottomNavigationBar: SizedBox(
        height: cartItem == null ? 90 : 130,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: cartItem == null
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          final newItem = CartItem(
                            id: widget.product["id"].toString(),
                            name: widget.product["name"],
                            price: widget.product["price"]?.toDouble() ?? 0,
                            quantity: 1,
                          );

                          setState(() => cartItem = newItem);

                          try {
                            await CartService.updateCartItem(
                              int.parse(newItem.id),
                              1,
                            );
                            await CartService.getCart();
                          } catch (e) {
                            print("❌ Failed to add to cart: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to add item to cart"),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          "Add To Cart",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Quantity + Price (stacked in column)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Quantity selector
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors
                                      .grey
                                      .shade200, // light background for pill
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // pill shape
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Minus button
                                    GestureDetector(
                                      onTap: () =>
                                          _changeQuantity(cartItem!, -1),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              Colors.white, // button background
                                        ),
                                        child: const Icon(
                                          Icons.remove,
                                          size: 18,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),

                                    // Quantity text
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        "${cartItem!.quantity}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    // Plus button
                                    GestureDetector(
                                      onTap: () =>
                                          _changeQuantity(cartItem!, 1),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              Colors.white, // button background
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 18,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 6),
                              // Price display
                              Text(
                                "₹${(cartItem!.price * cartItem!.quantity).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          // Go to Cart button (with caret)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, "/usercart");
                            },
                            icon: const Text(
                              "Go to Cart",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            label: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
}
