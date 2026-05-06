import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/screens/consultation/consultation_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});
  static const routeName = '/book-appointment';

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedDoctorId;
  String? selectedDoctorName;
  String reason = '';
  bool _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor')),
      );
      return;
    }
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final patient = auth.user!;

    final dateStr =
        '${selectedDate!.year}-${_pad(selectedDate!.month)}-${_pad(selectedDate!.day)}';
    final timeStr = selectedTime!.format(context);

    try {
      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': patient.uid,
        'patientName': patient.name,
        'doctorId': selectedDoctorId,
        'doctorName': selectedDoctorName ?? 'Doctor',
        'date': dateStr,
        'time': timeStr,
        'reason': reason.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await ConsultationService.createConsultation(
        patientId: patient.uid,
        patientName: patient.name,
        doctorId: selectedDoctorId!,
        doctorName: selectedDoctorName ?? 'Doctor',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Doctor",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'doctor')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Loading doctors...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange.withOpacity(0.10)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.orange.withOpacity(0.30)
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.person_search,
                            size: 40,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No doctors available right now.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please check back when a doctor has registered.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final doctors = docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return {
                      'uid': d.id,
                      'name': data['name'] as String? ?? 'Doctor',
                      'specialization':
                      data['specialization'] as String? ?? 'General Physician',
                    };
                  }).toList();

                  return DropdownButtonFormField<String>(
                    value: selectedDoctorId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: "Choose a doctor",
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: doctors.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc['uid'] as String,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: colorScheme.primary.withOpacity(0.12),
                              child: Text(
                                (doc['name'] as String).isNotEmpty
                                    ? (doc['name'] as String)[0].toUpperCase()
                                    : 'D',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    doc['name'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    doc['specialization'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedDoctorId = val;
                        selectedDoctorName = doctors.firstWhere(
                              (d) => d['uid'] == val,
                        )['name'] as String;
                      });
                    },
                    validator: (v) => v == null ? "Please select a doctor" : null,
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                "Date & Time",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                          initialDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: selectedDate == null
                              ? Theme.of(context).dividerColor
                              : colorScheme.primary,
                        ),
                      ),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        selectedDate == null
                            ? 'Select Date'
                            : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                        style: TextStyle(
                          fontSize: 13,
                          color: selectedDate == null
                              ? Theme.of(context).hintColor
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: selectedTime == null
                              ? Theme.of(context).dividerColor
                              : colorScheme.primary,
                        ),
                      ),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(
                        selectedTime == null
                            ? 'Select Time'
                            : selectedTime!.format(context),
                        style: TextStyle(
                          fontSize: 13,
                          color: selectedTime == null
                              ? Theme.of(context).hintColor
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Describe Symptoms",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe your symptoms...',
                ),
                onChanged: (v) => reason = v,
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Please describe your symptoms"
                    : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAppointment,
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'BOOK APPOINTMENT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}