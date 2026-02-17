import 'package:flutter/material.dart';
import 'package:auramed/models/reading.dart';
import 'package:auramed/screens/readings/add_manual_reading_screen.dart';
import 'package:auramed/screens/readings/reading_detail_screen.dart';

class ReadingsHistoryScreen extends StatelessWidget {
  static const routeName = '/readings-history';
  const ReadingsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for now (smartwatch simulated)
    final readings = [
      Reading(type: 'Heart Rate', value: '78 bpm', date: DateTime.now().subtract(const Duration(hours: 2)), notes: 'Feeling calm'),
      Reading(type: 'Blood Pressure', value: '120/80', date: DateTime.now().subtract(const Duration(days: 1)), notes: 'Routine check'),
      Reading(type: 'Oxygen Level', value: '98%', date: DateTime.now().subtract(const Duration(days: 2)), notes: 'After morning walk'),
      Reading(type: 'Sugar Level', value: '95 mg/dL', date: DateTime.now().subtract(const Duration(days: 3)), notes: 'Fasting'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text('My Health History'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: readings.length,
        itemBuilder: (context, index) {
          final r = readings[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getIconColor(r.type).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIcon(r.type), color: _getIconColor(r.type)),
              ),
              title: Text(r.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text('${r.value} • ${r.date.toString().substring(0, 10)}', style: TextStyle(color: Colors.grey.shade600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  ReadingDetailScreen.routeName,
                  arguments: r,
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
        backgroundColor: const Color(0xFF8E9EFF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Reading', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  IconData _getIcon(String type) {
    if (type.contains('Heart')) return Icons.favorite;
    if (type.contains('Blood')) return Icons.bloodtype;
    if (type.contains('Oxygen')) return Icons.air;
    return Icons.monitor_weight;
  }

  Color _getIconColor(String type) {
    if (type.contains('Heart')) return Colors.redAccent;
    if (type.contains('Blood')) return Colors.blueAccent;
    if (type.contains('Oxygen')) return Colors.teal;
    return Colors.orangeAccent;
  }
}
