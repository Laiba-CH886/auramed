import 'package:flutter/material.dart';

class HealthTipsScreen extends StatelessWidget {
  static const routeName = '/health-tips';
  const HealthTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text('Daily Health Tips'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTipCard(Icons.local_drink, "Stay Hydrated", "Drink at least 8 glasses of water a day to keep your organs functioning and skin glowing.", Colors.blue),
          _buildTipCard(Icons.directions_run, "Daily Exercise", "A 30-minute brisk walk can significantly lower the risk of heart disease and improve mood.", Colors.green),
          _buildTipCard(Icons.bedtime, "Prioritize Sleep", "Getting 7-9 hours of quality sleep helps your body repair and enhances cognitive function.", Colors.deepPurple),
          _buildTipCard(Icons.restaurant, "Balanced Diet", "Include more fiber, lean proteins, and healthy fats in your diet while reducing processed sugar.", Colors.orange),
          _buildTipCard(Icons.visibility, "Digital Detox", "Reduce screen time 1 hour before bed to improve your circadian rhythm and sleep quality.", Colors.teal),
        ],
      ),
    );
  }

  Widget _buildTipCard(IconData icon, String title, String description, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 6),
                  Text(description, style: TextStyle(color: Colors.grey.shade700, height: 1.4, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
