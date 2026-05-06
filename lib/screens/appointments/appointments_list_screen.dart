import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/screens/appointments/book_appointment_screen.dart';
import 'package:auramed/screens/consultation/consultation_chat_screen.dart';
import 'package:auramed/screens/consultation/consultation_service.dart';

class AppointmentsListScreen extends StatefulWidget {
  static const routeName = '/appointments-list';

  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  StreamSubscription<QuerySnapshot>? _alertsSubscription;
  bool _didSetupAlerts = false;
  final Map<String, String> _lastKnownStatuses = {};
  final Set<String> _seenAppointmentIds = {};

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }

  void _setupAppointmentAlerts({
    required bool isDoctor,
    required String userId,
  }) {
    if (_didSetupAlerts) return;
    _didSetupAlerts = true;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final filterField = isDoctor ? 'doctorId' : 'patientId';

    _alertsSubscription = FirebaseFirestore.instance
        .collection('appointments')
        .where(filterField, isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final appointmentId = doc.id;
        final status = data['status'] as String? ?? 'pending';
        final patientName = data['patientName'] as String? ?? 'Patient';
        final doctorName = data['doctorName'] as String? ?? 'Doctor';

        // First snapshot: just register baseline, don't alert
        if (!_seenAppointmentIds.contains(appointmentId)) {
          _seenAppointmentIds.add(appointmentId);
          _lastKnownStatuses[appointmentId] = status;
          continue;
        }

        if (!auth.isAppointmentNotificationEnabled) {
          _lastKnownStatuses[appointmentId] = status;
          continue;
        }

        final previousStatus = _lastKnownStatuses[appointmentId];

        // Doctor side: notify when a new pending appointment appears
        if (isDoctor && previousStatus == null && status == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New appointment request from $patientName'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Patient side: notify when status changes
        if (!isDoctor &&
            previousStatus != null &&
            previousStatus != status) {
          String message;
          switch (status) {
            case 'approved':
              message = 'Your appointment with $doctorName was approved';
              break;
            case 'rejected':
              message = 'Your appointment with $doctorName was rejected';
              break;
            case 'completed':
              message = 'Your appointment with $doctorName was completed';
              break;
            default:
              message = 'Your appointment was updated';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Doctor side: optional alert if status changed elsewhere
        if (isDoctor &&
            previousStatus != null &&
            previousStatus != status &&
            status != 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment status updated to ${_statusLabel(status)}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        _lastKnownStatuses[appointmentId] = status;
      }
    });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Confirmed';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }

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
    final filterField = isDoctor ? 'doctorId' : 'patientId';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupAppointmentAlerts(
        isDoctor: isDoctor,
        userId: user.uid,
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isDoctor ? 'Patient Appointments' : 'My Appointments'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where(filterField, isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

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

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 72,
                    color: Theme.of(context).hintColor.withOpacity(0.45),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isDoctor
                        ? 'You have no appointments right now.'
                        : 'You have no appointments yet.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDoctor
                        ? 'Patients who book with you will appear here.'
                        : 'Book an appointment with a doctor to get started.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  if (!isDoctor) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        BookAppointmentScreen.routeName,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Book Appointment'),
                    ),
                  ]
                ],
              ),
            );
          }

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
              if (pending.isNotEmpty) ...[
                _sectionHeader(context, '⏳ Pending', Colors.orange),
                ...pending.map(
                      (doc) => _AppointmentCard(
                    doc: doc,
                    isDoctor: isDoctor,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (approved.isNotEmpty) ...[
                _sectionHeader(context, '✅ Confirmed', Colors.green),
                ...approved.map(
                      (doc) => _AppointmentCard(
                    doc: doc,
                    isDoctor: isDoctor,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (completed.isNotEmpty) ...[
                _sectionHeader(context, '🏁 Completed', Colors.blue),
                ...completed.map(
                      (doc) => _AppointmentCard(
                    doc: doc,
                    isDoctor: isDoctor,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (rejected.isNotEmpty) ...[
                _sectionHeader(context, '❌ Rejected', Colors.red),
                ...rejected.map(
                      (doc) => _AppointmentCard(
                    doc: doc,
                    isDoctor: isDoctor,
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: !isDoctor
          ? FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
          context,
          BookAppointmentScreen.routeName,
        ),
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _sectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isDoctor;

  const _AppointmentCard({
    required this.doc,
    required this.isDoctor,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Confirmed';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        onTap: isDoctor ? () => _navigateToChat(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (dateStr.isNotEmpty)
                          Text(
                            '$dateStr${timeStr.isNotEmpty ? ' at $timeStr' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📋 $reason',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDoctor && status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatus(context, doc.id, 'rejected'),
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(context, doc.id, 'approved'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (isDoctor && status == 'approved') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(context, doc.id, 'completed'),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Mark as Completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
      BuildContext context,
      String docId,
      String newStatus,
      ) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Appointment ${newStatus == 'approved' ? 'approved' : newStatus == 'rejected' ? 'rejected' : 'marked as completed'}',
            ),
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToChat(BuildContext context) async {
    final data = doc.data() as Map<String, dynamic>;
    final patientId = data['patientId'] as String? ?? '';
    final patientName = data['patientName'] as String? ?? 'Patient';
    final doctorId = data['doctorId'] as String? ?? '';
    final doctorName = data['doctorName'] as String? ?? 'Doctor';
    final status = data['status'] as String? ?? 'pending';

    if (patientId.isEmpty || doctorId.isEmpty) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final consultationId = await ConsultationService.createConsultation(
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
    );

    if (context.mounted) {
      Navigator.pop(context); // Close loading

      if (consultationId != null) {
        Navigator.pushNamed(
          context,
          ConsultationChatScreen.routeName,
          arguments: ConsultationChatArgs(
            consultationId: consultationId,
            patientName: patientName,
            doctorName: doctorName,
            isDoctor: true,
            isActive: status != 'completed',
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start consultation chat')),
        );
      }
    }
  }

  void _showDoctorActionSheet(
      BuildContext context,
      String docId,
      String status,
      ) {
    if (status != 'pending' && status != 'approved') return;
  }
}