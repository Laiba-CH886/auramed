import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/reading.dart';
import 'package:auramed/screens/readings/add_manual_reading_screen.dart';
import 'package:auramed/screens/readings/reading_detail_screen.dart';

class ReadingsHistoryScreen extends StatelessWidget {
  static const routeName = '/readings-history';

  const ReadingsHistoryScreen({super.key});

  String _formatSleep(int? sleepMinutes) {
    if (sleepMinutes == null || sleepMinutes <= 0) return '--';
    final hours = sleepMinutes ~/ 60;
    final minutes = sleepMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String _formatWater(double? liters) {
    if (liters == null || liters <= 0) return '--';
    return '${liters.toStringAsFixed(1)} L';
  }

  String _formatStress(int? stressLevel) {
    if (stressLevel == null || stressLevel <= 0) return '--';
    return '$stressLevel%';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final readings = auth.getMyReadings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Health History'),
      ),
      body: readings.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: readings.length,
        itemBuilder: (context, index) {
          final r = readings[readings.length - 1 - index];

          final detailReading = Reading(
            type: 'Vitals',
            value:
            'HR: ${r.heartRate} bpm, BP: ${r.bp}, SpO₂: ${r.spo2}%, Sleep: ${_formatSleep(r.sleepMinutes)}, Stress: ${_formatStress(r.stressLevel)}, Water: ${_formatWater(r.waterIntakeLiters)}',
            date: r.timestamp,
            notes:
            'Heart Rate: ${r.heartRate} bpm\n'
                'Blood Pressure: ${r.bp}\n'
                'SpO₂: ${r.spo2}%\n'
                'Sleep: ${_formatSleep(r.sleepMinutes)}\n'
                'Stress: ${_formatStress(r.stressLevel)}\n'
                'Water Intake: ${_formatWater(r.waterIntakeLiters)}',
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text(
                'Vitals Record',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'HR ${r.heartRate} bpm • BP ${r.bp} • SpO₂ ${r.spo2}%\n'
                      'Sleep ${_formatSleep(r.sleepMinutes)} • Stress ${_formatStress(r.stressLevel)} • Water ${_formatWater(r.waterIntakeLiters)}\n'
                      '${r.timestamp.toString().substring(0, 16)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                    height: 1.4,
                  ),
                ),
              ),
              isThreeLine: true,
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).hintColor,
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  ReadingDetailScreen.routeName,
                  arguments: detailReading,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AddManualReadingScreen.routeName);
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Reading',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 72,
              color: Theme.of(context).hintColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No readings found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your saved vitals will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AddManualReadingScreen.routeName);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Reading'),
            ),
          ],
        ),
      ),
    );
  }
}