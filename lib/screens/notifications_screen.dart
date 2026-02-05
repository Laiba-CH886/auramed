import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';

  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Push Notifications"),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text("Appointment Reminders"),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text("Health Tips & Updates"),
              value: false,
              onChanged: (v) {},
            ),
          ],
        ),
      ),
    );
  }
}
