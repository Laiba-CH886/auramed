import 'package:flutter/material.dart';

class HelpFaqScreen extends StatelessWidget {
  static const routeName = '/help';

  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Help & FAQ"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: const [
            ExpansionTile(
              title: Text("How do I book an appointment?"),
              children: [Padding(padding: EdgeInsets.all(16), child: Text("You can book appointments through the dashboard."))],
            ),
            ExpansionTile(
              title: Text("How do I reset my password?"),
              children: [Padding(padding: EdgeInsets.all(16), child: Text("Go to Privacy settings and select Reset Password."))],
            ),
          ],
        ),
      ),
    );
  }
}
