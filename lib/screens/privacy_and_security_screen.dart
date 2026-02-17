import 'package:flutter/material.dart';

class PrivacySecurityScreen extends StatelessWidget {
  static const routeName = '/privacy';

  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Privacy & Security"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoBox("Your security is our top priority. We use industry-standard encryption to protect your medical data."),
          const SizedBox(height: 20),
          _buildSectionTitle("Account Security"),
          _buildTile(Icons.password, "Change Password", "Update your account password", () {}),
          _buildTile(Icons.phonelink_lock, "Two-Factor Authentication", "Add an extra layer of security", () {}),
          _buildTile(Icons.fingerprint, "Biometric Login", "Use Fingerprint or Face ID", () {}),
          
          const SizedBox(height: 20),
          _buildSectionTitle("Data Privacy"),
          _buildTile(Icons.visibility_off, "Privacy Policy", "How we handle your data", () {}),
          _buildTile(Icons.share, "Data Sharing", "Manage who can see your health logs", () {}),
          
          const SizedBox(height: 32),
          _buildDangerTile(Icons.delete_forever, "Delete Account", "Permanently remove your data", () {}),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.blue.shade900, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF8E9EFF)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    );
  }

  Widget _buildDangerTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade100)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.red)),
      ),
    );
  }
}
