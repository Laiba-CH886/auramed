import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/screens/edit_profile_screen.dart';
import 'package:auramed/screens/app_setting_screen.dart';
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
    final fbUser = auth.firebaseUser;

    final displayName = u?.name.isNotEmpty == true
        ? u!.name
        : fbUser?.displayName ?? fbUser?.email?.split('@').first ?? 'User';

    final displayEmail = u?.email ?? fbUser?.email ?? '';
    final isDoctor = u?.role == UserRole.doctor;
    final initials =
    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, AppSettingsScreen.routeName),
          ),
        ],
      ),
      body: u == null && fbUser == null
          ? _buildNotLoggedIn(context)
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  u?.photoUrl != null && u!.photoUrl!.isNotEmpty
                      ? CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(u.photoUrl!),
                  )
                      : CircleAvatar(
                    radius: 50,
                    backgroundColor:
                    Theme.of(context).colorScheme.primary,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDoctor ? '🩺 DOCTOR' : '👤 PATIENT',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isDoctor) ...[
                    const SizedBox(height: 8),
                    if ((u?.phone ?? '').isNotEmpty)
                      Text(
                        '📞 ${u!.phone}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                  ],
                  if (!isDoctor && u != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if ((u.bloodGroup ?? '').isNotEmpty)
                          _infoPill(
                            context,
                            '🩸 ${u.bloodGroup}',
                            Colors.red.shade50,
                            Colors.red,
                          ),
                        if (u.age != null)
                          _infoPill(
                            context,
                            '🎂 Age ${u.age}',
                            Colors.blue.shade50,
                            Colors.blue,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Account & Settings",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _settingsTile(
              context,
              Icons.person_outline,
              "Edit Profile",
              "Update your personal info",
                  () => Navigator.pushNamed(
                context,
                EditProfileScreen.routeName,
              ),
            ),
            _settingsTile(
              context,
              Icons.notifications_none,
              "Notifications",
              "Manage your alerts",
                  () => Navigator.pushNamed(
                context,
                NotificationsScreen.routeName,
              ),
            ),
            _settingsTile(
              context,
              Icons.palette_outlined,
              "Appearance",
              "Switch between light and dark mode",
                  () => Navigator.pushNamed(
                context,
                AppearanceScreen.routeName,
              ),
            ),
            _settingsTile(
              context,
              Icons.help_outline,
              "Help & FAQ",
              "Common questions",
                  () => Navigator.pushNamed(
                context,
                HelpFaqScreen.routeName,
              ),
            ),
            _settingsTile(
              context,
              Icons.support_agent,
              "Contact Support",
              "Get technical help",
                  () => Navigator.pushNamed(
                context,
                ContactSupportScreen.routeName,
              ),
            ),
            _settingsTile(
              context,
              Icons.info_outline,
              "About AuraMed",
              "Version and legal info",
                  () => Navigator.pushNamed(
                context,
                AboutAuraMedScreen.routeName,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/role_selection',
                        (r) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  "SIGN OUT",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Not logged in',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/role_selection'),
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(
      BuildContext context,
      String text,
      Color lightBg,
      Color fg,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? fg.withOpacity(0.16) : lightBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _settingsTile(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.primary.withOpacity(0.18)
                : colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 18,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}