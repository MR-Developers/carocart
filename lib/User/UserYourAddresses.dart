import 'package:carocart/Apis/address_service.dart';
import 'package:flutter/material.dart';

class YourAddressesPage extends StatefulWidget {
  const YourAddressesPage({super.key});

  @override
  State<YourAddressesPage> createState() => _YourAddressesPageState();
}

class _YourAddressesPageState extends State<YourAddressesPage> {
  List<Map<String, dynamic>> myAddresses = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => loading = true);

    try {
      final addresses = await AddressService.getMyAddresses(context);
      if (mounted) {
        setState(() {
          myAddresses = addresses;
          loading = false;
        });
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load addresses")));
    }
  }

  Future<void> _setDefaultAddress(int addressId) async {
    final success = await AddressService.setDefaultAddress(context, addressId);
    if (success) {
      await _fetchAddresses(); // refresh list
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Default address updated")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to set default address")),
      );
    }
  }

  Future<void> _deleteAddress(int addressId) async {
    final success = await AddressService.deleteAddress(context, addressId);
    if (success) {
      await _fetchAddresses();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Address deleted")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to delete address")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Your Addresses")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Addresses"),
        backgroundColor: Colors.green.shade600,
      ),
      body: myAddresses.isEmpty
          ? const Center(child: Text("No addresses added yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myAddresses.length,
              itemBuilder: (context, index) {
                final address = myAddresses[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: address["isDefault"] == true
                        ? Border.all(color: Colors.green.shade600, width: 2)
                        : null,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      address["address"] ?? "",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    subtitle: Text(
                      address["type"] ?? "",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    leading: address["isDefault"] == true
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.location_on, color: Colors.orange),
                    trailing: PopupMenuButton<String>(
                      color: Colors.white,
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) async {
                        if (value == 'default') {
                          await _setDefaultAddress(address["id"]);
                        } else if (value == 'delete') {
                          await _deleteAddress(address["id"]);
                        } else if (value == 'edit') {
                          final result = await Navigator.pushNamed(
                            context,
                            '/usereditaddress',
                            arguments: address, // pass the full address map
                          );

                          // If result is true, refresh addresses list
                          if (result == true) {
                            await _fetchAddresses();
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            if (address["isDefault"] != true)
                              const PopupMenuItem<String>(
                                value: 'default',
                                child: Text('Set as Default'),
                              ),
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
