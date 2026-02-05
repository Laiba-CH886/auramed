import 'package:flutter/material.dart';

class AppearanceScreen extends StatelessWidget {
  static const routeName = '/appearance';

  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Appearance"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            RadioListTile(
              value: "light",
              groupValue: "light",
              onChanged: (v) {},
              title: const Text("Light Mode"),
            ),
            RadioListTile(
              value: "dark",
              groupValue: "light",
              onChanged: (v) {},
              title: const Text("Dark Mode"),
            ),
            RadioListTile(
              value: "system",
              groupValue: "light",
              onChanged: (v) {},
              title: const Text("System Default"),
            ),
          ],
        ),
      ),
    );
  }
}
