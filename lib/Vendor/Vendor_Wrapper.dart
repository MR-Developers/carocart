import 'package:carocart/Vendor/Vendor_Home.dart';
import 'package:carocart/Vendor/Vendor_Order.dart';
import 'package:carocart/Vendor/Vendor_Products.dart';
import 'package:carocart/Vendor/Vendor_Profile.dart';
import 'package:flutter/material.dart';

class VendorWrapper extends StatefulWidget {
  final String vendorName;
  const VendorWrapper({super.key, this.vendorName = "Vendor"});

  @override
  State<VendorWrapper> createState() => _VendorWrapperState();
}

class _VendorWrapperState extends State<VendorWrapper> {
  int _selectedIndex = 0;

  // List of pages
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      VendorHomePage(vendorName: widget.vendorName),
      VendorOrderPage(),
      VendorProducts(),
      VendorProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0D1B2A),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: const Center(child: Text("Profile Page")),
    );
  }
}
