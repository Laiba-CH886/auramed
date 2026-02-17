import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/screens/edit_profile_screen.dart';
import 'package:auramed/screens/app_setting_screen.dart';
import 'package:auramed/screens/privacy_and_security_screen.dart';
import 'package:auramed/screens/notifications_screen.dart';
import 'package:auramed/screens/Appearance_screen.dart';
import 'package:auramed/screens/Help_and_FAQ_Screen.dart';
import 'package:auramed/screens/contact_support_screen.dart';
import 'package:auramed/screens/about_AuraMed_screen.dart';

class ProfileScreen extends StatelessWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final u = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("My Profile"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppSettingsScreen.routeName),
          )
        ],
      ),
      body: u == null
          ? const Center(child: Text("Not logged in"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF8E9EFF),
                          child: Text(
                            u.name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(u.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(u.email, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        Chip(
                          label: Text(u.role == UserRole.doctor ? 'DOCTOR' : 'PATIENT'),
                          backgroundColor: const Color(0xFF8E9EFF).withAlpha(30),
                          labelStyle: const TextStyle(color: Color(0xFF8E9EFF), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text("Account & Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _settingsTile(Icons.person_outline, "Edit Profile", "Update your personal info", () => Navigator.pushNamed(context, EditProfileScreen.routeName)),
                  _settingsTile(Icons.lock_outline, "Privacy & Security", "Password and data protection", () => Navigator.pushNamed(context, PrivacySecurityScreen.routeName)),
                  _settingsTile(Icons.notifications_none, "Notifications", "Manage your alerts", () => Navigator.pushNamed(context, NotificationsScreen.routeName)),
                  _settingsTile(Icons.palette_outlined, "Appearance", "Theme and font sizes", () => Navigator.pushNamed(context, AppearanceScreen.routeName)),
                  _settingsTile(Icons.help_outline, "Help & FAQ", "Common questions", () => Navigator.pushNamed(context, HelpFaqScreen.routeName)),
                  _settingsTile(Icons.support_agent, "Contact Support", "Get technical help", () => Navigator.pushNamed(context, ContactSupportScreen.routeName)),
                  _settingsTile(Icons.info_outline, "About AuraMed", "Version and legal info", () => Navigator.pushNamed(context, AboutAuraMedScreen.routeName)),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        auth.logout();
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                      },
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text("SIGN OUT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
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
