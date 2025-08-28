import 'package:flutter/material.dart';

class AppNavbar extends StatefulWidget implements PreferredSizeWidget {
  final int cartCount;
  final Function()? onCartTap;
  final Function()? onLoginTap;
  final Function()? onSellerTap;
  final Function()? onProfileTap;

  const AppNavbar({
    super.key,
    this.cartCount = 0,
    this.onCartTap,
    this.onLoginTap,
    this.onSellerTap,
    this.onProfileTap,
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
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, "/");
              },
              child: Row(
                children: [
                  Image.asset("assets/images/AppIcon.jpg", height: 40),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const Spacer(),

            // Location
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Open location selector")),
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 20),
                  const Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),

            Row(children: [const Icon(Icons.search, color: Colors.grey)]),
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
