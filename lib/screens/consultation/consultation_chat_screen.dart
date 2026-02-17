import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/appointment_provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/screens/consultation/doctor_notes_screen.dart';
import 'package:auramed/models/user.dart';

class ConsultationChatScreen extends StatefulWidget {
  static const routeName = '/consultation-chat';
  const ConsultationChatScreen({super.key});

  @override
  State<ConsultationChatScreen> createState() => _ConsultationChatScreenState();
}

class _ConsultationChatScreenState extends State<ConsultationChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hello Doctor, I have a fever and headache since yesterday.', 'isMe': false},
    {'text': 'Hello! Since how long exactly?', 'isMe': true},
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'isMe': true,
      });
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentId = ModalRoute.of(context)!.settings.arguments as String;
    final appointmentProv = Provider.of<AppointmentProvider>(context);
    final appt = appointmentProv.getAppointmentById(appointmentId);
    final auth = Provider.of<AuthProvider>(context);
    final isDoctor = auth.user?.role == UserRole.doctor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Consultation Chat', style: TextStyle(fontSize: 16)),
            Text('Ref: #${appt?.id.substring(appt?.id.length != null ? appt!.id.length - 5 : 0)}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          if (isDoctor)
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, DoctorNotesScreen.routeName),
              icon: const Icon(Icons.note_add, color: Color(0xFF6C73FF)),
              label: const Text("NOTES", style: TextStyle(color: Color(0xFF6C73FF), fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: msg['isMe'] ? const Color(0xFF6C73FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5)],
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(color: msg['isMe'] ? Colors.white : Colors.black87, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (isDoctor)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, DoctorNotesScreen.routeName),
                icon: const Icon(Icons.edit_note),
                label: const Text("📋 ADD MEDICAL NOTES"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade100,
                  foregroundColor: Colors.orange.shade900,
                  elevation: 0,
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(color: Colors.white),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(hintText: 'Type message...', border: InputBorder.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF6C73FF),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
