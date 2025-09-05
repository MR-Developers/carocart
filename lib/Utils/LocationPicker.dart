import 'package:carocart/Apis/address_service.dart';
import 'package:carocart/Utils/Messages.dart';
import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;

class LocationPicker extends StatefulWidget {
  final String apiKey;

  const LocationPicker({super.key, required this.apiKey});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  final TextEditingController controller = TextEditingController();
  bool _isLoading = false;

  GoogleMapController? mapController;
  LatLng? selectedLatLng;

  List<Map<String, dynamic>> myAddresses = []; // <-- list of saved addresses

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace(widget.apiKey);
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final res = await AddressService.getMyAddresses(context);
    if (mounted) {
      setState(() {
        myAddresses = res;
      });
    }
  }

  void autoCompleteSearch(String value) async {
    if (value.isNotEmpty) {
      var result = await googlePlace.autocomplete.get(value);
      if (result != null && result.predictions != null && mounted) {
        setState(() {
          predictions = result.predictions!;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          predictions = [];
        });
      }
    }
  }

  Future<void> _handlePlaceTap(AutocompletePrediction p) async {
    if (p.placeId == null) return;
    try {
      var details = await googlePlace.details.get(p.placeId!);
      if (details?.result?.geometry?.location != null) {
        var loc = details!.result!.geometry!.location!;
        setState(() {
          selectedLatLng = LatLng(loc.lat!, loc.lng!);
          predictions = [];
          controller.text = p.description ?? "";
        });
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(selectedLatLng!, 15),
        );
      } else {
        _showError("No coordinates found for this place.");
      }
    } catch (e) {
      _showError("Failed to load place details.");
    }
  }

  Future<void> _openMapAndAddAddress() async {
    setState(() => _isLoading = true);

    final location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled && !(await location.requestService())) {
      setState(() => _isLoading = false);
      return;
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied &&
        (await location.requestPermission()) != loc.PermissionStatus.granted) {
      setState(() => _isLoading = false);
      return;
    }

    final userLocation = await location.getLocation();
    if (userLocation.latitude == null || userLocation.longitude == null) {
      _showError("Unable to fetch current location.");
      setState(() => _isLoading = false);
      return;
    }

    final currentLatLng = LatLng(
      userLocation.latitude!,
      userLocation.longitude!,
    );
    setState(() => _isLoading = false);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MapPage(initialLatLng: currentLatLng, apiKey: widget.apiKey),
      ),
    );

    if (result != null) {
      final newAddress = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => AddAddressPage(
            lat: result["lat"],
            lng: result["lng"],
            description: result["description"],
          ),
        ),
      );

      if (newAddress != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppMessages.addressSuccess)),
        );
        _loadAddresses(); // refresh list
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),
      body: Stack(
        children: [
          Column(
            children: [
              // 🔍 Search bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Search location...",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (value.trim().isEmpty) {
                      setState(() {
                        predictions.clear();
                      });
                      return;
                    }
                    autoCompleteSearch(value);
                  },
                ),
              ),
              if (predictions.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: predictions.length,
                    itemBuilder: (context, index) {
                      var p = predictions[index];
                      return ListTile(
                        title: Text(p.description ?? ""),
                        onTap: () => _handlePlaceTap(p),
                      );
                    },
                  ),
                )
              else ...[
                // 🗺️ Open Map Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0.0),
                  child: Center(
                    child: InkWell(
                      onTap: _openMapAndAddAddress,
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange.shade400),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.orange,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.map, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Open Map",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ➕ Add Address Button (Styled)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GestureDetector(
                    onTap: _openMapAndAddAddress,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade600,
                            Colors.green.shade400,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_location_alt,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Add Address",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 🏠 Your Addresses
                if (myAddresses.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Your Addresses",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: myAddresses.length,
                      itemBuilder: (context, index) {
                        final address = myAddresses[index];
                        return ListTile(
                          title: Text(address["address"] ?? ""),
                          subtitle: Text(address["type"] ?? ""),
                          trailing: address["isDefault"] == true
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null,
                          onTap: () async {
                            final addressId = address["id"];

                            if (address["isDefault"] == true) {
                              // Already default → just return it
                              Navigator.pop(context, {
                                "lat": address["latitude"],
                                "lng": address["longitude"],
                                "description": address["address"],
                              });
                              return;
                            }

                            final success =
                                await AddressService.setDefaultAddress(
                                  context,
                                  addressId,
                                );

                            if (success) {
                              Navigator.pop(context, {
                                "lat": address["latitude"],
                                "lng": address["longitude"],
                                "description": address["address"],
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(AppMessages.error),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],

              // ✅ Confirm location when picked manually
              if (selectedLatLng != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context, {
                        "lat": selectedLatLng!.latitude,
                        "lng": selectedLatLng!.longitude,
                        "description": controller.text,
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Confirm Location",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  final LatLng initialLatLng;
  final String apiKey;

  const MapPage({super.key, required this.initialLatLng, required this.apiKey});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  LatLng? selectedLatLng;

  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedLatLng = widget.initialLatLng;
    googlePlace = GooglePlace(widget.apiKey);
  }

  void autoCompleteSearch(String value) async {
    if (value.isNotEmpty) {
      var result = await googlePlace.autocomplete.get(value);
      if (result != null && result.predictions != null && mounted) {
        setState(() {
          predictions = result.predictions!;
        });
      }
    } else {
      setState(() {
        predictions = [];
      });
    }
  }

  Future<void> _handlePredictionTap(AutocompletePrediction p) async {
    if (p.placeId == null) return;

    try {
      var details = await googlePlace.details.get(p.placeId!);
      if (details != null && details.result != null) {
        var gLoc = details.result!.geometry?.location;
        if (gLoc?.lat != null && gLoc?.lng != null) {
          LatLng newPos = LatLng(gLoc!.lat!, gLoc.lng!);
          setState(() {
            selectedLatLng = newPos;
            predictions = [];
            searchController.text = p.description ?? "";
          });

          mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 15));
        } else {
          _showError("No coordinates found for this place.");
        }
      }
    } catch (e) {
      _showError("Failed to load place details.");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialLatLng,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => mapController = controller,
            markers: {
              if (selectedLatLng != null)
                Marker(
                  markerId: const MarkerId("selected"),
                  position: selectedLatLng!,
                ),
            },
            onTap: (pos) {
              setState(() {
                selectedLatLng = pos;
              });
            },
          ),

          // Search box
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search place...",
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                      suffixIcon: const Icon(Icons.search),
                    ),
                    onChanged: autoCompleteSearch,
                  ),
                ),

                // Predictions list
                if (predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      itemCount: predictions.length,
                      itemBuilder: (context, index) {
                        var p = predictions[index];
                        return ListTile(
                          title: Text(p.description ?? ""),
                          onTap: () => _handlePredictionTap(p),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Confirm button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                if (selectedLatLng != null) {
                  Navigator.pop(context, {
                    "lat": selectedLatLng!.latitude,
                    "lng": selectedLatLng!.longitude,
                    "description": searchController.text.isNotEmpty
                        ? searchController.text
                        : "Dropped Pin",
                  });
                }
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Confirm Location",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddAddressPage extends StatefulWidget {
  final double lat;
  final double lng;
  final String description;

  const AddAddressPage({
    super.key,
    required this.lat,
    required this.lng,
    required this.description,
  });

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();
  bool _isSaving = false;

  void _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final addressData = {
      "fullName": fullNameController.text,
      "phoneNumber": phoneController.text,
      "address": addressController.text,
      "latitude": widget.lat,
      "longitude": widget.lng,
      "type": typeController.text,
      "instructions": instructionsController.text,
    };

    final res = await AddressService.createAddress(context, addressData);

    setState(() => _isSaving = false);

    if (res != null) {
      Navigator.pop(context, res); // return created address
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppMessages.addressSuccess)));
    }
  }

  @override
  void initState() {
    super.initState();
    addressController.text = widget.description;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Address")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Full Address"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: "Type (Home/Work)",
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: instructionsController,
                decoration: const InputDecoration(labelText: "Instructions"),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save Address",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
