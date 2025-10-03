import 'package:carocart/User/OnBoarding.dart';
import 'package:carocart/DeliveryPartner/DeliveryPartnerLoginScreen.dart';
import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fixed card height
    const double cardHeight = 220;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            // Logo
            Image.asset('assets/images/Logo.jpg', height: 60),
            const SizedBox(height: 20),

            // Title
            const Text(
              "Who are you ?",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 40),

            // Options
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Row for first two
                    Row(
                      children: [
                        Expanded(
                          child: RoleCard(
                            imagePath: 'assets/images/Customer.png',
                            title: "Customer",
                            subtitle: "I Want To Order Food Or Groceries",
                            height: cardHeight,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OnboardingScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: RoleCard(
                            imagePath: 'assets/images/DeliveryPartner.png',
                            title: "Delivery Partner",
                            subtitle: "I Want To Deliver Food Or Groceries",
                            height: cardHeight,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DeliveryPartnerLoginScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Vendor card below, same size
                    RoleCard(
                      imagePath: 'assets/images/Vendor.png',
                      title: "Vendor",
                      subtitle: "I Want To Sell My Products",
                      height: cardHeight,
                      onTap: () {
                        Navigator.pushNamed(context, "/vendorlogin");
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final double height;
  final VoidCallback onTap;

  const RoleCard({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.height,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 100),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
