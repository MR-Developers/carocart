import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Apis/delivery.Person.dart';

class DeliveryPartnerHome extends StatefulWidget {
  const DeliveryPartnerHome({super.key});

  @override
  State<DeliveryPartnerHome> createState() => _DeliveryPartnerHomeState();
}

class _DeliveryPartnerHomeState extends State<DeliveryPartnerHome> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  // Updated theme colors based on Color(0xFF273E06)
  static const Color primaryGreen = Color(0xFF273E06);
  static const Color lightGreen = Color(0xFF4A6B1E);
  static const Color darkGreen = Color(0xFF1A2B04);
  static const Color accentGreen = Color(0xFF3B5A0F);

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      throw Exception("No token found in local storage");
    }

    final results = await Future.wait([
      getAssignedOrders(context, token),
      getAvailableOrdersForAssignment(context, token),
      getDeliveryEarningsSummary(context, token, "daily"),
      getDeliveryProfile(context, token),
    ]);

    return {
      "assignedOrders": results[0] as List<Map<String, dynamic>>,
      "availableOrders": results[1] as List<Map<String, dynamic>>,
      "earningsSummary": results[2] as Map<String, dynamic>,
      "profile": results[3] as Map<String, dynamic>,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _dashboardFuture = _fetchDashboardData();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No data available"));
          }

          final data = snapshot.data!;
          final assignedOrders = data["assignedOrders"] as List;
          final availableOrders = data["availableOrders"] as List;
          final earningsSummary = data["earningsSummary"] as Map;
          final profile = data["profile"] as Map;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Grid
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF273E06),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          _buildStatCard(
                            icon: Icons.assignment,
                            title: "Assigned Orders",
                            value: assignedOrders.length.toString(),
                            color: accentGreen,
                            gradient: [accentGreen, lightGreen],
                          ),
                          _buildStatCard(
                            icon: Icons.local_shipping,
                            title: "Available Orders",
                            value: availableOrders.length.toString(),
                            color: const Color(0xFF5C7A1F),
                            gradient: [
                              const Color(0xFF5C7A1F),
                              const Color(0xFF7A9B3A),
                            ],
                          ),
                          _buildStatCard(
                            icon: Icons.account_balance_wallet,
                            title: "Today's Earnings",
                            value: "₹${earningsSummary["total"] ?? 0}",
                            color: primaryGreen,
                            gradient: [primaryGreen, darkGreen],
                          ),
                          _buildStatCard(
                            icon: Icons.verified_user,
                            title: "Status",
                            value: "Active",
                            color: const Color(0xFF3D5610),
                            gradient: [
                              const Color(0xFF3D5610),
                              const Color(0xFF567320),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
