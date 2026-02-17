import 'package:flutter/material.dart';

class AddManualReadingScreen extends StatefulWidget {
  static const routeName = '/add-manual-reading';
  const AddManualReadingScreen({super.key});

  @override
  State<AddManualReadingScreen> createState() =>
      _AddManualReadingScreenState();
}

class _AddManualReadingScreenState extends State<AddManualReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  String type = '';
  String value = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Reading')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Reading Type'),
                onSaved: (v) => type = v!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Value'),
                onSaved: (v) => value = v!,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _formKey.currentState!.save();
                  Navigator.pop(context);
                },
                child: const Text('Save Reading'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
