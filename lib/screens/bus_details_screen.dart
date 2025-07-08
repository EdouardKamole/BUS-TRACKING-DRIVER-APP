// lib/screens/bus_details_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_bus_app/screens/live_bus_tracking_screen.dart';

class BusDetailsScreen extends StatelessWidget {
  // Mock data - replace with real data from Firebase later
  final String driverName = 'Ahmed Al-Mansour';
  final String plateNumber = 'ABC 1234';
  final String route = 'Route 5 - Al-Nakheel District';
  final String busPhotoUrl = 'https://example.com/bus.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(
  'Bus Details',
  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20.sp),
)),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Bus Information',
              style: GoogleFonts.poppins(fontSize: 22.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 20.h),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[200],
                image: DecorationImage(
                  image: NetworkImage(busPhotoUrl),
                  fit: BoxFit.cover,
                  onError:
                      (exception, stackTrace) =>
                          Icon(Icons.directions_bus, size: 100),
                ),
              ),
            ),
            SizedBox(height: 30),
            _buildDetailCard(
              icon: Icons.person,
              title: 'Driver',
              value: driverName,
            ),
            SizedBox(height: 15),
            _buildDetailCard(
              icon: Icons.confirmation_number,
              title: 'Plate Number',
              value: plateNumber,
            ),
            SizedBox(height: 15),
            _buildDetailCard(icon: Icons.route, title: 'Route', value: route),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveBusTrackingScreen(),
                  ),
                );
              },
              child: Text('View on Map', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16.sp)),

              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 30.sp, color: Colors.blue),
            SizedBox(width: 15.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey)),
                SizedBox(height: 5.h),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
