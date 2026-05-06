import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';

class AppearanceScreen extends StatefulWidget {
  static const routeName = '/appearance';

  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  bool _isSavingTheme = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.loadAppearanceSettings();
    });
  }

  Future<void> _changeTheme(String themeMode) async {
    setState(() => _isSavingTheme = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.updateAppearanceSettings(themeMode: themeMode);

    if (!mounted) return;
    setState(() => _isSavingTheme = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update theme mode'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final appearance = auth.appearanceSettings;
    final isLoading = auth.isAppearanceSettingsLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Appearance"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Theme Mode"),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildRadioTile(
                  title: "Light Mode",
                  value: "light",
                  icon: Icons.wb_sunny_outlined,
                  groupValue: appearance.themeMode,
                  enabled: !_isSavingTheme,
                  onChanged: (v) async {
                    if (v == null) return;
                    await _changeTheme(v);
                  },
                ),
                _buildRadioTile(
                  title: "Dark Mode",
                  value: "dark",
                  icon: Icons.dark_mode_outlined,
                  groupValue: appearance.themeMode,
                  enabled: !_isSavingTheme,
                  onChanged: (v) async {
                    if (v == null) return;
                    await _changeTheme(v);
                  },
                ),
                _buildRadioTile(
                  title: "System Default",
                  value: "system",
                  icon: Icons.settings_brightness,
                  groupValue: appearance.themeMode,
                  enabled: !_isSavingTheme,
                  onChanged: (v) async {
                    if (v == null) return;
                    await _changeTheme(v);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String value,
    required IconData icon,
    required String groupValue,
    required bool enabled,
    required Future<void> Function(String?) onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      secondary: Icon(icon, color: const Color(0xFF8E9EFF)),
      groupValue: groupValue,
      activeColor: const Color(0xFF8E9EFF),
      onChanged: enabled ? onChanged : null,
    );
  }
}