import 'package:carocart/User/UserHome.dart';
import 'package:flutter/material.dart';

class UserPagesWrapper extends StatefulWidget {
  final int initialIndex;
  final String initialTab;

  const UserPagesWrapper({
    super.key,
    this.initialTab = "FOOD",
    this.initialIndex = 0,
  });

  @override
  State<UserPagesWrapper> createState() => _UserPagesWrapperState();
}

class _UserPagesWrapperState extends State<UserPagesWrapper> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      UserHome(initialTab: widget.initialTab),
      const Center(child: Text("Search Page")),
      const Center(child: Text("Cart Page")),
      const Center(child: Text("Profile Page")),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Cart",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
