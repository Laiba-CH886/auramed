import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactSupportScreen extends StatelessWidget {
  static const routeName = '/support';

  const ContactSupportScreen({super.key});

  static const String _email = 'laibachauhdry@gmail.com';
  static const String _phone = '03010400192';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Get Help"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "How can we help?",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You can contact us through email or phone.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 24),

            _buildContactMethod(
              context: context,
              icon: Icons.mail_outline,
              title: "Email Us",
              value: _email,
              onCopy: () => _copyToClipboard(
                context,
                _email,
                "Email copied",
              ),
            ),
            _buildContactMethod(
              context: context,
              icon: Icons.phone_outlined,
              title: "Call Us",
              value: _phone,
              onCopy: () => _copyToClipboard(
                context,
                _phone,
                "Phone number copied",
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _buildContactMethod({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onCopy,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.primary.withOpacity(0.18)
                    : colorScheme.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onCopy,
              tooltip: 'Copy',
              icon: Icon(
                Icons.copy_rounded,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}