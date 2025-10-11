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
    DeliveryPartnerHome(),
    DeliveryPartnerOrder(),
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
    const primaryColor = Color(0xFF273E06);
    const accentColor = Color(0xFF4A6B1E); // Lighter shade for accents

    return Scaffold(
      // AppBar with custom theme
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 4,
        shadowColor: Colors.black26,
      ),

      // PageView for swipe functionality
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _screens,
      ),

      // Bottom Navigation Bar with custom theme
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
