import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/appointment_provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/appointment.dart';
import 'package:auramed/screens/patient_detail_screen.dart';

class DoctorAppointmentActionScreen extends StatefulWidget {
  static const routeName = '/doctor-appointment-action';
  const DoctorAppointmentActionScreen({super.key});

  @override
  State<DoctorAppointmentActionScreen> createState() => _DoctorAppointmentActionScreenState();
}

class _DoctorAppointmentActionScreenState extends State<DoctorAppointmentActionScreen> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentId = ModalRoute.of(context)!.settings.arguments as String;
    final appointmentProv = Provider.of<AppointmentProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    
    final appt = appointmentProv.getAppointmentById(appointmentId);
    if (appt == null) return const Scaffold(body: Center(child: Text("Error: Appointment not found")));

    final patient = auth.registeredUsers.firstWhere((u) => u.uid == appt.patientId);
    final readings = auth.readingsFor(appt.patientId);
    final lastReading = readings.isNotEmpty ? readings.last : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text('Appointment Action'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PATIENT BASIC INFO
            _buildInfoCard(
              child: Column(
                children: [
                  _buildDetailRow("Patient", patient.name),
                  _buildDetailRow("Date", appt.date.toString().substring(0, 10)),
                  _buildDetailRow("Time", appt.date.toString().substring(11, 16)),
                  _buildDetailRow("Reason", appt.reason),
                  _buildDetailRow("Status", appt.status.name.toUpperCase(), isStatus: true),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // HEALTH SUMMARY
            const Text("Patient Health Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildInfoCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem("BP", lastReading?.bp ?? "--"),
                  _buildSummaryItem("Heart Rate", "${lastReading?.heartRate ?? '--'} bpm"),
                  _buildSummaryItem("SpO2", "${lastReading?.spo2 ?? '--'}%"),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ACTIONS
            if (appt.status == AppointmentStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        appointmentProv.approveAppointment(appointmentId);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment Accepted")));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text("✅ ACCEPT"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        appointmentProv.rejectAppointment(appointmentId);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment Rejected")));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                      child: const Text("❌ REJECT"),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 32),
            
            // NOTES SECTION
            const Text("Add Consultation Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Type diagnosis or instructions...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notes saved locally")));
                },
                child: const Text("SAVE NOTES"),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // VIEW FULL DETAIL
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context, 
                    PatientDetailScreen.routeName,
                    arguments: {'id': patient.uid, 'name': patient.name}
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text("VIEW FULL PATIENT DETAIL"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)]),
      child: child,
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isStatus ? Colors.orange : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6C73FF))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
