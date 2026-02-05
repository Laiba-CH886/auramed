import 'package:flutter/material.dart';

class ContactSupportScreen extends StatelessWidget {
  static const routeName = '/support';

  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Contact Support"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Describe your issue...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6C73FF),
                minimumSize: Size(double.infinity, 50),
              ),
              child: const Text("Send Message"),
            )
          ],
        ),
      ),
    );
  }
}
