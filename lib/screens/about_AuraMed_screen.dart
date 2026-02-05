import 'package:flutter/material.dart';

class AboutAuraMedScreen extends StatelessWidget {
  static const routeName = '/about';

  const AboutAuraMedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("About AuraMed"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: const Text(
          "AuraMed is a modern healthcare platform designed to "
              "connect patients and doctors seamlessly. Our goal is to "
              "simplify scheduling, consultations, and health tracking "
              "with a clean and secure interface.",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
