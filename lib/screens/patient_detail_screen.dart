import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/providers/appointment_provider.dart';
import 'package:auramed/widgets/vitals_card.dart';
import 'package:auramed/screens/consultation/consultation_chat_screen.dart';
import 'package:auramed/screens/consultation/doctor_notes_screen.dart';
import 'package:auramed/models/user.dart';

class PatientDetailScreen extends StatelessWidget {
  static const routeName = '/patient_detail';
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final patientId = args != null ? args['id'] as String : 'p1';

    final auth = Provider.of<AuthProvider>(context);
    final appointmentProv = Provider.of<AppointmentProvider>(context);
    
    final patient = auth.registeredUsers.firstWhere(
      (u) => u.uid == patientId, 
      orElse: () => UserModel(uid: 'p1', name: 'John Doe', email: 'john@test.com', role: UserRole.patient, age: 25, bloodGroup: 'A+', phone: '+923001234567')
    );
    
    final readings = auth.readingsFor(patientId);
    final history = appointmentProv.getAppointmentsForPatient(patientId);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Patient Profile"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PATIENT HEADER INFO
            _buildProfileHeader(patient),
            const SizedBox(height: 24),
            
            // VITALS SECTION
            const Text("Latest Readings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            VitalsCard(
              heartRate: readings.isNotEmpty ? readings.last.heartRate : 0,
              bp: readings.isNotEmpty ? readings.last.bp : '--',
              spo2: readings.isNotEmpty ? readings.last.spo2 : 0,
              onEmergency: () {},
            ),
            
            const SizedBox(height: 24),
            
            // QUICK ACTIONS
            const Text("Consultation Tools", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.chat_outlined,
                    label: "Start Chat",
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, ConsultationChatScreen.routeName, arguments: "consult_$patientId"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.note_alt_outlined,
                    label: "Add Notes",
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, DoctorNotesScreen.routeName),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // HEALTH READINGS HISTORY
            const Text("Health History (Vitals)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            if (readings.isEmpty)
              const Center(child: Text("No health readings available."))
            else
              ...readings.reversed.take(3).map((r) => _buildReadingCard(r)),
            
            const SizedBox(height: 32),
            
            // MEDICAL HISTORY (Previous Appointments)
            const Text("Medical History (Appointments)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            if (history.isEmpty)
              const Center(child: Text("No previous appointments found."))
            else
              ...history.reversed.map((a) => _buildHistoryCard(a)),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel patient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)]),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF6C73FF),
            child: Text(patient.name[0].toUpperCase(), style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Age: ${patient.age ?? 'N/A'} | Blood: ${patient.bloodGroup ?? 'N/A'}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text(patient.phone ?? "No phone set", style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReadingCard(dynamic r) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.show_chart, color: Color(0xFF6C73FF)),
        title: Text('${r.bp} | ${r.heartRate} bpm | SpO₂ ${r.spo2}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('${r.timestamp}'.substring(0, 10)),
      ),
    );
  }

  Widget _buildHistoryCard(dynamic a) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.history, color: Colors.grey),
        title: Text(a.reason, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text('${a.date}'.substring(0, 10)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(8)),
          child: Text(a.status.name.toUpperCase(), style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
