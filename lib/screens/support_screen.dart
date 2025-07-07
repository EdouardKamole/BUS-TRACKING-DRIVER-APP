import 'package:flutter/material.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Support & Help', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
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
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  color: Colors.white.withOpacity(0.93),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.support_agent_rounded, size: 36, color: Colors.deepPurple),
                            SizedBox(width: 12),
                            Text(
                              'Need Help?',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Contact our support team for any issues or questions.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 30),
                        TextField(
                          controller: _messageController,
                          maxLines: 4,
                          style: TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Describe your issue or question...',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.message_rounded, color: Colors.deepPurple),
                            contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.deepPurple.shade100),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.deepPurple.shade100),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _sendMessage(context);
                            },
                            icon: Icon(Icons.send_rounded, color: Colors.white),
                            label: Text('Send', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              elevation: 5,
                              shadowColor: Colors.deepPurpleAccent.withOpacity(0.15),
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        Divider(),
                        SizedBox(height: 10),
                        Text(
                          'Contact Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 15),
                        _buildContactOption(
                          icon: Icons.email,
                          title: 'Email Us',
                          subtitle: 'support@bechbus.com',
                          onTap: () {
                            // Implement email functionality
                          },
                        ),
                        _buildContactOption(
                          icon: Icons.phone,
                          title: 'Call Us',
                          subtitle: '+966 12 345 6789',
                          onTap: () {
                            // Implement call functionality
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 30, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _sendMessage(BuildContext context) {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter your message')));
      return;
    }

    // Implement message sending functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Your message has been sent to support')),
    );
    _messageController.clear();
  }
}
