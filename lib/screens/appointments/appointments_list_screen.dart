import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/providers/appointment_provider.dart';
import 'package:auramed/screens/appointments/book_appointment_screen.dart';
import 'package:auramed/screens/appointments/doctor_appointment_action_screen.dart';
import 'package:auramed/screens/appointments/appointment_detail_screen.dart';
import 'package:auramed/models/appointment.dart';
import 'package:auramed/models/user.dart';

class AppointmentsListScreen extends StatelessWidget {
  static const routeName = '/appointments-list';
  const AppointmentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final appointmentProv = Provider.of<AppointmentProvider>(context);
    final isDoctor = auth.user?.role == UserRole.doctor;
    
    final appointments = isDoctor
        ? appointmentProv.getAppointmentsForDoctor(auth.user!.uid)
        : appointmentProv.getAppointmentsForPatient(auth.user!.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text('My Appointments'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: appointments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No appointments found'),
                  if (!isDoctor)
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, BookAppointmentScreen.routeName),
                      child: const Text('Book Now'),
                    )
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (isDoctor) ...[
                  _buildSectionHeader("Pending Requests"),
                  ...appointments.where((a) => a.status == AppointmentStatus.pending).map((a) => _buildAppointmentCard(context, a, auth)),
                  const SizedBox(height: 24),
                  _buildSectionHeader("Confirmed"),
                  ...appointments.where((a) => a.status == AppointmentStatus.approved).map((a) => _buildAppointmentCard(context, a, auth)),
                ] else
                  ...appointments.map((a) => _buildAppointmentCard(context, a, auth)),
              ],
            ),
      floatingActionButton: !isDoctor
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, BookAppointmentScreen.routeName),
              backgroundColor: const Color(0xFF8E9EFF),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1, fontSize: 13)),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appt, AuthProvider auth) {
    final isDoctor = auth.user?.role == UserRole.doctor;
    // For doctor, we want to show patient name. For patient, we want doctor name.
    final displayName = isDoctor 
        ? (auth.registeredUsers.firstWhere((u) => u.uid == appt.patientId, orElse: () => UserModel(uid: '', name: 'Patient', email: '', role: UserRole.patient)).name)
        : (auth.registeredUsers.firstWhere((u) => u.uid == appt.doctorId, orElse: () => UserModel(uid: '', name: 'Doctor', email: '', role: UserRole.doctor)).name);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(appt.status).withAlpha(30),
          child: Icon(Icons.calendar_today, color: _getStatusColor(appt.status), size: 20),
        ),
        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${appt.date.toString().substring(0, 10)} | ${appt.reason}', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () {
          if (isDoctor) {
            Navigator.pushNamed(context, DoctorAppointmentActionScreen.routeName, arguments: appt.id);
          } else {
            Navigator.pushNamed(context, AppointmentDetailScreen.routeName, arguments: appt.id);
          }
        },
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending: return Colors.orange;
      case AppointmentStatus.approved: return Colors.green;
      case AppointmentStatus.rejected: return Colors.red;
      case AppointmentStatus.completed: return Colors.blue;
    }
  }
}
