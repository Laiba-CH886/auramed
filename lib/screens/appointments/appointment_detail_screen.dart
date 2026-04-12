import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:auramed/screens/consultation/consultation_chat_screen.dart';

class AppointmentDetailScreen extends StatelessWidget {
  static const routeName = '/appointment-detail';
  const AppointmentDetailScreen({super.key});

  // ── Status helpers ────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.blue;
      case 'pending':
      default: return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      case 'completed': return Icons.task_alt;
      case 'pending':
      default: return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Accepts appointmentId string from Navigator arguments
    final appointmentId =
    ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      // ✅ StreamBuilder from Firestore — no AppointmentProvider needed
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          // Not found
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Appointment not found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'pending';
          final reason = data['reason'] as String? ?? 'N/A';
          final patientName = data['patientName'] as String? ?? 'Unknown';
          final doctorName = data['doctorName'] as String? ?? 'Unknown';
          final date = data['date'] as String? ?? '';
          final time = data['time'] as String? ?? '';
          final createdAt = data['createdAt'] as Timestamp?;
          final canChat =
              status == 'approved' || status == 'completed';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status Banner ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                        _statusColor(status).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_statusIcon(status),
                          color: _statusColor(status), size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _statusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Details Card ────────────────────────────────────────
                _detailCard(children: [
                  _detailRow(Icons.person_outline, 'Patient', patientName),
                  const Divider(height: 20),
                  _detailRow(
                      Icons.local_hospital_outlined, 'Doctor', doctorName),
                  const Divider(height: 20),
                  _detailRow(
                      Icons.calendar_today_outlined, 'Date', date),
                  const Divider(height: 20),
                  _detailRow(Icons.access_time_outlined, 'Time', time),
                  if (createdAt != null) ...[
                    const Divider(height: 20),
                    _detailRow(
                      Icons.schedule_outlined,
                      'Booked On',
                      DateFormat('MMM d, yyyy – hh:mm a')
                          .format(createdAt.toDate()),
                    ),
                  ],
                ]),
                const SizedBox(height: 16),

                // ── Reason Card ─────────────────────────────────────────
                _detailCard(children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.notes_outlined,
                            color: Colors.deepPurple, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Reason for Visit',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reason,
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.5),
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Chat Button (only if approved or completed) ─────────
                if (canChat)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // ✅ Passes ConsultationChatArgs, not a plain string
                        Navigator.pushNamed(
                          context,
                          ConsultationChatScreen.routeName,
                          arguments: ConsultationChatArgs(
                            consultationId: appointmentId,
                            patientName: patientName,
                            doctorName: doctorName,
                            isActive: status == 'approved',
                            isDoctor: false,
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: Colors.white),
                      label: Text(
                        status == 'completed'
                            ? 'View Consultation Chat'
                            : 'Enter Consultation Chat',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                // Pending / rejected — explain why chat is hidden
                if (!canChat)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.grey.shade500, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            status == 'rejected'
                                ? 'This appointment was rejected. Chat is unavailable.'
                                : 'Chat will be available once the doctor approves your appointment.',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────────────────────
  Widget _detailCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}