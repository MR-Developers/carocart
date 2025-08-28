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

    var details = await googlePlace.details.get(p.placeId!);
    if (details != null && details.result != null) {
      var loc = details.result!.geometry?.location;
      if (loc != null) {
        setState(() {
          selectedLatLng = LatLng(loc.lat!, loc.lng!);
          predictions = [];
          controller.text = p.description ?? "";
        });

        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(selectedLatLng!, 15),
        );
      }
    }
  }

  Future<void> _openMap() async {
    // Use the alias to avoid clash
    loc.Location location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    loc.LocationData userLocation = await location.getLocation();
    LatLng currentLatLng = LatLng(
      userLocation.latitude!,
      userLocation.longitude!,
    );

    setState(() {
      selectedLatLng = currentLatLng;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentLatLng,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            markers: {
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Search location...",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: _openMap,
                ),
              ),
              onChanged: autoCompleteSearch,
            ),
          ),
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
        ],
      ),
      floatingActionButton: selectedLatLng != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, {
                  "lat": selectedLatLng!.latitude,
                  "lng": selectedLatLng!.longitude,
                  "description": controller.text,
                });
              },
              label: const Text("Confirm"),
              icon: const Icon(Icons.check),
            )
          : null,
    );
  }
}
