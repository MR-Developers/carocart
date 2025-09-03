import 'package:carocart/User/UserHome.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      UserHome(initialTab: widget.initialTab),
      const Center(child: Text("Search Page")),
      const Center(child: Text("Cart Page")),
      Center(
        child: GestureDetector(
          onTap: () => _logout(context),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(color: Colors.orange),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Logout", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green.shade700,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_rounded),
            label: "Cart",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
