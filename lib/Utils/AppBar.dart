import 'package:flutter/material.dart';

class AppNavbar extends StatefulWidget implements PreferredSizeWidget {
  final int cartCount;
  final String? userName;
  final String? profileImageUrl;
  final String userLocation;
  final Function()? onCartTap;
  final Function()? onLoginTap;
  final Function()? onSellerTap;
  final Function()? onProfileTap;
  final Function(String searchTerm)? onSearch;

  const AppNavbar({
    super.key,
    required this.userLocation,
    this.cartCount = 0,
    this.userName,
    this.profileImageUrl,
    this.onCartTap,
    this.onLoginTap,
    this.onSellerTap,
    this.onProfileTap,
    this.onSearch,
  });

  @override
  State<AppNavbar> createState() => _AppNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _AppNavbarState extends State<AppNavbar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.userName != null;

    return AppBar(
      elevation: 2,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Logo
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, "/");
            },
            child: Row(
              children: [
                Image.asset("assets/CC.png", height: 40),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "CaroCart",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "Ur Trusted Partner",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
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
                const SizedBox(width: 4),
                Text(
                  widget.userLocation.length > 20
                      ? "${widget.userLocation.substring(0, 20)}..."
                      : widget.userLocation,
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 20),
              ],
            ),
          ),
          const Spacer(),

          // Search Bar
          Expanded(
            flex: 3,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Search products...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        if (widget.onSearch != null) {
                          widget.onSearch!(value);
                        }
                      },
                      onChanged: (value) {
                        setState(() => _isSearching = value.isNotEmpty);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          // Cart
          if (isLoggedIn)
            Stack(
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
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),

          // Auth / Profile
          isLoggedIn
              ? GestureDetector(
                  onTap: widget.onProfileTap,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: widget.profileImageUrl != null
                            ? NetworkImage(widget.profileImageUrl!)
                            : null,
                        child: widget.profileImageUrl == null
                            ? Text(widget.userName![0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(widget.userName!),
                    ],
                  ),
                )
              : Row(
                  children: [
                    TextButton.icon(
                      onPressed: widget.onSellerTap,
                      icon: const Icon(Icons.storefront, size: 18),
                      label: const Text("Sell on CaroCart"),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: widget.onLoginTap,
                      icon: const Icon(Icons.person, size: 18),
                      label: const Text("Login / Register"),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
