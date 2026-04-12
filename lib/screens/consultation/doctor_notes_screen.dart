import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DoctorNotesArgs {
  final String patientName;
  final String consultationId;

  const DoctorNotesArgs({
    required this.patientName,
    required this.consultationId,
  });
}

class DoctorNotesScreen extends StatefulWidget {
  static const routeName = '/doctor-notes';
  const DoctorNotesScreen({super.key});

  @override
  State<DoctorNotesScreen> createState() => _DoctorNotesScreenState();
}

class _DoctorNotesScreenState extends State<DoctorNotesScreen> {
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  DateTime? _followUpDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _followUpDate = picked);
  }

  Future<void> _saveNotes(
      BuildContext context, DoctorNotesArgs args) async {
    if (_diagnosisController.text.trim().isEmpty &&
        _prescriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Please enter at least a diagnosis or prescription.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // ✅ Save notes to Firestore under the consultation doc
      await FirebaseFirestore.instance
          .collection('consultations')
          .doc(args.consultationId)
          .collection('notes')
          .add({
        'diagnosis': _diagnosisController.text.trim(),
        'prescription': _prescriptionController.text.trim(),
        'followUpDate': _followUpDate?.toIso8601String(),
        'patientName': args.patientName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final DoctorNotesArgs notesArgs = args is DoctorNotesArgs
        ? args
        : const DoctorNotesArgs(
      patientName: 'Patient',
      consultationId: 'unknown',
    );

    final today = DateFormat('MMM dd, yyyy').format(DateTime.now());
    final refId = notesArgs.consultationId.length >= 5
        ? notesArgs.consultationId
        .substring(notesArgs.consultationId.length - 5)
        : notesArgs.consultationId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Medical Notes"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient info header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C73FF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Patient: ${notesArgs.patientName}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      Text("Date: $today",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      Text("Ref: #$refId",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("Diagnosis",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _diagnosisController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter patient diagnosis...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Prescription",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _prescriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Enter medications and dosage...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Follow Up Date",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _followUpDate == null
                          ? "Select Date"
                          : DateFormat('MMM dd, yyyy')
                          .format(_followUpDate!),
                      style: TextStyle(
                        color: _followUpDate == null
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
                    const Icon(Icons.calendar_today,
                        size: 18, color: Color(0xFF6C73FF)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _saveNotes(context, notesArgs),
                icon: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? "Saving..." : "SAVE NOTES",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C73FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}