import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';

class AppNavbar extends StatefulWidget implements PreferredSizeWidget {
  final int cartCount;
  final Function()? onCartTap;
  final Function()? onLoginTap;
  final Function()? onSellerTap;
  final Function()? onProfileTap;
  final Function()? onLocationTap; // 👈 added callback

  const AppNavbar({
    super.key,
    this.cartCount = 0,
    this.onCartTap,
    this.onLoginTap,
    this.onSellerTap,
    this.onProfileTap,
    this.onLocationTap, // 👈 init
  });

  @override
  State<AppNavbar> createState() => _AppNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _AppNavbarState extends State<AppNavbar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 2,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      foregroundColor: Colors.black,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Row(
          children: [
            // Location
            InkWell(
              onTap: widget.onLocationTap, // 👈 notify parent
              child: Row(
                children: const [
                  Icon(Icons.location_on, color: Colors.green, size: 20),
                  Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
            const Spacer(),
            // Cart
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: widget.onCartTap,
                  ),
                  if (widget.cartCount > 0)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        widget.cartCount > 99
                            ? "99+"
                            : widget.cartCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
