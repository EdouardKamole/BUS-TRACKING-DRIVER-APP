import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_bus_app/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String phone = '';
  String email = '';
  String photoUrl = '';

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    if (_user == null) return;
    final uid = _user!.uid;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          name = data['fullName'] ?? '';
          phone = data['phone'] ?? '';
          email = data['email'] ?? _user!.email ?? '';
          photoUrl = data['photoUrl'] ?? '';
          _nameController.text = name;
          _phoneController.text = phone;
        });
      } else {
        setState(() {
          email = _user!.email ?? '';
        });
      }
    } catch (e) {
      setState(() {});
      // Optionally show error
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          _isEditing
              ? Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.check_rounded, color: Colors.deepPurple),
                    tooltip: 'Save',
                    onPressed: _saveProfile,
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey),
                    tooltip: 'Cancel',
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _nameController.text = name;
                        _phoneController.text = phone;
                      });
                    },
                  ),
                ],
              )
              : IconButton(
                icon: Icon(Icons.edit_rounded, color: Colors.deepPurple),
                tooltip: 'Edit',
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
        ],
      ),
      body: Stack(
        children: [
          // Modern gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 100, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Placeholder avatar with border and shadow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 64,
                        color: Colors.deepPurple.shade300,
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  _buildProfileField(
                    label: 'Full Name',
                    icon: Icons.person,
                    controller: _nameController,
                    isEditing: _isEditing,
                  ),
                  SizedBox(height: 20),
                  _buildProfileField(
                    label: 'Phone Number',
                    icon: Icons.phone,
                    controller: _phoneController,
                    isEditing: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 20),
                  // Email (read-only)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.deepPurple.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.email, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                          shadowColor: Colors.deepPurpleAccent.withOpacity(0.2),
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        icon: Icon(Icons.save_rounded, color: Colors.white),
                        label: Text(
                          'Save Changes',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: _saveProfile,
                      ),
                    ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 4,
                        shadowColor: Colors.redAccent.withOpacity(0.2),
                      ),
                      icon: Icon(Icons.logout, color: Colors.white),
                      label: Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: _logout,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isEditing = false,
    TextInputType? keyboardType,
  }) {
    if (isEditing) {
      return TextFormField(
        controller: controller,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.white.withOpacity(0.85),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple.shade100),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple, width: 2),
          ),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label'.toLowerCase();
          }
          return null;
        },
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.deepPurple.shade100),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.text,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        name = _nameController.text;
        phone = _phoneController.text;
        _isEditing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }
}
