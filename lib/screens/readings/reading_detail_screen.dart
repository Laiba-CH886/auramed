import 'package:flutter/material.dart';
import 'package:auramed/models/reading.dart';

class ReadingDetailScreen extends StatelessWidget {
  static const routeName = '/reading-detail';

  const ReadingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Reading reading =
    ModalRoute.of(context)!.settings.arguments as Reading;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monitor_heart_rounded,
                  size: 60,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              reading.type,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reading.value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    Icons.calendar_today,
                    'Date',
                    reading.date.toString().substring(0, 10),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    Icons.access_time,
                    'Time',
                    reading.date.toString().substring(11, 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Reading Notes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Text(
                reading.notes ?? 'No additional notes provided for this reading.',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            if ((reading.notes ?? '').isNotEmpty) ...[
              Text(
                'Quick Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildSummaryCard(
                context,
                title: 'Vitals Overview',
                icon: Icons.analytics_outlined,
                content: reading.value,
              ),
              const SizedBox(height: 24),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('BACK TO HISTORY'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).hintColor),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required String content,
      }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}