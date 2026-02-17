import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/appointment_provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/user.dart';

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
  String reason = '';

  final _formKey = GlobalKey<FormState>();

  void _submitAppointment() {
    if (!_formKey.currentState!.validate()) return;
    
    if (selectedDoctorId == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select doctor, date and time')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // Combine date and time
    final appointmentDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    Provider.of<AppointmentProvider>(context, listen: false).bookAppointment(
      patientId: auth.user!.uid,
      doctorId: selectedDoctorId!,
      date: appointmentDateTime,
      reason: reason,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment booked successfully!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final doctors = auth.registeredUsers.where((u) => u.role == UserRole.doctor).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Doctor", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: selectedDoctorId,
                items: doctors.map((doc) => DropdownMenuItem(
                  value: doc.uid,
                  child: Text(doc.name),
                )).toList(),
                onChanged: (val) => setState(() => selectedDoctorId = val),
                decoration: const InputDecoration(hintText: "Choose a doctor"),
                validator: (v) => v == null ? "Required" : null,
              ),
              const SizedBox(height: 16),
              
              const Text("Date & Time", style: TextStyle(fontWeight: FontWeight.bold)),
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
                        if (date != null) setState(() => selectedDate = date);
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(selectedDate == null ? 'Select Date' : selectedDate!.toString().split(' ')[0]),
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
                        if (time != null) setState(() => selectedTime = time);
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(selectedTime == null ? 'Select Time' : selectedTime!.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Text("Add Symptoms", style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Describe your symptoms...'),
                onChanged: (v) => reason = v,
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitAppointment,
                  child: const Text('BOOK APPOINTMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
