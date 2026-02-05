import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/user.dart';

// Import new screens
import 'package:auramed/screens/app_setting_screen.dart';
import 'package:auramed/screens/privacy_and_security_screen.dart';
import 'package:auramed/screens/notifications_screen.dart';
import 'package:auramed/screens/appearance_screen.dart';
import 'package:auramed/screens/Help_and_FAQ_Screen.dart';
import 'package:auramed/screens/contact_support_screen.dart';
import 'package:auramed/screens/about_auramed_screen.dart';

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
        title: const Text("Profile"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),

      body: u == null
          ? const Center(child: Text("Not logged in"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =======================
            //   PROFILE HEADER CARD
            // =======================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E9EFF), Color(0xFFB2C2FF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(77),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Text(
                        u.name
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join()
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          u.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          u.role == UserRole.doctor ? 'Doctor' : 'Patient',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // EDIT PROFILE BUTTON
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C73FF),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.edit),
              label: const Text("Edit Profile"),
            ),

            const SizedBox(height: 25),

            // =====================
            //   ACCOUNT SETTINGS
            // =====================
            const Text(
              "Account Settings",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            _settingsTile(
              Icons.settings,
              "App Settings",
                  () => Navigator.pushNamed(context, AppSettingsScreen.routeName),
            ),
            _settingsTile(
              Icons.lock,
              "Privacy & Security",
                  () => Navigator.pushNamed(context, PrivacySecurityScreen.routeName),
            ),
            _settingsTile(
              Icons.notifications,
              "Notifications",
                  () => Navigator.pushNamed(context, NotificationsScreen.routeName),
            ),
            _settingsTile(
              Icons.brightness_6,
              "Appearance (Dark Mode)",
                  () => Navigator.pushNamed(context, AppearanceScreen.routeName),
            ),

            const SizedBox(height: 25),

            // =====================
            //       SUPPORT
            // =====================
            const Text(
              "Support",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            _settingsTile(
              Icons.help_outline,
              "Help & FAQ",
                  () => Navigator.pushNamed(context, HelpFaqScreen.routeName),
            ),
            _settingsTile(
              Icons.mail_outline,
              "Contact Support",
                  () => Navigator.pushNamed(context, ContactSupportScreen.routeName),
            ),

            const SizedBox(height: 25),

            // =====================
            //         ABOUT
            // =====================
            const Text(
              "About",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            _settingsTile(
              Icons.info_outline,
              "About AuraMed",
                  () => Navigator.pushNamed(context, AboutAuraMedScreen.routeName),
            ),

            const SizedBox(height: 25),

            // LOGOUT BUTTON
            ElevatedButton.icon(
              onPressed: () {
                auth.logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text("Sign Out"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
