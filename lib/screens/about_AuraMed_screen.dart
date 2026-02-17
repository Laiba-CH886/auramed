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
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 15)]),
              child: Image.asset('assets/images/logo.png', height: 100),
            ),
            const SizedBox(height: 24),
            const Text("AuraMed", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF8E9EFF))),
            const Text("Your Smart Health Companion", style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            const Text("Version 1.0.0", style: TextStyle(fontWeight: FontWeight.w500)),
            const Divider(height: 48),
            
            _buildAboutSection("Our Mission", "AuraMed is designed to bridge the gap between patients and healthcare providers. We leverage smart technology to provide real-time health monitoring and seamless communication."),
            const SizedBox(height: 24),
            
            _buildLinkTile(Icons.description_outlined, "Terms of Service"),
            _buildLinkTile(Icons.privacy_tip_outlined, "Privacy Policy"),
            _buildLinkTile(Icons.code, "Open Source Licenses"),
            
            const SizedBox(height: 40),
            const Text("© 2026 AuraMed Inc. All rights reserved.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(color: Colors.grey.shade800, height: 1.5, fontSize: 15)),
      ],
    );
  }

  Widget _buildLinkTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8E9EFF)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
      onTap: () {},
    );
  }
}
