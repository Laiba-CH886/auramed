import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  static const routeName = '/notifications';
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _appts = true;
  bool _chat = true;
  bool _reminders = false;
  bool _email = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Notification Settings"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationSection(
            "App Alerts",
            [
              _buildSwitchTile("Appointment Alerts", "Get notified about status changes", _appts, (v) => setState(() => _appts = v)),
              _buildSwitchTile("Chat Messages", "New messages from your doctor", _chat, (v) => setState(() => _chat = v)),
              _buildSwitchTile("Health Reminders", "Daily vitals and checkup alerts", _reminders, (v) => setState(() => _reminders = v)),
            ],
          ),
          const SizedBox(height: 24),
          _buildNotificationSection(
            "External Alerts",
            [
              _buildSwitchTile("Email Notifications", "Weekly health summary and reports", _email, (v) => setState(() => _email = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF8E9EFF))),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      activeColor: const Color(0xFF8E9EFF),
      onChanged: onChanged,
    );
  }
}
