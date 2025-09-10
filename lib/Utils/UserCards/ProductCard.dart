import 'package:carocart/User/ProductDetails.dart';
import 'package:flutter/material.dart';
import 'package:carocart/Apis/cart_service.dart';

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final Function(int productId, int delta) onQuantityChange;

  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onQuantityChange,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Future<void> _updateCart(int newQty) async {
    try {
      await CartService.updateCartItem(widget.product["id"], newQty);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating cart: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    double? mrp = widget.product["mrp"]?.toDouble();
    double? price = widget.product["price"]?.toDouble();

    int? discountPercent;
    if (mrp != null && price != null && mrp > price) {
      discountPercent = (((mrp - price) / mrp) * 100).round();
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(product: widget.product),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            width: 250,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image + discount badge
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child:
                              widget.product["imageUrl"] != null &&
                                  widget.product["imageUrl"].isNotEmpty
                              ? Image.network(
                                  widget.product["imageUrl"],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        if (discountPercent != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$discountPercent% OFF",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Content section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product["name"] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.product["description"] != null &&
                            widget.product["description"]
                                .toString()
                                .isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.product["description"],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Price
                            Row(
                              children: [
                                if (widget.product["mrp"] != null)
                                  Text(
                                    "₹${widget.product["mrp"]}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.red,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                const SizedBox(width: 5),
                                Text(
                                  "₹${widget.product["price"] ?? ""}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            // Quantity selector
                            widget.quantity == 0
                                ? InkWell(
                                    onTap: () async {
                                      widget.onQuantityChange(
                                        widget.product["id"],
                                        1,
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        // Minus button
                                        // Quantity selector
                                        widget.quantity == 0
                                            ? InkWell(
                                                onTap: () {
                                                  widget.onQuantityChange(
                                                    widget.product["id"],
                                                    1,
                                                  );
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.green,
                                                    width: 1.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        widget.onQuantityChange(
                                                          widget.product["id"],
                                                          -1,
                                                        );
                                                      },
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        child: Icon(
                                                          Icons.remove,
                                                          color: Colors.green,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      widget.quantity
                                                          .toString(),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        widget.onQuantityChange(
                                                          widget.product["id"],
                                                          1,
                                                        );
                                                      },
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        child: Icon(
                                                          Icons.add,
                                                          color: Colors.green,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ],
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
        ],
      ),
    );
  }
}
