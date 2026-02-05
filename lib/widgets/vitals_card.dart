import 'package:flutter/material.dart';

class VitalsCard extends StatelessWidget {
  final int heartRate;
  final String bp;
  final int spo2;
  final VoidCallback onEmergency;

  const VitalsCard({
    super.key,
    required this.heartRate,
    required this.bp,
    required this.spo2,
    required this.onEmergency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Heart Rate', style: Theme.of(context).textTheme.bodySmall),
              Text('$heartRate bpm', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Blood Pressure', style: Theme.of(context).textTheme.bodySmall),
              Text(bp, style: Theme.of(context).textTheme.bodyLarge),
            ]),
          ),
          Container(width: 1, height: 70, color: Colors.grey[200]),
          const SizedBox(width: 12),
          Column(children: [
            CircleAvatar(radius: 28, backgroundColor: const Color(0xFFFFC1E3), child: Text('$spo2%', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: onEmergency,
              icon: const Icon(Icons.warning),
              label: const Text('Emergency'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A6BFF)),
            )
          ])
        ]),
      ),
    );
  }
}
