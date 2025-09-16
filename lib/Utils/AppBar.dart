import 'package:carocart/Apis/address_service.dart';
import 'package:carocart/Apis/cart_service.dart';
import 'package:carocart/Utils/LocationPicker.dart';
import 'package:flutter/material.dart';

class AppNavbar extends StatefulWidget implements PreferredSizeWidget {
  final Function(String? location, double? lat, double? lng) onLocationChanged;

  const AppNavbar({super.key, required this.onLocationChanged});

  @override
  State<AppNavbar> createState() => _AppNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _AppNavbarState extends State<AppNavbar> {
  String? selectedLocation;
  double? lat;
  double? lng;
  bool isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
    CartService.getCart(); // preload cart
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final addresses = await AddressService.getMyAddresses(context);
      if (!mounted) return;

      final defaultAddress = addresses.firstWhere(
        (a) => a["isDefault"] == true,
        orElse: () =>
            addresses.isNotEmpty ? addresses.first : <String, dynamic>{},
      );

      if (defaultAddress.isNotEmpty) {
        setState(() {
          lat = defaultAddress["latitude"];
          lng = defaultAddress["longitude"];
          selectedLocation =
              defaultAddress["address"] ?? defaultAddress["description"];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        selectedLocation = null;
        lat = null;
        lng = null;
      });
    } finally {
      if (!mounted) return;
      setState(() => isLoadingAddress = false);
    }
  }

  Future<void> _pickLocation() async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPicker(
          apiKey: "AIzaSyAJ0oDKBoCOF6cOEttl3Yf8QU8gFRrI4FU",
        ),
      ),
    );

    if (result != null) {
      setState(() {
        selectedLocation = result["description"];
        lat = result["lat"];
        lng = result["lng"];
      });
    }
    widget.onLocationChanged(selectedLocation, lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
        child: Row(
          children: [
            // Location Selector
            Expanded(
              child: InkWell(
                onTap: _pickLocation,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFE8F5E9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: isLoadingAddress
                            ? const Text(
                                "Fetching your location...",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              )
                            : Text(
                                selectedLocation != null
                                    ? (selectedLocation!.length > 28
                                          ? "${selectedLocation!.substring(0, 28)}..."
                                          : selectedLocation!)
                                    : "Choose your location",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 22,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Cart with badge
            ValueListenableBuilder<int>(
              valueListenable: CartService.cartCountNotifier,
              builder: (context, count, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: Colors.orange.shade400,
                      borderRadius: BorderRadius.circular(16),
                      elevation: count > 0 ? 6 : 2,
                      shadowColor: Colors.orangeAccent.withOpacity(0.5),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pushNamed(context, "/usercart");
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Icon(
                            Icons.shopping_bag,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.6),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            count > 99 ? "99+" : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
