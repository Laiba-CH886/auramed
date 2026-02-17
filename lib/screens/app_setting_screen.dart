import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/screens/privacy_and_security_screen.dart';
import 'package:auramed/screens/notifications_screen.dart';
import 'package:auramed/screens/Appearance_screen.dart';
import 'package:auramed/screens/Help_and_FAQ_Screen.dart';
import 'package:auramed/screens/contact_support_screen.dart';
import 'package:auramed/screens/about_AuraMed_screen.dart';

class AppSettingsScreen extends StatelessWidget {
  static const routeName = '/app-settings';

  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("App Settings"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Account & Security"),
          _buildSettingsTile(
            Icons.lock_outline, 
            "Privacy & Security", 
            "Manage your data and privacy",
            () => Navigator.pushNamed(context, PrivacySecurityScreen.routeName),
          ),
          
          _buildSectionHeader("Personalization"),
          _buildSettingsTile(
            Icons.notifications_none, 
            "Notifications", 
            "Set your alert preferences",
            () => Navigator.pushNamed(context, NotificationsScreen.routeName),
          ),
          _buildSettingsTile(
            Icons.palette_outlined, 
            "Appearance", 
            "Switch between light and dark mode",
            () => Navigator.pushNamed(context, AppearanceScreen.routeName),
          ),
          
          _buildSectionHeader("Support & Info"),
          _buildSettingsTile(
            Icons.help_outline, 
            "FAQ", 
            "Frequently asked questions",
            () => Navigator.pushNamed(context, HelpFaqScreen.routeName),
          ),
          _buildSettingsTile(
            Icons.support_agent, 
            "Contact Support", 
            "Get help from our team",
            () => Navigator.pushNamed(context, ContactSupportScreen.routeName),
          ),
          _buildSettingsTile(
            Icons.info_outline, 
            "About AuraMed", 
            "App version and legal info",
            () => Navigator.pushNamed(context, AboutAuraMedScreen.routeName),
          ),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: () {
              auth.logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
            },
            icon: const Icon(Icons.logout),
            label: const Text("LOGOUT"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text("Version 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8E9EFF), letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF8E9EFF).withAlpha(20), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF8E9EFF), size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      ),
    );
  }
}
