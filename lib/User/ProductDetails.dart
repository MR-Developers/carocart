import 'package:carocart/Apis/home_api.dart';
import 'package:carocart/Utils/delivery_fee.dart';
import 'package:flutter/material.dart';
import 'package:carocart/Apis/address_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
// import your CartService, ProductService, VendorService if needed

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String deliveryAddress = "Fetching address...";
  String deliveryTime = "Calculating...";

  @override
  void initState() {
    super.initState();
    _loadDeliveryInfo();
  }

  Future<void> _loadDeliveryInfo() async {
    try {
      // ✅ Fetch user default address
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
      // ✅ Fetch vendor coordinates from product
      final product = widget.product;
      final vendor = await getVendorById(product["vendorId"]);
      // 👇 Expect vendor info to come from API
      vendorLat ??= vendor["latitude"];
      vendorLng ??= vendor["longitude"];

      if (vendorLat != null &&
          vendorLng != null &&
          userLat != null &&
          userLng != null) {
        final distance = haversineKm(vendorLat, vendorLng, userLat, userLng);
        // Estimate delivery time (e.g., 30 min per 10 km)
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
            // Product image
            widget.product["imageUrl"] != null
                ? Image.network(
                    widget.product["imageUrl"],
                    fit: BoxFit
                        .contain, // Maintains the image's original aspect ratio
                    width: double.infinity, // Takes full width
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

                  // Inside your widget
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

            // Delivery info
            const Divider(),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: Text("Delivers to: $deliveryAddress"),
              trailing: TextButton(
                onPressed: () {
                  // TODO: Change address action
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
            // Description
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Description",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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

      // Bottom action bar
      bottomNavigationBar: Container(
        height: 60,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // TODO: Add To Cart
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: Colors.green),
                  alignment: Alignment.center,
                  child: const Text(
                    "Add To Cart",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
