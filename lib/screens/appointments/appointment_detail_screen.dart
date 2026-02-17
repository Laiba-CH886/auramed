import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/appointment_provider.dart';
import 'package:auramed/screens/consultation/consultation_chat_screen.dart';

class AppointmentDetailScreen extends StatelessWidget {
  static const routeName = '/appointment-detail';
  const AppointmentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentId = ModalRoute.of(context)!.settings.arguments as String;
    final appointmentProv = Provider.of<AppointmentProvider>(context);
    final appt = appointmentProv.getAppointmentById(appointmentId);

    if (appt == null) {
      return Scaffold(body: const Center(child: Text('Appointment not found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reason: ${appt.reason}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Date: ${appt.date.toString().substring(0, 16)}'),
            const SizedBox(height: 8),
            Text('Status: ${appt.status.name.toUpperCase()}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, ConsultationChatScreen.routeName, arguments: appointmentId);
                },
                icon: const Icon(Icons.chat),
                label: const Text('Enter Consultation Chat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
