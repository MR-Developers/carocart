import 'package:flutter/material.dart';

class DeliveryDocVerification extends StatelessWidget {
  const DeliveryDocVerification({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header Section with Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2ECC71)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  "Welcome to Caro Cart",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Just a few steps to complete and then you can start earning with Us",
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ✅ Pending Documents
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              "Pending Documents",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          _buildDocTile("Personal Documents"),
          _buildDocTile("Vehicle Details"),
          _buildDocTile("Bank Account Details"),
          _buildDocTile("Emergency Details"),

          const SizedBox(height: 20),

          // ✅ Completed Documents
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              "Completed Documents",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          _buildCompletedDocTile("Personal Information"),

          const Spacer(),

          // ✅ Next Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to next step
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Pending Doc Tile
  Widget _buildDocTile(String title) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 15)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.green,
        ),
        onTap: () {
          // TODO: Navigate to respective screen
        },
      ),
    );
  }

  // ✅ Completed Doc Tile
  Widget _buildCompletedDocTile(String title) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.check, color: Colors.green),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.green,
        ),
        onTap: () {
          // TODO: Navigate to details
        },
      ),
    );
  }
}
