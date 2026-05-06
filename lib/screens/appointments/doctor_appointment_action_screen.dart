import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/screens/patient_detail_screen.dart';

class DoctorAppointmentActionScreen extends StatefulWidget {
  static const routeName = '/doctor-appointment-action';

  const DoctorAppointmentActionScreen({super.key});

  @override
  State<DoctorAppointmentActionScreen> createState() =>
      _DoctorAppointmentActionScreenState();
}

class _DoctorAppointmentActionScreenState
    extends State<DoctorAppointmentActionScreen> {
  final _notesController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateAppointmentStatus(
      BuildContext context,
      String appointmentId,
      String newStatus,
      ) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      final message = newStatus == 'approved'
          ? 'Appointment approved'
          : newStatus == 'rejected'
          ? 'Appointment rejected'
          : 'Appointment updated';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: newStatus == 'approved'
              ? Colors.green
              : newStatus == 'rejected'
              ? Colors.red
              : Colors.blue,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      case 'completed':
        return 'COMPLETED';
      default:
        return 'PENDING';
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final appointmentId = ModalRoute.of(context)!.settings.arguments as String;
    final auth = Provider.of<AuthProvider>(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Error: Appointment not found")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final patientId = data['patientId'] as String? ?? '';
        final patientName = data['patientName'] as String? ?? 'Patient';
        final dateStr = data['date'] as String? ?? '--';
        final timeStr = data['time'] as String? ?? '--';
        final reason = data['reason'] as String? ?? 'No reason provided';
        final status = data['status'] as String? ?? 'pending';

        final patient = auth.registeredUsers.firstWhere(
              (u) => u.uid == patientId,
          orElse: () => UserModel(
            uid: patientId,
            name: patientName,
            email: '',
            role: UserRole.patient,
            isApproved: true,
            isBlocked: false,
          ),
        );

        final readings = auth.readingsFor(patientId);
        final lastReading = readings.isNotEmpty ? readings.last : null;
        final statusColor = _statusColor(status);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Appointment Action'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  context,
                  child: Column(
                    children: [
                      _buildDetailRow(context, "Patient", patient.name),
                      _buildDetailRow(context, "Date", dateStr),
                      _buildDetailRow(context, "Time", timeStr),
                      _buildDetailRow(context, "Reason", reason),
                      _buildDetailRow(
                        context,
                        "Status",
                        _formatStatus(status),
                        valueColor: statusColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Patient Health Summary",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        context,
                        "BP",
                        lastReading?.bp ?? "--",
                      ),
                      _buildSummaryItem(
                        context,
                        "Heart Rate",
                        "${lastReading?.heartRate ?? '--'} bpm",
                      ),
                      _buildSummaryItem(
                        context,
                        "SpO2",
                        "${lastReading?.spo2 ?? '--'}%",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUpdating
                              ? null
                              : () => _updateAppointmentStatus(
                            context,
                            appointmentId,
                            'approved',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: _isUpdating
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text("✅ ACCEPT"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUpdating
                              ? null
                              : () => _updateAppointmentStatus(
                            context,
                            appointmentId,
                            'rejected',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: _isUpdating
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text("❌ REJECT"),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
                Text(
                  "Add Consultation Notes",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Type diagnosis or instructions...",
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Notes saved locally"),
                        ),
                      );
                    },
                    child: const Text("SAVE NOTES"),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        PatientDetailScreen.routeName,
                        arguments: {
                          'id': patient.uid,
                          'name': patient.name,
                        },
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
      },
    );
  }

  Widget _buildInfoCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(
      BuildContext context,
      String label,
      String value, {
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context,
      String label,
      String value,
      ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}