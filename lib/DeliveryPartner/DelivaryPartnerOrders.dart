import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Apis/delivery.Person.dart';
import 'package:carocart/Utils/delivery_fee.dart';

class DeliveryPartnerOrder extends StatefulWidget {
  const DeliveryPartnerOrder({super.key});

  @override
  State<DeliveryPartnerOrder> createState() => _DeliveryPartnerOrderState();
}

class _DeliveryPartnerOrderState extends State<DeliveryPartnerOrder> {
  int _selectedIndex = 0; // 0 => Assigned, 1 => Available

  List<Map<String, dynamic>> assignedOrders = [];
  List<Map<String, dynamic>> availableOrders = [];

  bool isLoadingAssigned = false;
  bool isLoadingAvailable = false;

  String? token; // Token will be loaded from local storage

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchOrders();
  }

  /// Load token from SharedPreferences and then fetch data
  Future<void> _loadTokenAndFetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('authToken');

    if (storedToken != null && storedToken.isNotEmpty) {
      setState(() {
        token = storedToken;
      });
      _fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No token found, please login again.')),
      );
    }
  }

  /// Fetch both assigned and available orders
  Future<void> _fetchOrders() async {
    if (token == null) return;

    setState(() {
      isLoadingAssigned = true;
      isLoadingAvailable = true;
    });

    try {
      // Run both API calls in parallel
      final results = await Future.wait([
        getAvailableOrdersForAssignment(context, token!),
        getAssignedOrders(context, token!),
      ]);

      setState(() {
        availableOrders = results[0]; // first API
        assignedOrders = results[1]; // second API
      });
    } finally {
      setState(() {
        isLoadingAssigned = false;
        isLoadingAvailable = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: token == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Toggle Buttons with Counts
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      _buildToggleButton("Assigned", 0, assignedOrders.length),
                      const SizedBox(width: 10),
                      _buildToggleButton(
                        "Available",
                        1,
                        availableOrders.length,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Screen Content
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      // Assigned Orders Screen
                      isLoadingAssigned
                          ? const Center(child: CircularProgressIndicator())
                          : AssignedOrdersScreen(orders: assignedOrders),

                      // Available Orders Screen
                      isLoadingAvailable
                          ? const Center(child: CircularProgressIndicator())
                          : AvailableOrdersScreen(orders: availableOrders),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Builds each toggle button with count
  Widget _buildToggleButton(String text, int index, int count) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.green : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
// Assigned Orders Screen
//
class AssignedOrdersScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  const AssignedOrdersScreen({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          "No assigned orders",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          child: ListTile(
            title: Text(
              order["productName"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Qty: ${order["quantity"]}\n"
              "Address: ${order["deliveryAddress"]}\n"
              "Status: ${order["deliveryStatus"]}",
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }
}

//
// Available Orders Screen
//
class AvailableOrdersScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  const AvailableOrdersScreen({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          "No available orders",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final vendorLat = (order["vendorLat"] ?? 0.0) as double;
        final vendorLng = (order["vendorLng"] ?? 0.0) as double;
        final addressLat = (order["addressLat"] ?? 0.0) as double;
        final addressLng = (order["addressLng"] ?? 0.0) as double;
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          child: ListTile(
            title: Text(
              order["productName"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Qty: ${order["quantity"]}\n"
              "Address: ${order["shippingAddress"]}\n"
              "Status: ${order["status"]}\n"
              "Customer Name:${order["userName"]}\n"
              "Customer Phone Number:${order["userPhone"]}\n"
              "Distance: ${haversineKm(vendorLat, vendorLng, addressLat, addressLng).toStringAsFixed(2)} KM",
            ),
            trailing: GestureDetector(
              onTap: () {
                print(order);
              },
              child: Icon(
                Icons.add_circle_outline,
                size: 24,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }
}
