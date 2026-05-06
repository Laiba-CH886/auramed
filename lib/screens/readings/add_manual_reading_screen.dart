import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/reading.dart';

class AddManualReadingScreen extends StatefulWidget {
  static const routeName = '/add-manual-reading';

  const AddManualReadingScreen({super.key});

  @override
  State<AddManualReadingScreen> createState() => _AddManualReadingScreenState();
}

class _AddManualReadingScreenState extends State<AddManualReadingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();

  @override
  void dispose() {
    _heartRateController.dispose();
    _bpController.dispose();
    _spo2Controller.dispose();
    super.dispose();
  }

  void _saveReading() {
    if (!_formKey.currentState!.validate()) return;

    final int heartRate = int.parse(_heartRateController.text.trim());
    final String bp = _bpController.text.trim();
    final int spo2 = int.parse(_spo2Controller.text.trim());

    final reading = PatientReading(
      timestamp: DateTime.now(),
      heartRate: heartRate,
      bp: bp,
      spo2: spo2,
    );

    Provider.of<AuthProvider>(context, listen: false).addReading(reading);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reading saved successfully'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Reading'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _heartRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Heart Rate (bpm)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter heart rate';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null || number <= 0) {
                    return 'Enter a valid heart rate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bpController,
                decoration: const InputDecoration(
                  labelText: 'Blood Pressure (e.g. 120/80)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter blood pressure';
                  }
                  if (!value.contains('/')) {
                    return 'Use format like 120/80';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _spo2Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'SpO₂ (%)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter SpO₂';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null || number < 0 || number > 100) {
                    return 'Enter a valid SpO₂ value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveReading,
                  child: const Text('Save Reading'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}