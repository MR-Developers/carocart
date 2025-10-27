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
  int _selectedIndex = 0;

  // Theme colors based on Color(0xFF273E06)
  static const Color primaryGreen = Color(0xFF273E06);
  static const Color lightGreen = Color(0xFF4A6B1E);
  static const Color darkGreen = Color(0xFF1A2B04);
  static const Color accentGreen = Color(0xFF3B5A0F);

  List<Map<String, dynamic>> assignedOrders = [];
  List<Map<String, dynamic>> availableOrders = [];

  bool isLoadingAssigned = false;
  bool isLoadingAvailable = false;
  bool isRefreshing = false;

  String? token;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchOrders();
  }

  Future<void> _loadTokenAndFetchOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');

      if (storedToken != null && storedToken.isNotEmpty) {
        setState(() {
          token = storedToken;
          errorMessage = null;
        });
        await _fetchOrders();
      } else {
        setState(() {
          errorMessage = 'No token found, please login again.';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No token found, please login again.'),
              backgroundColor: primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load authentication: $e';
      });
    }
  }

  Future<void> _fetchOrders() async {
    if (token == null) return;

    setState(() {
      isLoadingAssigned = true;
      isLoadingAvailable = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        getAvailableOrdersForAssignment(context, token!),
        getAssignedOrders(context, token!),
      ]);

      if (mounted) {
        setState(() {
          availableOrders = results[0];
          assignedOrders = results[1];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to fetch orders: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingAssigned = false;
          isLoadingAvailable = false;
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      isRefreshing = true;
    });
    await _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: token == null
          ? _buildErrorState()
          : Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryGreen, accentGreen],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildToggleButton(
                            "Assigned",
                            0,
                            assignedOrders.length,
                          ),
                          const SizedBox(width: 12),
                          _buildToggleButton(
                            "Available",
                            1,
                            availableOrders.length,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: primaryGreen,
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        isLoadingAssigned
                            ? _buildLoadingState()
                            : AssignedOrdersScreen(
                                orders: assignedOrders,
                                onRefresh: _handleRefresh,
                              ),
                        isLoadingAvailable
                            ? _buildLoadingState()
                            : AvailableOrdersScreen(
                                orders: availableOrders,
                                onRefresh: _handleRefresh,
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Authentication required',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTokenAndFetchOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading orders...',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, int index, int count) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? primaryGreen : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: [primaryGreen, accentGreen])
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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

class AssignedOrdersScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final VoidCallback onRefresh;

  static const Color primaryGreen = Color(0xFF273E06);
  static const Color lightGreen = Color(0xFF4A6B1E);
  static const Color accentGreen = Color(0xFF3B5A0F);

  const AssignedOrdersScreen({
    super.key,
    required this.orders,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No assigned orders",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Pull down to refresh",
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildAssignedOrderCard(context, order);
      },
    );
  }

  Widget _buildAssignedOrderCard(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGreen.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Handle tap - navigate to order details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryGreen.withOpacity(0.1),
                            accentGreen.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order["productName"] ?? "Unknown Product",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getStatusGradient(
                                  order["deliveryStatus"],
                                ),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(
                                    order["deliveryStatus"],
                                  ).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              order["deliveryStatus"] ?? "Unknown",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.inventory_2_outlined,
                  "Quantity",
                  order["quantity"]?.toString() ?? "N/A",
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  "Address",
                  order["deliveryAddress"] ?? "No address",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange[600]!;
      case 'in_transit':
      case 'picked_up':
        return const Color(0xFF4A6B1E);
      case 'delivered':
        return primaryGreen;
      default:
        return Colors.grey[600]!;
    }
  }

  List<Color> _getStatusGradient(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return [Colors.orange[600]!, Colors.orange[400]!];
      case 'in_transit':
      case 'picked_up':
        return [const Color(0xFF4A6B1E), const Color(0xFF5C7A1F)];
      case 'delivered':
        return [primaryGreen, accentGreen];
      default:
        return [Colors.grey[600]!, Colors.grey[400]!];
    }
  }
}

class AvailableOrdersScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final VoidCallback onRefresh;

  static const Color primaryGreen = Color(0xFF273E06);
  static const Color lightGreen = Color(0xFF4A6B1E);
  static const Color darkGreen = Color(0xFF1A2B04);
  static const Color accentGreen = Color(0xFF3B5A0F);

  const AvailableOrdersScreen({
    super.key,
    required this.orders,
    required this.onRefresh,
  });

  // Helper method to safely extract orderId from various types
  int? _extractOrderId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "No available orders",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Pull down to refresh",
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildAvailableOrderCard(context, order);
      },
    );
  }

  Widget _buildAvailableOrderCard(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    final vendorLat = (order["vendorLat"] ?? 0.0) as double;
    final vendorLng = (order["vendorLng"] ?? 0.0) as double;
    final addressLat = (order["addressLat"] ?? 0.0) as double;
    final addressLng = (order["addressLng"] ?? 0.0) as double;
    final distance = haversineKm(vendorLat, vendorLng, addressLat, addressLng);

    final String status = (order["status"] ?? "").toString().toLowerCase();
    final bool isDelivered = status == "delivered";

    // Use the helper method to safely extract orderId
    final int? orderId = _extractOrderId(order["orderId"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGreen.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryGreen.withOpacity(0.1),
                              accentGreen.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order["productName"] ?? "Unknown Product",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryGreen, accentGreen],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryGreen.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    order["status"] ?? "Unknown",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF5C7A1F),
                                        const Color(0xFF7A9B3A),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.directions_car,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${distance.toStringAsFixed(2)} KM",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.inventory_2_outlined,
                    "Quantity",
                    order["quantity"]?.toString() ?? "N/A",
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.person_outline,
                    "Customer",
                    order["userName"] ?? "Unknown",
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.phone_outlined,
                    "Phone",
                    order["userPhone"] ?? "N/A",
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    "Address",
                    order["shippingAddress"] ?? "No address",
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: isDelivered
                    ? LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[300]!],
                      )
                    : LinearGradient(colors: [primaryGreen, accentGreen]),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDelivered
                        ? Colors.grey.withOpacity(0.2)
                        : primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  onTap: isDelivered
                      ? null
                      : () async {
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('auth_token');

                            if (token == null || token.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Authentication token not found',
                                  ),
                                  backgroundColor: Colors.red[700],
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            if (orderId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Invalid order ID'),
                                  backgroundColor: Colors.red[700],
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            // Call the API
                            await selfAssignOrder(context, token, orderId);

                            // Refresh the orders after assignment
                            onRefresh();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Order accepted: ${order["productName"]}',
                                ),
                                backgroundColor: primaryGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error accepting order: $e'),
                                backgroundColor: Colors.red[700],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDelivered
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDelivered ? 'Already Delivered' : 'Accept Order',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
