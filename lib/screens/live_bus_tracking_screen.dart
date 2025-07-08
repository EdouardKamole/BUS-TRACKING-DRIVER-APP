import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:open_route_service/open_route_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveBusTrackingScreen extends StatefulWidget {
  const LiveBusTrackingScreen({Key? key}) : super(key: key);

  @override
  _LiveBusTrackingScreenState createState() => _LiveBusTrackingScreenState();
}

class _LiveBusTrackingScreenState extends State<LiveBusTrackingScreen>
    with SingleTickerProviderStateMixin {
  LatLng busLocation = const LatLng(24.7236, 46.6853);
  List<Map<String, dynamic>> activeStudents = [];
  Map<String, dynamic>? selectedStudent;
  String? selectedStudentId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _userNamesCache = {};
  List<LatLng> routePoints = [];
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late final String driverId;
  final OpenRouteService openRouteService = OpenRouteService(
    apiKey: '5b3ce3597851110001cf624862ba9d9ce4314f088c7a3b8fec0f957e',
  );
  late AnimationController _animationController;
  late Animation<double> _animation;
  final MapController _mapController = MapController();

  late StreamSubscription<DatabaseEvent> _busLocationSubscription;
  late StreamSubscription<DatabaseEvent> _studentsSubscription;

  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    driverId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _subscribeBusLocation();
    _subscribeActiveStudents();
    _startLocationUpdates();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _busLocationSubscription.cancel();
    _studentsSubscription.cancel();
    _animationController.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return;
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      // Update location in Firebase
      _database.child('busLocation').set({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    });
  }

  // Fetch bus location from Firebase Realtime Database
  void _subscribeBusLocation() {
    _busLocationSubscription = _database
        .child('buses')
        .child(driverId)
        .child('location')
        .onValue
        .listen(
          (event) {
            if (!mounted) return;
            if (event.snapshot.exists) {
              final data = event.snapshot.value as Map<dynamic, dynamic>;
              final latitude = data['latitude'] as double?;
              final longitude = data['longitude'] as double?;
              if (latitude != null && longitude != null) {
                setState(() {
                  busLocation = LatLng(latitude, longitude);
                  _updateRoute();
                });
              }
            } else {
              print('No location data found for $driverId');
            }
          },
          onError: (error) {
            if (!mounted) return;
            print('Error fetching bus location: $error');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to fetch bus location from database.'),
              ),
            );
          },
        );
  }

  // Fetch all active students from Firebase
  void _subscribeActiveStudents() {
    _studentsSubscription = _database
        .child('students')
        .onValue
        .listen(
          (event) {
            if (!mounted) return;
            if (event.snapshot.exists) {
              final data = event.snapshot.value as Map<dynamic, dynamic>;
              final List<Map<String, dynamic>> updatedStudents = [];
              data.forEach((studentName, studentData) {
                final status = studentData['status'] as Map<dynamic, dynamic>?;
                if (status != null && status['isActive'] == true) {
                  final latitude = status['latitude'] as double?;
                  final longitude = status['longitude'] as double?;
                  if (latitude != null && longitude != null) {
                    updatedStudents.add({
                      'id': studentName,
                      'location': LatLng(latitude, longitude),
                    });
                  }
                }
              });
              _fetchAndSetStudentNames(updatedStudents).then((_) {
                setState(() {
                  activeStudents = updatedStudents;
                  // If no student is selected, select the first active student
                  if (activeStudents.isNotEmpty && selectedStudent == null) {
                    selectedStudent = activeStudents[0];
                    selectedStudentId = selectedStudent!['id'];
                    _updateRoute();
                  } else if (activeStudents.isEmpty) {
                    selectedStudent = null;
                    selectedStudentId = null;
                    routePoints = [];
                  } else if (selectedStudent != null &&
                      !activeStudents.any(
                        (s) => s['id'] == selectedStudent!['id'],
                      )) {
                    // If selected student is no longer active, reset selection
                    selectedStudent =
                        activeStudents.isNotEmpty ? activeStudents[0] : null;
                    selectedStudentId =
                        selectedStudent != null ? selectedStudent!['id'] : null;
                    _updateRoute();
                  }
                  _centerMap();
                });
              });
            } else {
              print('No student data found');
              setState(() {
                activeStudents = [];
                selectedStudent = null;
                routePoints = [];
              });
            }
          },
          onError: (error) {
            if (!mounted) return;
            print('Error fetching active students: $error');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to fetch student locations from database.',
                ),
              ),
            );
          },
        );
  }

  // Fetch and cache student names from Firestore
  Future<void> _fetchAndSetStudentNames(
    List<Map<String, dynamic>> students,
  ) async {
    for (final student in students) {
      final id = student['id'];
      if (!_userNamesCache.containsKey(id)) {
        try {
          final doc = await _firestore.collection('users').doc(id).get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            _userNamesCache[id] = data['fullName'] ?? id;
          } else {
            _userNamesCache[id] = id;
          }
        } catch (e) {
          _userNamesCache[id] = id;
        }
      }
    }
  }

  // Fetch route from bus to selected student using OpenRouteService
  Future<void> _updateRoute() async {
    if (selectedStudent == null) {
      setState(() {
        routePoints = [];
      });
      return;
    }
    try {
      final List<ORSCoordinate> routeCoordinates = await openRouteService
          .directionsRouteCoordsGet(
            startCoordinate: ORSCoordinate(
              latitude: busLocation.latitude,
              longitude: busLocation.longitude,
            ),
            endCoordinate: ORSCoordinate(
              latitude: selectedStudent!['location'].latitude,
              longitude: selectedStudent!['location'].longitude,
            ),
          );
      if (routeCoordinates.isNotEmpty) {
        setState(() {
          routePoints =
              routeCoordinates
                  .map((coord) => LatLng(coord.latitude, coord.longitude))
                  .toList();
        });
        _centerMap();
      } else {
        throw Exception('No route coordinates found');
      }
    } catch (e) {
      print('Error fetching route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch route from OpenRouteService.'),
        ),
      );
      setState(() {
        routePoints = [];
      });
    }
  }

  // Calculate center point among bus and selected student (or just bus if none selected)
  LatLng _calculateCenterPoint() {
    if (selectedStudent == null || activeStudents.isEmpty) {
      return busLocation;
    }
    final double totalLat =
        busLocation.latitude + selectedStudent!['location'].latitude;
    final double totalLon =
        busLocation.longitude + selectedStudent!['location'].longitude;
    return LatLng(totalLat / 2, totalLon / 2);
  }

  // Center map on bus and selected student
  void _centerMap() {
    _mapController.move(_calculateCenterPoint(), _mapController.zoom);
  }

  // Zoom in on the map
  void _zoomIn() {
    _mapController.move(_mapController.center, _mapController.zoom + 1);
  }

  // Zoom out on the map
  void _zoomOut() {
    _mapController.move(_mapController.center, _mapController.zoom - 1);
  }

  // Center map on bus location
  void _centerOnBus() {
    _mapController.move(busLocation, _mapController.zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Subtle gradient background for consistency
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () => Navigator.of(context).pop(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.98),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withOpacity(0.11),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.19),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.deepPurple,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
          // Map widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(center: _calculateCenterPoint(), zoom: 14),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              PolylineLayer(
                polylines: [
                  if (routePoints.isNotEmpty)
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.0,
                      color: Colors.green,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Bus marker
                  Marker(
                    point: busLocation,
                    width: 40,
                    height: 40,
                    child: ScaleTransition(
                      scale: _animation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // Active student markers
                  ...activeStudents.map(
                    (student) => Marker(
                      point: student['location'] as LatLng,
                      width:
                          selectedStudent != null &&
                                  selectedStudent!['id'] == student['id']
                              ? 48
                              : 40,
                      height:
                          selectedStudent != null &&
                                  selectedStudent!['id'] == student['id']
                              ? 48
                              : 40,
                      child: ScaleTransition(
                        scale: _animation,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                selectedStudent != null &&
                                        selectedStudent!['id'] == student['id']
                                    ? Colors.green
                                    : Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_pin_circle,
                                color: Colors.white,
                                size:
                                    (selectedStudent != null &&
                                            selectedStudent!['id'] ==
                                                student['id'])
                                        ? 32.0
                                        : 24.0,
                              ),
                              SizedBox(height: 2),
                              Text(
                                _userNamesCache[student['id']] ?? student['id'],
                                style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 2,
                                      color: Colors.black.withOpacity(0.5),
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.directions_bus, color: Colors.red),
                    onPressed: _centerOnBus,
                    tooltip: 'Center on Bus Location',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.black),
                    onPressed: _zoomIn,
                    tooltip: 'Zoom In',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.remove, color: Colors.black),
                    onPressed: _zoomOut,
                    tooltip: 'Zoom Out',
                  ),
                ),
              ],
            ),
          ),
          // Floating Back Button
          Positioned(
            top: 40,
            left: 20,
            child: Material(
              color: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back',
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Student',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value:
                          activeStudents.any(
                                (student) => student['id'] == selectedStudentId,
                              )
                              ? selectedStudentId
                              : null,
                      hint: const Text('Select a student'),
                      items:
                          activeStudents
                              .where((student) => student['id'] != null)
                              .map((student) {
                                final id = student['id'] as String;
                                final fullName = _userNamesCache[id] ?? id;
                                return DropdownMenuItem<String>(
                                  value: id,
                                  child: Text(fullName),
                                );
                              })
                              .toList(),
                      onChanged: (String? newId) {
                        setState(() {
                          selectedStudentId = newId;
                          selectedStudent = activeStudents.firstWhere(
                            (student) => student['id'] == newId,
                          );
                          _updateRoute();
                        });
                      },
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
