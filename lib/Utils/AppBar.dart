import 'package:carocart/Apis/cart_service.dart';
import 'package:flutter/material.dart';

class AppNavbar extends StatefulWidget implements PreferredSizeWidget {
  final int cartCount;
  final String? selectedLocation;
  final Function()? onCartTap;
  final Function()? onLoginTap;
  final Function()? onSellerTap;
  final Function()? onProfileTap;
  final Function()? onLocationTap; // 👈 added callback

  const AppNavbar({
    super.key,
    this.cartCount = 0,
    this.selectedLocation = "Your Location",
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
  void initState() {
    getCartCount();
    super.initState();
  }

  void getCartCount() async {
    await CartService.getCart();
  }

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
                children: [
                  Icon(Icons.location_on, color: Colors.green, size: 32),
                  Text(
                    (widget.selectedLocation != null &&
                            widget.selectedLocation!.length > 25)
                        ? "${widget.selectedLocation!.substring(0, 25)}..."
                        : widget.selectedLocation ?? "",
                    style: TextStyle(fontSize: 16),
                  ),

                  Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
            const Spacer(),
            // Cart
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ValueListenableBuilder<int>(
                valueListenable: CartService.cartCountNotifier,
                builder: (context, count, _) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_bag_rounded,
                          color: Colors.black54,
                        ),
                        onPressed: widget.onCartTap,
                      ),
                      if (count > 0)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 99 ? "99+" : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
