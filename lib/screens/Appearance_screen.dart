import 'package:flutter/material.dart';

class AppearanceScreen extends StatefulWidget {
  static const routeName = '/appearance';
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  String _selectedTheme = "light";
  double _fontSize = 14.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Appearance"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Theme Mode"),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildRadioTile("Light Mode", "light", Icons.wb_sunny_outlined),
                _buildRadioTile("Dark Mode", "dark", Icons.dark_mode_outlined),
                _buildRadioTile("System Default", "system", Icons.settings_brightness),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("Font Size"),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Small", style: TextStyle(fontSize: 12)),
                      SizedBox(
                        width: 200,
                        child: Slider(
                          value: _fontSize,
                          min: 12,
                          max: 20,
                          divisions: 4,
                          activeColor: const Color(0xFF8E9EFF),
                          onChanged: (v) => setState(() => _fontSize = v),
                        ),
                      ),
                      const Text("Large", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  Text("Sample Text Preview", style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildRadioTile(String title, String value, IconData icon) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      secondary: Icon(icon, color: const Color(0xFF8E9EFF)),
      groupValue: _selectedTheme,
      activeColor: const Color(0xFF8E9EFF),
      onChanged: (v) => setState(() => _selectedTheme = v!),
    );
  }
}
