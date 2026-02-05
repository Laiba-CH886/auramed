import 'package:flutter/material.dart';

class AppSettingsScreen extends StatelessWidget {
  static const routeName = '/app-settings';

  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("App Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text("Enable Auto Sync"),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text("Enable Location Access"),
              value: false,
              onChanged: (v) {},
            ),
          ],
        ),
      ),
    );
  }
}
