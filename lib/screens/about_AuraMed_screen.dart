import 'package:flutter/material.dart';

class AboutAuraMedScreen extends StatelessWidget {
  static const routeName = '/about';

  const AboutAuraMedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("About AuraMed"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// LOGO CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo.png',
                height: 100,
              ),
            ),

            const SizedBox(height: 24),

            /// APP NAME
            Text(
              "AuraMed",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Your Smart Health Companion",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Version 1.0.0",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),

            const Divider(height: 48),

            /// ABOUT SECTION
            _buildAboutSection(
              context,
              "Our Mission",
              "AuraMed is designed to bridge the gap between patients and healthcare providers. "
                  "We leverage smart technology to provide real-time health monitoring and seamless communication.",
            ),

            const SizedBox(height: 40),

            /// FOOTER
            Text(
              "© 2026 AuraMed Inc. All rights reserved.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(
      BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
      ],
    );
  }
}