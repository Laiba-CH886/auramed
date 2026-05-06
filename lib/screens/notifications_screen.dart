import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  static const routeName = '/notifications';

  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isSavingAppointment = false;
  bool _isSavingChat = false;
  bool _isSavingReminders = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.loadNotificationSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final settings = auth.notificationSettings;
    final isLoading = auth.isNotificationSettingsLoading;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Settings"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationSection(
            context,
            "App Alerts",
            accent,
            [
              _buildSwitchTile(
                context: context,
                title: "Appointment Alerts",
                subtitle: "Show alerts related to appointments",
                value: settings.appointmentAlerts,
                isSaving: _isSavingAppointment,
                onChanged: (v) async {
                  setState(() => _isSavingAppointment = true);
                  final ok = await auth.updateNotificationSetting(
                    appointmentAlerts: v,
                  );
                  if (!mounted) return;
                  setState(() => _isSavingAppointment = false);

                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to update Appointment Alerts',
                        ),
                      ),
                    );
                  }
                },
              ),
              _buildSwitchTile(
                context: context,
                title: "Chat Messages",
                subtitle: "Show alerts when doctor sends a message",
                value: settings.chatMessages,
                isSaving: _isSavingChat,
                onChanged: (v) async {
                  setState(() => _isSavingChat = true);
                  final ok = await auth.updateNotificationSetting(
                    chatMessages: v,
                  );
                  if (!mounted) return;
                  setState(() => _isSavingChat = false);

                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to update Chat Messages',
                        ),
                      ),
                    );
                  }
                },
              ),
              _buildSwitchTile(
                context: context,
                title: "Health Reminders",
                subtitle: "Daily vitals and checkup alerts",
                value: settings.healthReminders,
                isSaving: _isSavingReminders,
                onChanged: (v) async {
                  setState(() => _isSavingReminders = true);
                  final ok = await auth.updateNotificationSetting(
                    healthReminders: v,
                  );
                  if (!mounted) return;
                  setState(() => _isSavingReminders = false);

                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to update Health Reminders',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(
      BuildContext context,
      String title,
      Color accentColor,
      List<Widget> children,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: accentColor,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required bool isSaving,
    required Future<void> Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: value,
      onChanged: isSaving ? null : onChanged,
      secondary: isSaving
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : null,
    );
  }
}