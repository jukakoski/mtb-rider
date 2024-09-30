import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

void main() {
  runApp(const MtbRiderApp());
}

class MtbRiderApp extends StatelessWidget {
  const MtbRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTB Rider',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _mapReady = false; // New flag to check if the map is ready

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission;

    setState(() {
      // Set a mock location (example: a location in Prague)
      _currentLocation = const LatLng(50.0755, 14.4378);
    });

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Set a fallback or show a message
      setState(() {
        _currentLocation = const LatLng(50.0755, 14.4378); // Mock location
      });
      // Location services are not enabled, show a message to the user
      return;
    }

    // Request permission
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Set a fallback or show a message
      setState(() {
        _currentLocation = const LatLng(50.0755, 14.4378); // Mock location
      });
      // Permission denied, show a message to the user
      return;
    }

    // Get the current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    // Only move the map if the map is ready
    if (_mapReady && _currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  void _centralizeMap() {
    if (_currentLocation != null && _mapReady) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MTB Rider'),
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? const LatLng(50.0755, 14.4378), // Default to Prague
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                maxZoom: 18.0,
                onMapReady: () {
                  // Set the map as ready when the map is fully initialized
                  setState(() {
                    _mapReady = true;
                  });

                  // Once the map is ready, move to the current location
                  if (_currentLocation != null) {
                    _mapController.move(_currentLocation!, 15.0);
                  }
                },
                onPositionChanged: (MapPosition position, bool hasGesture) {
                  // Do something if needed when the map is moved
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.mtbmap.cz/mtbmap_tiles/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  tileProvider: CancellableNetworkTileProvider(), // Using cancellable tile provider
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _currentLocation!,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centralizeMap,
        tooltip: 'Center to My Location',
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }
}
