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

  @override
  void initState() {
    super.initState();
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
      if (details != null && details.result != null) {
        var gLoc = details.result!.geometry?.location;
        if (gLoc?.lat != null && gLoc?.lng != null) {
          setState(() {
            selectedLatLng = LatLng(gLoc!.lat!, gLoc.lng!);
            predictions = [];
            controller.text = p.description ?? "";
          });

          mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(selectedLatLng!, 15),
          );
        } else {
          _showError("No coordinates found for this place.");
        }
      }
    } catch (e) {
      _showError("Failed to load place details.");
    }
  }

  Future<void> _openMap() async {
    setState(() => _isLoading = true);

    loc.Location location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        setState(() => _isLoading = false);
        return;
      }
    }

    loc.LocationData userLocation = await location.getLocation();
    if (userLocation.latitude == null || userLocation.longitude == null) {
      _showError("Unable to fetch current location.");
      setState(() => _isLoading = false);
      return;
    }

    LatLng currentLatLng = LatLng(
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
      Navigator.pop(context, {
        "lat": result["lat"],
        "lng": result["lng"],
        "description": result["description"],
      });
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // your main content
          Column(
            children: [
              // Search box
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Search location...",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: autoCompleteSearch,
                ),
              ),

              // Open Map Button (centered below search field)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0.0),
                child: Center(
                  child: InkWell(
                    onTap: _openMap,
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.map, size: 20, color: Colors.black87),
                            SizedBox(width: 8),
                            Text(
                              "Open Map",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Predictions list
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
              ),

              // Confirm button
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

          // 🔥 Loader Overlay
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
      appBar: AppBar(
        title: const Text("Pick Location"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
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
