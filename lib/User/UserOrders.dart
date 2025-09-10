import 'package:carocart/Apis/cart_service.dart';
import 'package:carocart/Utils/FormatDate.dart';
import 'package:carocart/Utils/Messages.dart';
import 'package:flutter/material.dart';
import 'package:carocart/Apis/order_service.dart';
import 'package:dio/dio.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});
  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  bool loading = true;
  bool actionLoading = false; // overlay for actions like cancel/reorder
  List<dynamic> orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => loading = true);
    final Response? res = await OrderService.getMyOrders();
    if (res != null && res.statusCode == 200) {
      if (!mounted) return;
      setState(() {
        orders = List.from(res.data.reversed);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    setState(() => actionLoading = true);
    try {
      final Response? res = await OrderService.cancelOrder(orderId);
      if (res != null && res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppMessages.cancelOrder)));
        await _loadOrders();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppMessages.cancelOrderFailed)),
      );
    } finally {
      setState(() => actionLoading = false);
    }
  }

  void _showCancelConfirmation(int orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close dialog
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelOrder(orderId);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<dynamic> getActiveOrders() =>
      orders.where((o) => o['status'] == "PLACED").toList();

  List<dynamic> getPastOrders() => orders
      .where((o) => o['status'] == "DELIVERED" || o['status'] == "CANCELLED")
      .toList();

  Widget _buildOrderCard(dynamic order) {
    final items = order['items'] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: First item image + order summary
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: items.isNotEmpty && items[0]['productImageUrl'] != null
                      ? Image.network(
                          items[0]['productImageUrl'],
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 80,
                          width: 80,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order #${order['orderId']}",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: order['status'] == "DELIVERED"
                              ? LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.2),
                                    Colors.green.withOpacity(0.1),
                                  ],
                                )
                              : order['status'] == "CANCELLED"
                              ? LinearGradient(
                                  colors: [
                                    Colors.red.withOpacity(0.2),
                                    Colors.red.withOpacity(0.1),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.orange.withOpacity(0.2),
                                    Colors.orange.withOpacity(0.1),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order['status'] ?? "DELIVERED",
                          style: TextStyle(
                            color: order['status'] == "DELIVERED"
                                ? Colors.green
                                : order['status'] == "CANCELLED"
                                ? Colors.red
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Placed on ${formatDate(order['orderDate'] ?? '')}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "₹${order['totalAmount'] ?? 0}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // List all items
            Column(
              children: List.generate(items.length, (i) {
                final item = items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['productName'] ?? "Product",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black38,
                          ),
                        ),
                      ),
                      Text(
                        "x${item['quantity'] ?? 1}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 6),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    setState(() => actionLoading = true);
                    try {
                      for (var item in order['items'] ?? []) {
                        await CartService.addToCart(
                          item['productId'],
                          item['quantity'] ?? 1,
                        );
                      }
                      await CartService.getCart();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppMessages.itemsAddedToCartSuccessful),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppMessages.itemsAddedToCartFailed),
                        ),
                      );
                    } finally {
                      setState(() => actionLoading = false);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.replay, color: Colors.green),
                  label: const Text(
                    "Reorder",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                if (order['status'] == "PLACED")
                  OutlinedButton.icon(
                    onPressed: () => _showCancelConfirmation(order['orderId']),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
            // Rating
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Rating",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < (order['rating'] ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<dynamic> ordersList) {
    if (ordersList.isEmpty) {
      return const Center(child: Text("No orders found"));
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        itemCount: ordersList.length,
        itemBuilder: (ctx, i) => _buildOrderCard(ordersList[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Your Orders"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Active Orders"),
              Tab(text: "Past Orders"),
            ],
          ),
        ),
        body: Stack(
          children: [
            loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _buildOrdersList(getActiveOrders()),
                      _buildOrdersList(getPastOrders()),
                    ],
                  ),
            if (!loading && actionLoading) // overlay only after initial load
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
