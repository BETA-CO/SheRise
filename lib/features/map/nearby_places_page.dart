import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class NearbyPlacesPage extends StatefulWidget {
  const NearbyPlacesPage({super.key});

  @override
  State<NearbyPlacesPage> createState() => _NearbyPlacesPageState();
}

class _NearbyPlacesPageState extends State<NearbyPlacesPage> {
  final MapController _mapController = MapController();
  LatLng? _currentP;
  List<dynamic> _allPlaces = [];
  final List<String> _selectedFilters = [
    'hospital',
    'police',
    'pharmacy',
    'doctors',
  ];

  bool _mapReady = false;
  double _currentRotation = 0.0;
  bool _isSensorReliable = true;
  bool _isManualMoving = false;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;

  // Teal & Mint Theme Colors
  final Color _tealColor = const Color(0xFF00695C);
  final Color _mintColor = const Color(0xFFF2FCF9);

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _compassStream?.cancel();
    super.dispose();
  }

  Future<void> _initApp() async {
    // Permission handling
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentP = LatLng(position.latitude, position.longitude);
          _currentP = LatLng(position.latitude, position.longitude);
        });
        _fetchNearbyServices(position.latitude, position.longitude);
      }

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((pos) {
            if (mounted) {
              setState(() {
                _currentP = LatLng(pos.latitude, pos.longitude);
              });
            }
          });

      _compassStream = FlutterCompass.events?.listen((event) {
        if (event.heading != null && mounted) {
          double newHeading = event.heading!;
          setState(() {
            _currentRotation =
                _currentRotation + (newHeading - _currentRotation) * 0.12;
            _isSensorReliable = (event.accuracy ?? 0) > 0;
          });
          if (_mapReady && !_isManualMoving) {
            _mapController.rotate(-_currentRotation);
          }
        }
      });
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _fetchNearbyServices(double lat, double lng) async {
    final query =
        '[out:json];(node["amenity"~"hospital|police|pharmacy|doctors"](around:5000, $lat, $lng););out body;';
    final url =
        'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _allPlaces = json.decode(response.body)['elements'];
          });
        }
      } else {
        // Retry once on failure
        await Future.delayed(const Duration(seconds: 2));
        final retryResponse = await http.get(Uri.parse(url));
        if (retryResponse.statusCode == 200 && mounted) {
          setState(() {
            _allPlaces = json.decode(retryResponse.body)['elements'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching places: $e");
    }
  }

  // --- UPDATED: DIRECT NAVIGATION POPUP ---
  void _showNearestOptions() {
    if (_allPlaces.isEmpty || _currentP == null) return;

    Map<String, dynamic> nearestByCategory = {};
    const dist = Distance();

    for (var type in ['hospital', 'police', 'pharmacy', 'doctors']) {
      double shortest = double.infinity;
      dynamic closestNode;

      for (var p in _allPlaces) {
        if (p['tags']['amenity'] == type) {
          double d = dist.as(
            LengthUnit.Meter,
            _currentP!,
            LatLng(p['lat'], p['lon']),
          );
          if (d < shortest) {
            shortest = d;
            closestNode = p;
          }
        }
      }
      if (closestNode != null) {
        nearestByCategory[type] = {'node': closestNode, 'distance': shortest};
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Emergency Help: Select Type",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _tealColor,
                ),
              ),
              const SizedBox(height: 15),
              if (nearestByCategory.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No nearby services found in this area."),
                )
              else
                ...nearestByCategory.entries.map((entry) {
                  String type = entry.key;
                  var data = entry.value;
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _mintColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(type),
                        color: _getColorForType(type),
                      ),
                    ),
                    title: Text(
                      "Nearest ${type.toUpperCase()}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "${data['node']['tags']['name'] ?? 'Available'} • ${(data['distance'] / 1000).toStringAsFixed(1)} km",
                    ),
                    trailing: Icon(Icons.navigation, color: _tealColor),
                    onTap: () {
                      Navigator.pop(context);
                      _launchDirectNavigation(
                        data['node']['lat'],
                        data['node']['lon'],
                      );
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchDirectNavigation(double lat, double lng) async {
    final String url = Platform.isAndroid
        ? 'google.navigation:q=$lat,$lng&mode=d'
        : 'http://maps.apple.com/?daddr=$lat,$lng';

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
    } else {
      debugPrint("Could not launch navigation");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "nearby_title".tr(),
          style: TextStyle(fontWeight: FontWeight.bold, color: _tealColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _tealColor),
      ),
      body: _currentP == null
          ? Center(child: CircularProgressIndicator(color: _tealColor))
          : Stack(
              children: [
                // 1. Map Layer (Full Screen)
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentP!,
                    initialZoom: 15.0,
                    onMapReady: () => setState(() => _mapReady = true),
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture) setState(() => _isManualMoving = true);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.sherise.project_app',
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),

                // 2. Header Gradient (Background for AppBar & Filters)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 160,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Top Controls (Filters & Compass)
                Positioned(
                  top: 100, // Below standard AppBar height
                  left: 0,
                  right: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildTopFilters()],
                  ),
                ),

                // 4. North Arrow (Top Right, below filters to avoid overlap)
                if (_mapReady)
                  Positioned(
                    top: 110,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isManualMoving = false);
                        _mapController.rotate(0);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Transform.rotate(
                          angle:
                              (_mapController.camera.rotation *
                              (3.14159 / 180)),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.redAccent,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 5. Warnings
                if (!_isSensorReliable) _buildCalibrationWarning(),

                // 6. Recenter Button (Bottom Right)
                Positioned(
                  bottom: 100, // Above FAB
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: "recenter_btn",
                    backgroundColor: Colors.white,
                    child: Icon(Icons.my_location, color: _tealColor),
                    onPressed: () {
                      setState(() {
                        _isManualMoving = false;
                        if (_currentP != null)
                          _mapController.move(_currentP!, 15.0);
                      });
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNearestOptions,
        label: const Text(
          "Find Nearest Help",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.emergency, color: Colors.white),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  List<Marker> _buildMarkers() {
    if (_currentP == null) return [];
    return [
      Marker(
        point: _currentP!,
        width: 80,
        height: 80,
        child: Transform.rotate(
          angle: _currentRotation * (3.14159 / 180),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(Icons.navigation, color: Colors.blue, size: 40),
            ],
          ),
        ),
      ),
      ..._allPlaces
          .where((p) => _selectedFilters.contains(p['tags']['amenity']))
          .map((p) {
            return Marker(
              point: LatLng(p['lat'], p['lon']),
              rotate: true,
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showPlaceDetails(
                  p['tags']['name'] ?? 'Service',
                  p['lat'],
                  p['lon'],
                ),
                child: Icon(
                  _getIconForType(p['tags']['amenity']),
                  color: _getColorForType(p['tags']['amenity']),
                  size: 30,
                ),
              ),
            );
          })
          .toList(),
    ];
  }

  Widget _buildTopFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ['hospital', 'police', 'pharmacy', 'doctors'].map((cat) {
          bool sel = _selectedFilters.contains(cat);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                cat.toUpperCase(),
                style: TextStyle(
                  color: sel ? _tealColor : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              selected: sel,
              backgroundColor: Colors.white,
              selectedColor: _mintColor,
              checkmarkColor: _tealColor,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: sel ? _tealColor : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (v) => setState(
                () => v
                    ? _selectedFilters.add(cat)
                    : _selectedFilters.remove(cat),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalibrationWarning() {
    return Positioned(
      bottom: 140,
      left: 40,
      right: 40,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Calibrate: Move phone in ∞ shape",
          style: TextStyle(color: Colors.white, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  IconData _getIconForType(String type) => type == 'hospital'
      ? Icons.local_hospital
      : type == 'police'
      ? Icons.local_police
      : type == 'pharmacy'
      ? Icons.medication
      : Icons.medical_services;

  Color _getColorForType(String type) => type == 'hospital'
      ? Colors.red
      : type == 'police'
      ? Colors.blue
      : type == 'pharmacy'
      ? Colors.orange
      : Colors.pinkAccent;

  void _showPlaceDetails(String name, double lat, double lon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 200,
        child: Column(
          children: [
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _tealColor,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _tealColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.directions),
              label: const Text("Get Directions"),
              onPressed: () {
                Navigator.pop(context);
                _launchDirectNavigation(lat, lon);
              },
            ),
          ],
        ),
      ),
    );
  }
}
