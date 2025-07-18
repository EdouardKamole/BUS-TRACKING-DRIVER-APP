// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print, use_rethrow_when_possible

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:school_bus_app/screens/live_bus_tracking_screen.dart';
import 'package:school_bus_app/screens/profile_screen.dart';
import 'package:school_bus_app/screens/support_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  bool isActive = false;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late final String driverId;
  LatLng busLocation = const LatLng(24.7236, 46.6853);
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    driverId = FirebaseAuth.instance.currentUser!.uid;
    _initializeFirebase();

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
    _animationController.dispose();
    super.dispose();
  }

  void _initializeFirebase() async {
    try {
      final snapshot =
          await _database
              .child('buses')
              .child(driverId)
              .child('location')
              .get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          isActive = data['isActive'] ?? false;
          final latitude = data['latitude'] as double?;
          final longitude = data['longitude'] as double?;
          if (latitude != null && longitude != null) {
            busLocation = LatLng(latitude, longitude);
          }
        });
      }
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  Future<void> _handleLocationAndFirebaseUpdateWithId(
    String driverId,
    bool newValue,
  ) async {
    if (newValue) {
      final status = await _requestLocationPermission();
      if (status == PermissionStatus.granted) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          await _updateFirebaseStatus(
            isActive: newValue,
            latitude: position.latitude,
            longitude: position.longitude,
          );
          setState(() {
            isActive = newValue;
            busLocation = LatLng(position.latitude, position.longitude);
          });
        } catch (e) {
          print('Error getting location: $e');
          setState(() {
            isActive = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get location. Please try again.'),
            ),
          );
        }
      } else {
        setState(() {
          isActive = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
      }
    } else {
      await _updateFirebaseStatus(isActive: newValue);
      setState(() {
        isActive = newValue;
      });
    }
  }

  Future<PermissionStatus> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services.')),
      );
      return PermissionStatus.denied;
    }

    PermissionStatus permission = await Permission.location.status;
    if (permission.isDenied) {
      permission = await Permission.location.request();
    }

    return permission;
  }

  Future<void> _updateFirebaseStatus({
    required bool isActive,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await _database.child('buses').child(driverId).child('location').set({
        'isActive': isActive,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating Firebase: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Subtle gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFf8fafc),
                  Color(0xFFe0c3fc),
                  Color(0xFF8ec5fc),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      _buildDriverHeader(context),
                      const SizedBox(height: 32),
                      _buildBusLocationCard(context),
                      const SizedBox(height: 32),
                      _buildQuickActionsGrid(context),
                      const SizedBox(height: 100), // Bottom padding for nav bar
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildDriverHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Dashboard',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bus Control Panel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? const Color(0xFFF97316).withOpacity(0.15)
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isActive ? const Color(0xFFF97316) : Colors.grey[400]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isActive
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color:
                          isActive ? const Color(0xFFF97316) : Colors.grey[500],
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isActive = !isActive;
                        });
                        _handleLocationAndFirebaseUpdateWithId(
                          driverId,
                          isActive,
                        );
                      },
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color:
                              isActive
                                  ? const Color(0xFFF97316)
                                  : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (val) {
                        setState(() {
                          isActive = val;
                        });
                        _handleLocationAndFirebaseUpdateWithId(driverId, val);
                      },
                      activeColor: const Color(0xFFF97316),
                      inactiveThumbColor: Colors.grey[400],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusLocationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Current Bus Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: FlutterMap(
              options: MapOptions(
                center: busLocation,
                zoom: 14,
                interactiveFlags:
                    InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/basic-v2/{z}/{x}/{y}@2x.png?key=atBiJT3x9AIw2gQtXqfP',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
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
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveBusTrackingScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.map_outlined,
                  size: 12.sp,
                  color: Color(0xFFF97316),
                ),
                label: Text(
                  'View Full Map',
                  style: GoogleFonts.poppins(
                    color: Color(0xFFF97316),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 4.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16.sp,
          mainAxisSpacing: 16.sp,
          childAspectRatio: 1.1,
          children: [
            _buildActionCard(
              context,
              icon: Icons.map_rounded,
              title: 'View Route',
              subtitle: 'Live tracking',
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveBusTrackingScreen(),
                  ),
                );
              },
            ),

            _buildActionCard(
              context,
              icon: Icons.support_agent_rounded,
              title: 'Support',
              subtitle: 'Get help',
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SupportScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(vertical: 10.sp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            offset: const Offset(0, 8),
            blurRadius: 32,
          ),
        ],
        gradient: LinearGradient(
          colors: [
            gradient.colors.first.withOpacity(0.94),
            gradient.colors.last.withOpacity(0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.10),
          highlightColor: Colors.white.withOpacity(0.08),
          child: Padding(
            padding: EdgeInsets.all(10.sp),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8.sp),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 14.sp),
                ),
                SizedBox(width: 8.w),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: true,
              onTap: () {
                // Already on home
              },
            ),
            _buildNavItem(
              context,
              icon: Icons.map_rounded,
              label: 'Route',
              isActive: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveBusTrackingScreen(),
                  ),
                );
              },
            ),
            _buildNavItem(
              context,
              icon: Icons.person,
              label: 'Profile',
              isActive: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
        decoration: BoxDecoration(
          color:
              isActive
                  ? const Color(0xFFF97316).withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFF97316) : Colors.grey[500],
              size: 24,
            ),
            SizedBox(height: 4.sp),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: isActive ? const Color(0xFFF97316) : Colors.grey[500],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
