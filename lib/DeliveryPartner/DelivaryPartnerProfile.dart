import 'package:carocart/DeliveryPartner/DelivaryOrderHistory.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Apis/delivery.Person.dart';
import 'EditProfileScreen.dart';
import 'DeliveryEarningsPage.dart';

class DeliveryPartnerProfile extends StatefulWidget {
  const DeliveryPartnerProfile({super.key});

  @override
  State<DeliveryPartnerProfile> createState() => _DeliveryPartnerProfileState();
}

class _DeliveryPartnerProfileState extends State<DeliveryPartnerProfile> {
  // Fetch token and profile data
  Future<Map<String, dynamic>> _fetchProfile(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken'); // Retrieve token

    if (token == null || token.isEmpty) {
      throw Exception("No token found in local storage");
    }

    return await getDeliveryProfile(context, token);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchProfile(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        }

        final data = snapshot.data ?? {};

        if (data.isEmpty) {
          return const Center(
            child: Text(
              "No profile data available",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        final phone = data['phone'] ?? 'N/A';
        final email = data['email'] ?? 'N/A';
        final address = data['address'] ?? 'N/A';
        final earnings = (data['earnings'] ?? 0).toDouble();
        final profilePhotoUrl = data['profilePhotoUrl'] ?? '';

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Profile Header
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profilePhotoUrl.isNotEmpty
                        ? NetworkImage(profilePhotoUrl)
                        : const AssetImage('assets/images/default_avatar.png')
                              as ImageProvider,
                  ),
                  const SizedBox(height: 10),

                  // Full Name
                  Text(
                    "$firstName $lastName",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Phone
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(phone, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Email
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(email, style: const TextStyle(fontSize: 16)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Earnings Display
                  // Container(
                  //   margin: const EdgeInsets.symmetric(horizontal: 16),
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 20,
                  //     vertical: 14,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: Colors.green.shade50,
                  //     borderRadius: BorderRadius.circular(10),
                  //     border: Border.all(color: Colors.green.shade100),
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       const Icon(
                  //         Icons.currency_rupee,
                  //         color: Colors.green,
                  //         size: 28,
                  //       ),
                  //       const SizedBox(width: 4),
                  //       Text(
                  //         earnings.toStringAsFixed(2),
                  //         style: const TextStyle(
                  //           fontSize: 24,
                  //           fontWeight: FontWeight.bold,
                  //           color: Colors.green,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 30),

                  // Options Section
                  _buildSectionTitle("Options"),

                  _buildOptionTile(
                    context,
                    icon: Icons.person,
                    label: "Edit Profile",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(existingData: data),
                        ),
                      ).then((value) {
                        if (value == true) setState(() {});
                      });
                    },
                  ),
                  _buildOptionTile(
                    context,
                    icon: Icons.currency_rupee,
                    label: "Earnings",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryEarningsPage(),
                        ),
                      );
                    },
                  ),
                  _buildOptionTile(
                    context,
                    icon: Icons.receipt_long, // Perfect for order history
                    label: "Order History",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryOrderHistory(),
                        ),
                      );
                    },
                  ),

                  _buildOptionTile(
                    context,
                    icon: Icons.headset_mic,
                    label: "Support",
                    onTap: () {
                      // TODO: Navigate to support screen
                    },
                  ),
                  _buildOptionTile(
                    context,
                    icon: Icons.description,
                    label: "Terms and Conditions",
                    onTap: () {
                      // TODO: Navigate to terms and conditions
                    },
                  ),

                  // Logout button
                  _buildOptionTile(
                    context,
                    icon: Icons.logout,
                    label: "Log Out",
                    isLogout: true,
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('authToken');
                      // TODO: Navigate back to login screen
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Section title
  Widget _buildSectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Option Tile
  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isLogout ? Colors.red : Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isLogout ? Colors.red : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
