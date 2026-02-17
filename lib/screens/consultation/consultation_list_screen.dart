import 'package:flutter/material.dart';
import 'package:auramed/screens/consultation/consultation_chat_screen.dart';

class ConsultationListScreen extends StatelessWidget {
  static const routeName = '/consultation-list';
  const ConsultationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Consultations"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("💬 Active Consultations"),
          _buildConsultationCard(
            context,
            name: "John Doe",
            lastMsg: "I have a fever and headache...",
            time: "Feb 20 - 10:00 AM",
            isActive: true,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("✅ Completed Consultations"),
          _buildConsultationCard(
            context,
            name: "Sara Khan",
            lastMsg: "Thank you doctor, I feel better.",
            time: "Feb 18 - 02:00 PM",
            isActive: false,
          ),
          _buildConsultationCard(
            context,
            name: "Ali Ahmed",
            lastMsg: "Prescription received.",
            time: "Feb 15 - 11:30 AM",
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildConsultationCard(BuildContext context, {
    required String name,
    required String lastMsg,
    required String time,
    required bool isActive,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isActive ? const Color(0xFF6C73FF).withAlpha(30) : Colors.grey.withAlpha(30),
          child: Text(name[0], style: TextStyle(color: isActive ? const Color(0xFF6C73FF) : Colors.grey, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: isActive 
          ? const Icon(Icons.chevron_right, color: Color(0xFF6C73FF))
          : const Icon(Icons.check_circle, color: Colors.green, size: 20),
        onTap: () {
          if (isActive) {
            Navigator.pushNamed(
              context, 
              ConsultationChatScreen.routeName,
              arguments: "dummy_id", // In real app, pass actual appt/consult id
            );
          }
        },
      ),
    );
  }
}
