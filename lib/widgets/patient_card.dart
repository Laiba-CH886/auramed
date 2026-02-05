import 'package:flutter/material.dart';

class PatientCard extends StatelessWidget {
  final String name;
  final int age;
  final dynamic lastReading;

  const PatientCard({super.key, required this.name, required this.age, required this.lastReading});

  @override
  Widget build(BuildContext context) {
    final lr = lastReading;
    final lastStr = lr != null ? '${lr.heartRate} bpm • ${lr.bp}' : '--';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(child: Text(name.split(' ').map((e) => e[0]).take(2).join())),
        title: Text(name),
        subtitle: Text('Age $age • Last: $lastStr'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
