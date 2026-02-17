import 'package:flutter/material.dart';
import 'package:auramed/models/reading.dart';

class ReadingDetailScreen extends StatelessWidget {
  static const routeName = '/reading-detail';
  const ReadingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Reading reading = ModalRoute.of(context)!.settings.arguments as Reading;

    return Scaffold(
      appBar: AppBar(title: const Text('Reading Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E9EFF).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.show_chart, size: 60, color: const Color(0xFF8E9EFF)),
              ),
            ),
            const SizedBox(height: 24),
            Text(reading.type, style: const TextStyle(fontSize: 18, color: Colors.grey)),
            Text(reading.value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF8E9EFF))),
            const Divider(height: 40),
            
            _buildDetailRow(Icons.calendar_today, 'Date', reading.date.toString().substring(0, 10)),
            _buildDetailRow(Icons.access_time, 'Time', reading.date.toString().substring(11, 16)),
            const SizedBox(height: 20),
            
            const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                reading.notes ?? 'No additional notes provided for this reading.',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 40),
            
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
