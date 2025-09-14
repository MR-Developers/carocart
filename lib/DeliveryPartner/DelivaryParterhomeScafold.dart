import 'package:flutter/material.dart';
import 'package:carocart/DeliveryPartner/DelivaryPartnerOrders.dart';
import 'package:carocart/DeliveryPartner/DelivaryPartnerProfile.dart';
import './DelivaryPartnerHome.dart';

class DelivaryParterHomeScafold extends StatefulWidget {
  const DelivaryParterHomeScafold({super.key});

  @override
  State<DelivaryParterHomeScafold> createState() =>
      _DelivaryParterHomeScafoldState();
}

class _DelivaryParterHomeScafoldState extends State<DelivaryParterHomeScafold> {
  int _selectedIndex = 0;

  // Controller for PageView
  late PageController _pageController;

  // Titles for the AppBar based on the selected tab
  final List<String> _titles = const ['Home', 'Orders', 'Profile'];

  // Screens for each tab
  final List<Widget> _screens = const [
    DelivaryParterHome(),
    DelivaryParterOrder(),
    DeliveryPartnerProfile(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Handle bottom nav tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Handle swipe
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Single AppBar for all screens
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🚫 Removes the back arrow
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
      ),

      // PageView for swipe functionality
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _screens,
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
