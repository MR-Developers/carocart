import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Apis/delivery.Person.dart';

/// Fetch orders from API

class DeliveryOrderHistory extends StatefulWidget {
  const DeliveryOrderHistory({super.key});

  @override
  State<DeliveryOrderHistory> createState() => _DeliveryOrderHistoryState();
}

class _DeliveryOrderHistoryState extends State<DeliveryOrderHistory> {
  late Future<List<Map<String, dynamic>>> futureOrders;

  @override
  void initState() {
    super.initState();
    futureOrders = _loadOrders();
  }

  /// Load token from local storage and fetch orders
  Future<List<Map<String, dynamic>>> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    if (token.isEmpty) {
      throw Exception("No auth token found in local storage");
    }

    return await getOrderHistory(context, token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureOrders,
        builder: (context, snapshot) {
          // Show loading spinner while fetching
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error message
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load orders: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          // No orders found
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'No order history found.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // Display orders in list
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order ID and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Order #${order['orderId']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            order['deliveryStatus'] ?? 'Pending',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: order['deliveryStatus'] == 'Delivered'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Product Name & Quantity
                      Text(
                        "${order['productName']} (x${order['quantity']})",
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 6),

                      // User Name & Phone
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(order['userName'] ?? 'Unknown'),
                          const SizedBox(width: 12),
                          const Icon(Icons.phone, size: 18, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(order['userPhone'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Delivery Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order['deliveryAddress'] ?? 'No Address',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Payment Type
                      Row(
                        children: [
                          const Icon(
                            Icons.payment,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Payment: ${order['paymentType'] ?? 'N/A'}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
