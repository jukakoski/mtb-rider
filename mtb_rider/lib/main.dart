import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_compass/flutter_compass.dart';

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
  LatLng? _lastLocation;
  bool _mapReady = false; // New flag to check if the map is ready
  double? _currentHeading; // Store the current compass heading

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    FlutterCompass.events?.listen((CompassEvent event) {
      setState(() {
        _currentHeading = event.heading;
      });
    });

    StreamSubscription positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
        timeLimit: Duration(seconds: 10),
      ),
    ).listen(
      (Position position) {
        // If the last location is not null, calculate the distance
        if (_lastLocation != null) {
          double distance = Geolocator.distanceBetween(
            _lastLocation!.latitude,
            _lastLocation!.longitude,
            position.latitude,
            position.longitude,
          );

          // if the distance is greater than 10 meters, update the last location
          if (distance > 10) {
            _lastLocation = LatLng(position.latitude, position.longitude);

            // Update the current location
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
            });

            // move the map if the map is ready
/*             if (_mapReady && _currentLocation != null) {
              _mapController.move(_currentLocation!, 15.0);
            } */
          }

          debugPrint('Distance: $distance meters');
        } else {
          // If the last location is null, update the last location and the current location
          _lastLocation = LatLng(position.latitude, position.longitude);

          // Update the current location
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });

          // move the map if the map is ready
          if (_mapReady && _currentLocation != null) {
            _mapController.move(_currentLocation!, 15.0);
          }
        }

        debugPrint(
            'Current Latitude: ${position.latitude}, Longitude: ${position.longitude}');
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission;

    if (_currentLocation == null) {
      setState(() {
        // Set a mock location (example: a location in Prague)
        _currentLocation = const LatLng(50.0755, 14.4378);
      });
    }

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

  LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
    timeLimit: Duration(seconds: 10),
  );

  void _centralizeMap() {
    // get my current location
    _getCurrentLocation();
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
                initialCenter: _currentLocation ??
                    const LatLng(50.0755, 14.4378), // Default to Prague
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
                  tileProvider:
                      CancellableNetworkTileProvider(), // Using cancellable tile provider
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
                // Add the compass symbol overlay
                if (_currentHeading != null)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Transform.rotate(
                      angle: _currentHeading! *
                          (3.141592653589793 /
                              180), // Convert degrees to radians
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.red,
                        size: 50.0,
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centralizeMap,
        tooltip: 'Keskitä kartta omaan sijaintiin',
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }
}
