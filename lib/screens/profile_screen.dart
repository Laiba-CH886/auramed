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

    // ✅ Try auth.user first, fallback to firebaseUser for name/email
    final u = auth.user;
    final fbUser = auth.firebaseUser;

    final displayName = u?.name.isNotEmpty == true
        ? u!.name
        : fbUser?.displayName ?? fbUser?.email?.split('@').first ?? 'User';
    final displayEmail = u?.email ?? fbUser?.email ?? '';
    final isDoctor = u?.role == UserRole.doctor;
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

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
            onPressed: () =>
                Navigator.pushNamed(context, AppSettingsScreen.routeName),
          )
        ],
      ),
      body: u == null && fbUser == null
          ? _buildNotLoggedIn(context)
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar & Info ─────────────────────────────────────
            Center(
              child: Column(
                children: [
                  // Photo or initials avatar
                  u?.photoUrl != null && u!.photoUrl!.isNotEmpty
                      ? CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(u.photoUrl!),
                  )
                      : CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF8E9EFF),
                    child: Text(
                      initials,
                      style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(displayName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(displayEmail,
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  // Role chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E9EFF)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDoctor ? '🩺 DOCTOR' : '👤 PATIENT',
                      style: const TextStyle(
                        color: Color(0xFF8E9EFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // Extra doctor fields
                  if (isDoctor) ...[
                    const SizedBox(height: 8),
                    if ((u?.phone ?? '').isNotEmpty)
                      Text('📞 ${u!.phone}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600)),
                  ],

                  // Extra patient fields
                  if (!isDoctor && u != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if ((u.bloodGroup ?? '').isNotEmpty)
                          _infoPill(
                              '🩸 ${u.bloodGroup}', Colors.red.shade50,
                              Colors.red),
                        if (u.age != null) ...[
                          const SizedBox(width: 8),
                          _infoPill('🎂 Age ${u.age}',
                              Colors.blue.shade50, Colors.blue),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text("Account & Settings",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // ── Settings Tiles ────────────────────────────────────
            _settingsTile(
              Icons.person_outline,
              "Edit Profile",
              "Update your personal info",
                  () => Navigator.pushNamed(
                  context, EditProfileScreen.routeName),
            ),
            _settingsTile(
              Icons.lock_outline,
              "Privacy & Security",
              "Password and data protection",
                  () => Navigator.pushNamed(
                  context, PrivacySecurityScreen.routeName),
            ),
            _settingsTile(
              Icons.notifications_none,
              "Notifications",
              "Manage your alerts",
                  () => Navigator.pushNamed(
                  context, NotificationsScreen.routeName),
            ),
            _settingsTile(
              Icons.palette_outlined,
              "Appearance",
              "Theme and font sizes",
                  () => Navigator.pushNamed(
                  context, AppearanceScreen.routeName),
            ),
            _settingsTile(
              Icons.help_outline,
              "Help & FAQ",
              "Common questions",
                  () => Navigator.pushNamed(
                  context, HelpFaqScreen.routeName),
            ),
            _settingsTile(
              Icons.support_agent,
              "Contact Support",
              "Get technical help",
                  () => Navigator.pushNamed(
                  context, ContactSupportScreen.routeName),
            ),
            _settingsTile(
              Icons.info_outline,
              "About AuraMed",
              "Version and legal info",
                  () => Navigator.pushNamed(
                  context, AboutAuraMedScreen.routeName),
            ),

            const SizedBox(height: 32),

            // ── Sign Out ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (!context.mounted) return;
                  // ✅ Fixed: navigate to /role_selection, not '/'
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/role_selection', (r) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  "SIGN OUT",
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Not logged in state ───────────────────────────────────────────────────
  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Not logged in',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(
                context, '/role_selection'),
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _infoPill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _settingsTile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8E9EFF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
          Icon(icon, color: const Color(0xFF8E9EFF), size: 22),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right,
            size: 18, color: Colors.grey),
      ),
    );
  }
}