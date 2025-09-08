import 'package:carocart/Apis/address_service.dart';
import 'package:carocart/Apis/cart_service.dart';
import 'package:carocart/Utils/LocationPicker.dart';
import 'package:flutter/material.dart';

class AppNavbar extends StatefulWidget implements PreferredSizeWidget {
  const AppNavbar({super.key});

  @override
  State<AppNavbar> createState() => _AppNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
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
      setState(() {
        selectedLocation = null;
        lat = null;
        lng = null;
      });
    } finally {
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
            // Location picker
            InkWell(
              onTap: _pickLocation,
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 32),
                  if (isLoadingAddress)
                    const Text("Loading...", style: TextStyle(fontSize: 16))
                  else
                    Text(
                      (selectedLocation != null &&
                              selectedLocation!.length > 25)
                          ? "${selectedLocation!.substring(0, 25)}..."
                          : selectedLocation ?? "Choose location",
                      style: const TextStyle(fontSize: 16),
                    ),
                  const Icon(Icons.keyboard_arrow_down, size: 20),
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
                        onPressed: () {
                          Navigator.pushNamed(context, "/usercart");
                        },
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
