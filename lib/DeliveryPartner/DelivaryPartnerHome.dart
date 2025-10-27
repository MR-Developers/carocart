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

  static const Color primaryGreen = Color(0xFF273E06);
  static const Color accentGreen = Color(0xFF4A6B1E);
  static const Color lightGreen = Color(0xFFF0F5EB);
  static const Color borderColor = Color(0xFFE8EFE0);

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

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
      backgroundColor: const Color(0xFFFAFCF8),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
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
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _dashboardFuture = _fetchDashboardData();
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header with gradient background - Full Width
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryGreen, accentGreen],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back! 👋',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your delivery dashboard',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Stats Grid
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Stats',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.05,
                        children: [
                          _buildStatCard(
                            icon: Icons.assignment_outlined,
                            title: "Assigned",
                            value: assignedOrders.length.toString(),
                            color: primaryGreen,
                            bgColor: const Color(0xFFE8F2DC),
                          ),
                          _buildStatCard(
                            icon: Icons.local_shipping_outlined,
                            title: "Available",
                            value: availableOrders.length.toString(),
                            color: const Color(0xFF5C7A1F),
                            bgColor: const Color(0xFFF1F6E8),
                          ),
                          _buildStatCard(
                            icon: Icons.wallet_outlined,
                            title: "Earnings",
                            value: "₹${earningsSummary["total"] ?? 0}",
                            color: const Color(0xFF3D5610),
                            bgColor: const Color(0xFFF5F9ED),
                          ),
                          _buildStatCard(
                            icon: Icons.check_circle_outline,
                            title: "Status",
                            value: "Active",
                            color: const Color(0xFF2E8B57),
                            bgColor: const Color(0xFFE8F5F0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
    required Color bgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
