import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/screens/appointments/book_appointment_screen.dart';

class AppointmentsListScreen extends StatelessWidget {
  static const routeName = '/appointments-list';
  const AppointmentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDoctor = user.role == UserRole.doctor;

    // Filter by doctorId or patientId depending on who is logged in
    final String filterField = isDoctor ? 'doctorId' : 'patientId';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: Text(isDoctor ? 'Patient Appointments' : 'My Appointments'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where(filterField, isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading appointments.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // Empty state
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    isDoctor
                        ? 'You have no appointments right now.'
                        : 'You have no appointments yet.',
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDoctor
                        ? 'Patients who book with you will appear here.'
                        : 'Book an appointment with a doctor to get started.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey),
                  ),
                  if (!isDoctor) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, BookAppointmentScreen.routeName),
                      icon: const Icon(Icons.add),
                      label: const Text('Book Appointment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E9EFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]
                ],
              ),
            );
          }

          // Split by status
          final pending = docs
              .where((d) =>
          (d.data() as Map<String, dynamic>)['status'] == 'pending')
              .toList();
          final approved = docs
              .where((d) =>
          (d.data() as Map<String, dynamic>)['status'] == 'approved')
              .toList();
          final completed = docs
              .where((d) =>
          (d.data() as Map<String, dynamic>)['status'] == 'completed')
              .toList();
          final rejected = docs
              .where((d) =>
          (d.data() as Map<String, dynamic>)['status'] == 'rejected')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // PENDING
              if (pending.isNotEmpty) ...[
                _sectionHeader('⏳ Pending', Colors.orange),
                ...pending.map((doc) => _AppointmentCard(
                  doc: doc,
                  isDoctor: isDoctor,
                )),
                const SizedBox(height: 16),
              ],

              // APPROVED
              if (approved.isNotEmpty) ...[
                _sectionHeader('✅ Confirmed', Colors.green),
                ...approved.map((doc) => _AppointmentCard(
                  doc: doc,
                  isDoctor: isDoctor,
                )),
                const SizedBox(height: 16),
              ],

              // COMPLETED
              if (completed.isNotEmpty) ...[
                _sectionHeader('🏁 Completed', Colors.blue),
                ...completed.map((doc) => _AppointmentCard(
                  doc: doc,
                  isDoctor: isDoctor,
                )),
                const SizedBox(height: 16),
              ],

              // REJECTED
              if (rejected.isNotEmpty) ...[
                _sectionHeader('❌ Rejected', Colors.red),
                ...rejected.map((doc) => _AppointmentCard(
                  doc: doc,
                  isDoctor: isDoctor,
                )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: !isDoctor
          ? FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
            context, BookAppointmentScreen.routeName),
        backgroundColor: const Color(0xFF8E9EFF),
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color),
          ),
        ],
      ),
    );
  }
}

// ── Single appointment card ───────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isDoctor;

  const _AppointmentCard({
    required this.doc,
    required this.isDoctor,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.blue;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved': return 'Confirmed';
      case 'rejected': return 'Rejected';
      case 'completed': return 'Completed';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'pending';
    final color = _statusColor(status);

    // Doctor sees patient name, patient sees doctor name
    final displayName = isDoctor
        ? (data['patientName'] as String? ?? 'Patient')
        : (data['doctorName'] as String? ?? 'Doctor');

    final reason = data['reason'] as String? ?? 'No reason provided';
    final dateStr = data['date'] as String? ?? '';
    final timeStr = data['time'] as String? ?? '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isDoctor
            ? () => _showDoctorActionSheet(context, doc.id, status)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        if (dateStr.isNotEmpty)
                          Text(
                            '$dateStr${timeStr.isNotEmpty ? ' at $timeStr' : ''}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📋 $reason',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Doctor action buttons for pending appointments
              if (isDoctor && status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _updateStatus(context, doc.id, 'rejected'),
                        icon: const Icon(Icons.close,
                            size: 16, color: Colors.red),
                        label: const Text('Reject',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _updateStatus(context, doc.id, 'approved'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Doctor can mark approved as completed
              if (isDoctor && status == 'approved') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _updateStatus(context, doc.id, 'completed'),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Mark as Completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Appointment ${newStatus == 'approved' ? 'approved' : newStatus == 'rejected' ? 'rejected' : 'marked as completed'}'),
            backgroundColor: newStatus == 'approved'
                ? Colors.green
                : newStatus == 'rejected'
                ? Colors.red
                : Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDoctorActionSheet(
      BuildContext context, String docId, String status) {
    if (status != 'pending' && status != 'approved') return;
    // Action buttons are already shown inline on the card
  }
}