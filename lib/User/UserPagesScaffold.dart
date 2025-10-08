import 'package:carocart/User/UserCart.dart';
import 'package:carocart/User/UserHome.dart';
import 'package:carocart/User/UserOrders.dart';
import 'package:carocart/User/UserProfile.dart';
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

class _UserPagesWrapperState extends State<UserPagesWrapper>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late List<Widget> _pages;
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      UserHome(initialTab: widget.initialTab),
      UserOrdersPage(),
      UserCartPage(),
      UserProfilePage(),
    ];

    // Initialize animation controllers for each nav item
    _animationControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.1,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    // Animate the initially selected item
    _animationControllers[_currentIndex].forward();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _animationControllers[_currentIndex].reverse();
        _currentIndex = index;
        _animationControllers[_currentIndex].forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: "Home",
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long_rounded,
                  label: "Orders",
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.shopping_bag_rounded,
                  label: "Cart",
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: "Profile",
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimations[index],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.orange.shade700
                      : Colors.grey.shade600,
                  size: 26,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: isSelected
                      ? Colors.orange.shade700
                      : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
