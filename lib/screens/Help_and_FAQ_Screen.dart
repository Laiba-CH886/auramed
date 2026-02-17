import 'package:flutter/material.dart';

class HelpFaqScreen extends StatelessWidget {
  static const routeName = '/help';
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Help & FAQ"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("How can we help you?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildFaqItem("How do I book an appointment?", "Navigate to the Appointments section from your dashboard, tap the 'Book' button, select a doctor, date, and time, and confirm your booking."),
          _buildFaqItem("Where can I see my health history?", "Your health logs are available in the 'Readings' section. You can view heart rate, blood pressure, and more over time."),
          _buildFaqItem("How do I contact my doctor?", "Once an appointment is approved, a 'Start Chat' button will appear in the appointment details screen."),
          _buildFaqItem("Is my data secure?", "Yes, AuraMed uses end-to-end encryption for all medical records and chat communications."),
          _buildFaqItem("Can I use AuraMed offline?", "You can view cached data, but booking appointments and real-time syncing require an internet connection."),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(answer, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
          )
        ],
      ),
    );
  }
}
