import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("App Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Personalization", colorScheme.primary),
          _buildSettingsTile(
            context,
            Icons.notifications_none,
            "Notifications",
            "Set your alert preferences",
                () => Navigator.pushNamed(context, NotificationsScreen.routeName),
          ),
          _buildSettingsTile(
            context,
            Icons.palette_outlined,
            "Appearance",
            "Switch between light and dark mode",
                () => Navigator.pushNamed(context, AppearanceScreen.routeName),
          ),
          const SizedBox(height: 8),
          _buildSectionHeader("Support & Info", colorScheme.primary),
          _buildSettingsTile(
            context,
            Icons.help_outline,
            "FAQ",
            "Frequently asked questions",
                () => Navigator.pushNamed(context, HelpFaqScreen.routeName),
          ),
          _buildSettingsTile(
            context,
            Icons.support_agent,
            "Contact Support",
            "Get help from our team",
                () => Navigator.pushNamed(context, ContactSupportScreen.routeName),
          ),
          _buildSettingsTile(
            context,
            Icons.info_outline,
            "About AuraMed",
            "App version and legal info",
                () => Navigator.pushNamed(context, AboutAuraMedScreen.routeName),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/role_selection', (r) => false);
            },
            icon: const Icon(Icons.logout),
            label: const Text("LOGOUT"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              "Version 1.0.0",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: accentColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
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
      margin: const EdgeInsets.only(bottom: 8),
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
                : colorScheme.primary.withOpacity(0.10),
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